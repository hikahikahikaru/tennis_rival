import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/repositories/auth_repository.dart';
import 'package:mobile/services/auth_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  group('AuthService', () {
    test('normalizes input and returns email confirmation state', () async {
      final repository = _FakeAuthRepository();
      final service = AuthService(repository: repository);

      final result = await service.signUp(
        displayName: '  たけし\t',
        email: '  takeshi@example.com  ',
        password: 'password8',
        confirmPassword: 'password8',
      );

      expect(
          result.status, AccountRegistrationStatus.emailConfirmationRequired);
      expect(result.isSuccess, isTrue);
      expect(
        result.message,
        '登録手続きを受け付けました。確認メールが届いた場合は、メール内のリンクから登録を完了してください。',
      );
      expect(repository.callCount, 1);
      expect(repository.displayName, 'たけし');
      expect(repository.email, 'takeshi@example.com');
      expect(repository.password, 'password8');
    });

    test('returns authenticated state when a session is issued', () async {
      final repository = _FakeAuthRepository(
        response: const AuthSignUpResponse(
          userId: 'user-1',
          hasSession: true,
        ),
      );

      final result = await AuthService(repository: repository).signUp(
        displayName: 'たけし',
        email: 'takeshi@example.com',
        password: 'password8',
        confirmPassword: 'password8',
      );

      expect(result.status, AccountRegistrationStatus.authenticated);
      expect(result.isSuccess, isTrue);
    });

    test('accepts a password with exactly eight characters', () async {
      final repository = _FakeAuthRepository();

      final result = await AuthService(repository: repository).signUp(
        displayName: 'たけし',
        email: 'takeshi@example.com',
        password: '12345678',
        confirmPassword: '12345678',
      );

      expect(result.isSuccess, isTrue);
      expect(repository.callCount, 1);
    });

    final invalidCases = <String, _InvalidInputCase>{
      'rejects an empty display name': const _InvalidInputCase(
        displayName: ' \t\n ',
        expectedField: AccountRegistrationField.displayName,
      ),
      'rejects an empty email': const _InvalidInputCase(
        email: '   ',
        expectedField: AccountRegistrationField.email,
      ),
      'rejects an invalid email format': const _InvalidInputCase(
        email: 'invalid-email',
        expectedField: AccountRegistrationField.email,
      ),
      'rejects a password with seven characters': const _InvalidInputCase(
        password: '1234567',
        confirmPassword: '1234567',
        expectedField: AccountRegistrationField.password,
      ),
      'rejects a mismatched confirmation password': const _InvalidInputCase(
        confirmPassword: 'different8',
        expectedField: AccountRegistrationField.confirmPassword,
      ),
    };

    for (final entry in invalidCases.entries) {
      test('${entry.key} without calling the repository', () async {
        final repository = _FakeAuthRepository();
        final input = entry.value;

        final result = await AuthService(repository: repository).signUp(
          displayName: input.displayName,
          email: input.email,
          password: input.password,
          confirmPassword: input.confirmPassword,
        );

        expect(result.status, AccountRegistrationStatus.validationError);
        expect(result.fieldErrors, contains(input.expectedField));
        expect(repository.callCount, 0);
      });
    }

    test('maps AuthException to a safe registration error', () async {
      const secret = 'registered-email-internal-detail';
      final repository = _FakeAuthRepository(
        error: const AuthException(secret, code: 'user_already_exists'),
      );

      final result = await AuthService(repository: repository).signUp(
        displayName: 'たけし',
        email: 'takeshi@example.com',
        password: 'password8',
        confirmPassword: 'password8',
      );

      expect(result.status, AccountRegistrationStatus.authError);
      expect(result.message, isNot(contains(secret)));
    });

    test('maps a retryable communication failure to a network error', () async {
      final repository = _FakeAuthRepository(
        error: AuthRetryableFetchException(message: 'socket detail'),
      );

      final result = await AuthService(repository: repository).signUp(
        displayName: 'たけし',
        email: 'takeshi@example.com',
        password: 'password8',
        confirmPassword: 'password8',
      );

      expect(result.status, AccountRegistrationStatus.networkError);
      expect(result.message, isNot(contains('socket detail')));
    });

    test('maps a retryable server failure to a network error', () async {
      final repository = _FakeAuthRepository(
        error: AuthRetryableFetchException(
          message: 'service unavailable detail',
          statusCode: '503',
        ),
      );

      final result = await AuthService(repository: repository).signUp(
        displayName: 'たけし',
        email: 'takeshi@example.com',
        password: 'password8',
        confirmPassword: 'password8',
      );

      expect(result.status, AccountRegistrationStatus.networkError);
      expect(result.message, isNot(contains('service unavailable detail')));
    });

    test('does not expose details from an unknown error', () async {
      const secret = 'secret-token-and-password';
      final repository = _FakeAuthRepository(error: Exception(secret));

      final result = await AuthService(repository: repository).signUp(
        displayName: 'たけし',
        email: 'takeshi@example.com',
        password: 'password8',
        confirmPassword: 'password8',
      );

      expect(result.status, AccountRegistrationStatus.unknownError);
      expect(result.message, isNot(contains(secret)));
    });

    test('signs in with a normalized email and returns the user ID', () async {
      final repository = _FakeAuthRepository(
        signInResponse: const AuthSignInResponse(
          userId: 'user-2',
          hasSession: true,
        ),
      );

      final result = await AuthService(repository: repository).signIn(
        email: '  login@example.com  ',
        password: 'password8',
      );

      expect(result.status, AuthenticationStatus.authenticated);
      expect(result.userId, 'user-2');
      expect(repository.signInEmail, 'login@example.com');
      expect(repository.signInCallCount, 1);
    });

    test('does not call sign in for invalid input', () async {
      final repository = _FakeAuthRepository();

      final result = await AuthService(repository: repository).signIn(
        email: 'invalid-email',
        password: '',
      );

      expect(result.status, AuthenticationStatus.validationError);
      expect(repository.signInCallCount, 0);
    });

    test('does not authenticate when the repository reports no session',
        () async {
      final repository = _FakeAuthRepository(
        signInResponse: const AuthSignInResponse(
          userId: 'user-2',
          hasSession: false,
        ),
      );

      final result = await AuthService(repository: repository).signIn(
        email: 'login@example.com',
        password: 'password8',
      );

      expect(result.status, AuthenticationStatus.unknownError);
      expect(result.isSuccess, isFalse);
    });

    test('classifies credential, confirmation, and unexpected auth errors',
        () async {
      final invalidRepository = _FakeAuthRepository(
        signInError:
            const AuthException('invalid', code: 'invalid_credentials'),
      );
      final unconfirmedRepository = _FakeAuthRepository(
        signInError:
            const AuthException('unconfirmed', code: 'email_not_confirmed'),
      );
      final unexpectedRepository = _FakeAuthRepository(
        signInError: const AuthException(
          'invalid response detail',
          code: 'invalid_auth_response',
        ),
      );

      final invalid = await AuthService(repository: invalidRepository).signIn(
        email: 'login@example.com',
        password: 'password8',
      );
      final unconfirmed =
          await AuthService(repository: unconfirmedRepository).signIn(
        email: 'login@example.com',
        password: 'password8',
      );
      final unexpected =
          await AuthService(repository: unexpectedRepository).signIn(
        email: 'login@example.com',
        password: 'password8',
      );

      expect(invalid.status, AuthenticationStatus.invalidCredentials);
      expect(unconfirmed.status, AuthenticationStatus.emailNotConfirmed);
      expect(unconfirmed.isSuccess, isFalse);
      expect(unexpected.status, AuthenticationStatus.unknownError);
      expect(unexpected.message, isNot(contains('invalid response detail')));
    });

    test('classifies retryable and unknown sign in failures safely', () async {
      final networkRepository = _FakeAuthRepository(
        signInError: AuthRetryableFetchException(message: 'socket secret'),
      );
      final unknownRepository = _FakeAuthRepository(
        signInError: Exception('token secret'),
      );

      final network = await AuthService(repository: networkRepository).signIn(
        email: 'login@example.com',
        password: 'password8',
      );
      final unknown = await AuthService(repository: unknownRepository).signIn(
        email: 'login@example.com',
        password: 'password8',
      );

      expect(network.status, AuthenticationStatus.networkError);
      expect(network.message, isNot(contains('socket secret')));
      expect(unknown.status, AuthenticationStatus.unknownError);
      expect(unknown.message, isNot(contains('token secret')));
    });

    test('signs out and classifies logout failures', () async {
      final successRepository = _FakeAuthRepository();
      final networkRepository = _FakeAuthRepository(
        signOutError: AuthRetryableFetchException(message: 'offline'),
      );
      final authRepository = _FakeAuthRepository(
        signOutError: const AuthException('denied'),
      );

      final success =
          await AuthService(repository: successRepository).signOut();
      final network =
          await AuthService(repository: networkRepository).signOut();
      final auth = await AuthService(repository: authRepository).signOut();

      expect(success.status, LogoutStatus.signedOut);
      expect(successRepository.signOutCallCount, 1);
      expect(network.status, LogoutStatus.networkError);
      expect(auth.status, LogoutStatus.authError);
    });
  });
}

class _InvalidInputCase {
  final String displayName;
  final String email;
  final String password;
  final String confirmPassword;
  final AccountRegistrationField expectedField;

  const _InvalidInputCase({
    this.displayName = 'たけし',
    this.email = 'takeshi@example.com',
    this.password = 'password8',
    this.confirmPassword = 'password8',
    required this.expectedField,
  });
}

class _FakeAuthRepository implements AuthRepository {
  _FakeAuthRepository({
    this.response = const AuthSignUpResponse(
      userId: 'user-1',
      hasSession: false,
    ),
    this.error,
    this.signInResponse = const AuthSignInResponse(
      userId: 'user-1',
      hasSession: true,
    ),
    this.signInError,
    this.signOutError,
  });

  final AuthSignUpResponse response;
  final Object? error;
  final AuthSignInResponse signInResponse;
  final Object? signInError;
  final Object? signOutError;
  @override
  bool get hasActiveSession => false;
  int callCount = 0;
  int signInCallCount = 0;
  int signOutCallCount = 0;
  String? displayName;
  String? email;
  String? password;
  String? signInEmail;

  @override
  Future<AuthSignUpResponse> signUp({
    required String displayName,
    required String email,
    required String password,
  }) async {
    callCount++;
    this.displayName = displayName;
    this.email = email;
    this.password = password;
    final failure = error;
    if (failure != null) throw failure;
    return response;
  }

  @override
  Future<AuthSignInResponse> signIn({
    required String email,
    required String password,
  }) async {
    signInCallCount++;
    signInEmail = email;
    final failure = signInError;
    if (failure != null) throw failure;
    return signInResponse;
  }

  @override
  Future<void> signOut() async {
    signOutCallCount++;
    final failure = signOutError;
    if (failure != null) throw failure;
  }
}
