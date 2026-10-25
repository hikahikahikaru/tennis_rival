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
