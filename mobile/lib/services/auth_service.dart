import 'package:supabase_flutter/supabase_flutter.dart';

import '../constants/app_strings.dart';
import '../repositories/auth_repository.dart';

enum AccountRegistrationStatus {
  emailConfirmationRequired,
  authenticated,
  validationError,
  authError,
  networkError,
  unknownError,
}

enum AccountRegistrationField {
  displayName,
  email,
  password,
  confirmPassword,
}

enum AuthenticationStatus {
  authenticated,
  validationError,
  invalidCredentials,
  emailNotConfirmed,
  networkError,
  unknownError,
}

/// ログイン画面がSupabase固有型へ依存せず結果を扱うための値。
class AuthenticationResult {
  final AuthenticationStatus status;
  final String message;
  final String? userId;

  const AuthenticationResult({
    required this.status,
    required this.message,
    this.userId,
  });

  bool get isSuccess => status == AuthenticationStatus.authenticated;
}

enum LogoutStatus { signedOut, authError, networkError, unknownError }

/// ログアウト結果を画面遷移とエラー表示へ安全に渡すための値。
class LogoutResult {
  final LogoutStatus status;
  final String message;

  const LogoutResult({required this.status, required this.message});

  bool get isSuccess => status == LogoutStatus.signedOut;
}

/// 登録画面がSupabase固有型へ依存せず状態を表示するための結果。
class AccountRegistrationResult {
  final AccountRegistrationStatus status;
  final String message;
  final Map<AccountRegistrationField, String> fieldErrors;

  const AccountRegistrationResult({
    required this.status,
    required this.message,
    this.fieldErrors = const {},
  });

  bool get isSuccess =>
      status == AccountRegistrationStatus.emailConfirmationRequired ||
      status == AccountRegistrationStatus.authenticated;
}

/// アカウント登録の入力検証と結果分類を担当するService。
class AuthService {
  static const int minimumPasswordLength = 8;

  final AuthRepository _repository;

  AuthService({AuthRepository? repository})
      : _repository = repository ?? SupabaseAuthRepository();

  /// ログアウト通信の成否とは別に、端末上の認証状態を確認する。
  bool get hasActiveSession => _repository.hasActiveSession;

  Future<AccountRegistrationResult> signUp({
    required String displayName,
    required String email,
    required String password,
    required String confirmPassword,
  }) async {
    final normalizedDisplayName = displayName.trim();
    final normalizedEmail = email.trim();
    final fieldErrors = _validate(
      displayName: normalizedDisplayName,
      email: normalizedEmail,
      password: password,
      confirmPassword: confirmPassword,
    );
    if (fieldErrors.isNotEmpty) {
      return AccountRegistrationResult(
        status: AccountRegistrationStatus.validationError,
        message: AppStrings.accountRegistrationInputInvalid,
        fieldErrors: fieldErrors,
      );
    }

    try {
      final response = await _repository.signUp(
        displayName: normalizedDisplayName,
        email: normalizedEmail,
        password: password,
      );
      if (response.hasSession) {
        return const AccountRegistrationResult(
          status: AccountRegistrationStatus.authenticated,
          message: AppStrings.accountRegistrationCompleted,
        );
      }
      // userが返ってもsessionがなければ、確認完了前のログイン状態とは扱わない。
      return const AccountRegistrationResult(
        status: AccountRegistrationStatus.emailConfirmationRequired,
        message: AppStrings.accountRegistrationConfirmationPending,
      );
    } on AuthRetryableFetchException {
      // gotrue 2.25.0では通信失敗とHTTP 5xxの双方がこの例外に統一される。
      return const AccountRegistrationResult(
        status: AccountRegistrationStatus.networkError,
        message: AppStrings.accountRegistrationNetworkError,
      );
    } on AuthException {
      // 登録済みメールの有無やAuth内部情報を画面へ露出しない。
      return const AccountRegistrationResult(
        status: AccountRegistrationStatus.authError,
        message: AppStrings.accountRegistrationFailed,
      );
    } catch (_) {
      return const AccountRegistrationResult(
        status: AccountRegistrationStatus.unknownError,
        message: AppStrings.accountRegistrationUnexpectedError,
      );
    }
  }

  Future<AuthenticationResult> signIn({
    required String email,
    required String password,
  }) async {
    final normalizedEmail = email.trim();
    if (normalizedEmail.isEmpty ||
        !_emailPattern.hasMatch(normalizedEmail) ||
        password.isEmpty) {
      return const AuthenticationResult(
        status: AuthenticationStatus.validationError,
        message: AppStrings.authenticationInputInvalid,
      );
    }

    try {
      final response = await _repository.signIn(
        email: normalizedEmail,
        password: password,
      );
      if (!response.hasSession) {
        return const AuthenticationResult(
          status: AuthenticationStatus.unknownError,
          message: AppStrings.authenticationUnexpectedError,
        );
      }
      return AuthenticationResult(
        status: AuthenticationStatus.authenticated,
        message: AppStrings.loginCompleted,
        userId: response.userId,
      );
    } on AuthRetryableFetchException {
      return const AuthenticationResult(
        status: AuthenticationStatus.networkError,
        message: AppStrings.authenticationNetworkError,
      );
    } on AuthException catch (error) {
      switch (error.code) {
        case 'invalid_credentials':
          return const AuthenticationResult(
            status: AuthenticationStatus.invalidCredentials,
            message: AppStrings.authenticationFailed,
          );
        case 'email_not_confirmed':
          return const AuthenticationResult(
            status: AuthenticationStatus.emailNotConfirmed,
            message: AppStrings.authenticationEmailNotConfirmed,
          );
        default:
          // Auth内部の詳細は公開せず、想定外の応答として再試行可能な状態にする。
          return const AuthenticationResult(
            status: AuthenticationStatus.unknownError,
            message: AppStrings.authenticationUnexpectedError,
          );
      }
    } catch (_) {
      return const AuthenticationResult(
        status: AuthenticationStatus.unknownError,
        message: AppStrings.authenticationUnexpectedError,
      );
    }
  }

  Future<LogoutResult> signOut() async {
    try {
      await _repository.signOut();
      return const LogoutResult(
        status: LogoutStatus.signedOut,
        message: '',
      );
    } on AuthRetryableFetchException {
      return const LogoutResult(
        status: LogoutStatus.networkError,
        message: AppStrings.logoutNetworkError,
      );
    } on AuthException {
      return const LogoutResult(
        status: LogoutStatus.authError,
        message: AppStrings.logoutFailed,
      );
    } catch (_) {
      return const LogoutResult(
        status: LogoutStatus.unknownError,
        message: AppStrings.logoutUnexpectedError,
      );
    }
  }

  Map<AccountRegistrationField, String> _validate({
    required String displayName,
    required String email,
    required String password,
    required String confirmPassword,
  }) {
    final errors = <AccountRegistrationField, String>{};
    if (displayName.isEmpty) {
      errors[AccountRegistrationField.displayName] =
          AppStrings.accountDisplayNameRequired;
    }
    if (email.isEmpty) {
      errors[AccountRegistrationField.email] = AppStrings.accountEmailRequired;
    } else if (!_emailPattern.hasMatch(email)) {
      errors[AccountRegistrationField.email] = AppStrings.accountEmailInvalid;
    }
    if (password.length < minimumPasswordLength) {
      errors[AccountRegistrationField.password] =
          AppStrings.accountPasswordTooShort;
    }
    if (password != confirmPassword) {
      errors[AccountRegistrationField.confirmPassword] =
          AppStrings.accountPasswordMismatch;
    }
    return errors;
  }

  static final RegExp _emailPattern = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');
}
