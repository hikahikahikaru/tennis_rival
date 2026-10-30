import 'package:supabase_flutter/supabase_flutter.dart';

/// Supabase Authへの通信を担当するRepository。
abstract class AuthRepository {
  Future<AuthSignUpResponse> signUp({
    required String displayName,
    required String email,
    required String password,
  });
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

class SupabaseAuthRepository implements AuthRepository {
  final SupabaseClient? _client;

  SupabaseAuthRepository({SupabaseClient? client}) : _client = client;

  SupabaseClient get client => _client ?? Supabase.instance.client;

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
}
