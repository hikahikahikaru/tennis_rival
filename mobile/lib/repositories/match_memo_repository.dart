import 'package:supabase_flutter/supabase_flutter.dart';

abstract class MatchMemoRepository {
  Future<void> upsertPersonalMemo({
    required String matchId,
    required String userId,
    required String memo,
  });

  Future<void> deletePersonalMemo({
    required String matchId,
    required String userId,
  });
}

/// 個人メモの書き込みだけをSupabaseへ委譲するRepository。
class SupabaseMatchMemoRepository implements MatchMemoRepository {
  static const String table = 'match_memos';

  final SupabaseClient? _client;

  SupabaseMatchMemoRepository({SupabaseClient? client}) : _client = client;

  SupabaseClient get client => _client ?? Supabase.instance.client;

  @override
  Future<void> upsertPersonalMemo({
    required String matchId,
    required String userId,
    required String memo,
  }) async {
    // 複合主キー単位でupsertし、同じ試合にある他ユーザーのメモへ触れない。
    await client.from(table).upsert(
      {
        'match_id': matchId,
        'user_id': userId,
        'memo': memo,
      },
      onConflict: 'match_id,user_id',
    );
  }

  @override
  Future<void> deletePersonalMemo({
    required String matchId,
    required String userId,
  }) async {
    await client
        .from(table)
        .delete()
        .eq('match_id', matchId)
        .eq('user_id', userId);
  }
}
