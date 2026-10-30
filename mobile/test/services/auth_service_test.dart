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
  });

  final AuthSignUpResponse response;
  final Object? error;
  int callCount = 0;
  String? displayName;
  String? email;
  String? password;

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
}
