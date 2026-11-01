import 'package:supabase_flutter/supabase_flutter.dart';

/// Supabase Authへの通信を担当するRepository。
abstract class AuthRepository {
  bool get hasActiveSession;

  Future<AuthSignUpResponse> signUp({
    required String displayName,
    required String email,
    required String password,
  });

  Future<AuthSignInResponse> signIn({
    required String email,
    required String password,
  });

  Future<void> signOut();
}

/// 登録後のユーザーとセッション発行有無だけを上位層へ公開する。
class AuthSignUpResponse {
  final String userId;
  final bool hasSession;

  const AuthSignUpResponse({
    required this.userId,
    required this.hasSession,
  });
}

/// ログイン後にUIから必要となる識別子とセッション状態だけを上位層へ公開する。
class AuthSignInResponse {
  final String userId;
  final bool hasSession;

  const AuthSignInResponse({
    required this.userId,
    required this.hasSession,
  });
}

class SupabaseAuthRepository implements AuthRepository {
  final SupabaseClient? _client;

  SupabaseAuthRepository({SupabaseClient? client}) : _client = client;

  SupabaseClient get client => _client ?? Supabase.instance.client;

  @override
  bool get hasActiveSession => client.auth.currentSession != null;

  @override
  Future<AuthSignUpResponse> signUp({
    required String displayName,
    required String email,
    required String password,
  }) async {
    final response = await client.auth.signUp(
      email: email,
      password: password,
      data: {'user_name': displayName},
    );
    final user = response.user;
    if (user == null) {
      throw const AuthException('Sign up completed without a user.');
    }

    return AuthSignUpResponse(
      userId: user.id,
      hasSession: response.session != null,
    );
  }

  @override
  Future<AuthSignInResponse> signIn({
    required String email,
    required String password,
  }) async {
    late final AuthResponse response;
    try {
      response = await client.auth.signInWithPassword(
        email: email,
        password: password,
      );
    } on AuthException {
      rethrow;
    } catch (_) {
      // SDKが解釈できない応答でも、途中で保存されたセッションを残さない。
      if (hasActiveSession) {
        await _discardRejectedSession();
      }
      throw const AuthException(
        'Sign in returned an invalid response.',
        code: 'invalid_auth_response',
      );
    }
    final user = response.user;
    final session = response.session;
    // セッションだけが保存された異常応答では、認証失敗後に状態を残さない。
    if (user == null || session == null) {
      if (session != null || hasActiveSession) {
        await _discardRejectedSession();
      }
      throw const AuthException(
        'Sign in completed without a user or session.',
        code: 'invalid_auth_response',
      );
    }
    if (user.emailConfirmedAt == null) {
      // API設定差異で発行された未確認セッションを端末に残さず、ログインを拒否する。
      await _discardRejectedSession();
      throw const AuthException(
        'Email is not confirmed.',
        code: 'email_not_confirmed',
      );
    }

    return AuthSignInResponse(userId: user.id, hasSession: true);
  }

  @override
  Future<void> signOut() {
    // gotrue 2.25.0の既定値を明示し、この端末のセッションだけを破棄する。
    return client.auth.signOut(scope: SignOutScope.local);
  }

  Future<void> _discardRejectedSession() async {
    try {
      await client.auth.signOut(scope: SignOutScope.local);
    } catch (_) {
      // SDKは通信前にローカルセッションを消すため、通信失敗時も実状態を確認する。
    }
    if (client.auth.currentSession != null) {
      // 破棄を確認できない場合はメール未確認より重い異常とし、必ず成功経路を止める。
      throw const AuthException(
        'Failed to clear a rejected authentication session.',
        code: 'session_cleanup_failed',
      );
    }
  }
}
