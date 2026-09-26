import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/match_history_item.dart';
import '../models/match_type.dart';

abstract class MatchHistoryRepository {
  /// ホーム表示用に、直近の試合だけを取得する。
  ///
  /// 戦績画面で全履歴やページングが必要になった場合は別APIとして追加する。
  Future<List<MatchHistoryItem>> fetchRecentMatches(String currentUserId);
}

class MatchHistoryQuery {
  final String currentUserId;

  const MatchHistoryQuery._({required this.currentUserId});

  static const String table = 'match_participants';
  static const String participantColumn = 'participant_id';
  static const String matchTypeColumn = 'matches.match_type';
  static const String matchDateOrderColumn = 'matches(dt_match)';
  static const int recentMatchLimit = 2;

  static const String select = 'match_id,participant_id,'
      'match_memos!match_memos_match_participant_fkey(user_id,memo),'
      'matches!inner('
      'match_id,'
      'dt_match,'
      'match_type,'
      'total_set_amount,'
      'winner,'
      'score1_user_id,'
      'set_scores(set_no,score1,score2,t_score1,t_score2),'
      'match_participants('
      'participant_id,'
      'users!match_participants_participant_id_fkey(user_id,user_name)'
      ')'
      ')';

  static MatchHistoryQuery forUser(String currentUserId) {
    return MatchHistoryQuery._(currentUserId: currentUserId);
  }
}

/// Supabaseへ試合履歴を問い合わせ、取得行をModelへ渡すRepository。
///
/// HomeScreenは通信の詳細を持たず、このRepositoryまたはFake実装を受け取る。
class SupabaseMatchHistoryRepository implements MatchHistoryRepository {
  final SupabaseClient? _client;

  SupabaseMatchHistoryRepository({SupabaseClient? client}) : _client = client;

  SupabaseClient get client => _client ?? Supabase.instance.client;

  @override
  Future<List<MatchHistoryItem>> fetchRecentMatches(
    String currentUserId,
  ) async {
    final query = MatchHistoryQuery.forUser(currentUserId);
    final rows = await fetchRows(query);
    return rows
        .map(
          (row) => MatchHistoryItem.fromRow(
            row,
            currentUserId: currentUserId,
          ),
        )
        .whereType<MatchHistoryItem>()
        .toList();
  }

  Future<List<dynamic>> fetchRows(MatchHistoryQuery query) async {
    // 閲覧者の参加行で絞り、その行に属する本人メモと、対戦相手用の全参加者を同時取得する。
    // user_idによる絞り込みは認証導入前の表示制御であり、セキュリティ保証ではない。
    final response = await client
        .from(MatchHistoryQuery.table)
        .select(MatchHistoryQuery.select)
        .eq(MatchHistoryQuery.participantColumn, query.currentUserId)
        .eq(
          MatchHistoryQuery.matchTypeColumn,
          MatchType.singles.dbValue,
        )
        .order(
          MatchHistoryQuery.matchDateOrderColumn,
          ascending: false,
        )
        .limit(MatchHistoryQuery.recentMatchLimit);

    return response as List<dynamic>;
  }
}
