import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/match_history_item.dart';
import '../models/match_type.dart';

abstract class MatchHistoryRepository {
  Future<List<MatchHistoryItem>> fetchRecentMatches(String currentUserId);
}

class MatchHistoryQuery {
  final String currentUserId;

  const MatchHistoryQuery._({required this.currentUserId});

  static const String table = 'match_participants';
  static const String participantColumn = 'participant_id';
  static const String matchTypeColumn = 'matches.match_type';
  static const String matchDateOrderColumn = 'dt_match';
  static const String matchesReferencedTable = 'matches';

  static const String select = 'match_id,participant_id,'
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
    final items = rows
        .map(
          (row) => MatchHistoryItem.fromRow(
            row,
            currentUserId: currentUserId,
          ),
        )
        .whereType<MatchHistoryItem>()
        .toList()
      ..sort((a, b) => b.matchDate.compareTo(a.matchDate));
    return items;
  }

  Future<List<dynamic>> fetchRows(MatchHistoryQuery query) async {
    // 閲覧者の参加行で絞り、同じ試合に属する全参加者も埋め込んで対戦相手を得る。
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
          referencedTable: MatchHistoryQuery.matchesReferencedTable,
          ascending: false,
        );

    return response as List<dynamic>;
  }
}
