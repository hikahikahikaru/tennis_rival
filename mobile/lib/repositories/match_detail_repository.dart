import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/match_detail.dart';

class MatchDetailNotFoundException implements Exception {
  final String matchId;

  const MatchDetailNotFoundException(this.matchId);

  @override
  String toString() => 'MatchDetailNotFoundException: $matchId';
}

abstract class MatchDetailRepository {
  Future<MatchDetail> fetchMatchDetail({
    required String matchId,
    required String currentUserId,
  });
}

/// Supabaseから試合と全参加者・全セットを一度に取得するRepository。
class SupabaseMatchDetailRepository implements MatchDetailRepository {
  static const String _table = 'matches';
  static const String _select = 'match_id,'
      'dt_match,'
      'match_type,'
      'total_set_amount,'
      'winner,'
      'score1_user_id,'
      'set_scores(set_no,score1,score2,t_score1,t_score2,set_winner),'
      'match_participants('
      'participant_id,'
      'users!match_participants_participant_id_fkey(user_id,user_name)'
      ')';

  final SupabaseClient? _client;

  SupabaseMatchDetailRepository({SupabaseClient? client}) : _client = client;

  SupabaseClient get client => _client ?? Supabase.instance.client;

  @override
  Future<MatchDetail> fetchMatchDetail({
    required String matchId,
    required String currentUserId,
  }) async {
    final rows = await fetchRows(matchId);
    if (rows.isEmpty) {
      throw MatchDetailNotFoundException(matchId);
    }
    // currentUserIdの参加確認は表示データの整合性検証であり、認証・RLSの代替ではない。
    return MatchDetail.fromRow(
      rows.first,
      currentUserId: currentUserId,
    );
  }

  Future<List<dynamic>> fetchRows(String matchId) async {
    final response = await client
        .from(_table)
        .select(_select)
        .eq('match_id', matchId)
        .limit(1);
    return response as List<dynamic>;
  }
}
