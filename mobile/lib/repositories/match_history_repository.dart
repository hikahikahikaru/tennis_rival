import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/match_history_item.dart';
import '../models/match_history_query.dart';

abstract class MatchHistoryRepository {
  /// ホーム表示用に、直近2件のシングルス試合を取得する。
  Future<List<MatchHistoryItem>> fetchRecentMatches(String currentUserId);

  /// ユーザー・期間・種別・件数など、指定条件に合う試合を取得する。
  Future<List<MatchHistoryItem>> fetchMatches(MatchHistoryQuery query);
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
    return fetchMatches(MatchHistoryQuery.recent(currentUserId));
  }

  @override
  Future<List<MatchHistoryItem>> fetchMatches(MatchHistoryQuery query) async {
    final rows = await fetchRows(query);
    return rows
        .map(
          (row) => MatchHistoryItem.fromRow(
            row,
            currentUserId: query.currentUserId,
          ),
        )
        .whereType<MatchHistoryItem>()
        .toList();
  }

  Future<List<dynamic>> fetchRows(MatchHistoryQuery query) async {
    // 閲覧者の参加行で絞り、その行に属する本人メモと、対戦相手用の全参加者を同時取得する。
    // user_idによる絞り込みは認証導入前の表示制御であり、セキュリティ保証ではない。
    var request = client
        .from(MatchHistoryQuery.table)
        .select(MatchHistoryQuery.select)
        .eq(MatchHistoryQuery.participantColumn, query.currentUserId);

    final matchTypes = query.matchTypes;
    if (matchTypes != null && matchTypes.isNotEmpty) {
      final matchTypeValues = matchTypes.map((type) => type.dbValue).toList();
      request = matchTypeValues.length == 1
          ? request.eq(
              MatchHistoryQuery.matchTypeColumn, matchTypeValues.single)
          : request.inFilter(
              MatchHistoryQuery.matchTypeColumn, matchTypeValues);
    }
    if (query.startDate != null) {
      request = request.gte(
        MatchHistoryQuery.matchDateFilterColumn,
        query.startDate!.toUtc().toIso8601String(),
      );
    }
    if (query.endDateExclusive != null) {
      request = request.lt(
        MatchHistoryQuery.matchDateFilterColumn,
        query.endDateExclusive!.toUtc().toIso8601String(),
      );
    }
    final orderedRequest = request.order(
      MatchHistoryQuery.matchDateOrderColumn,
      ascending: query.ascending,
    );
    final response = query.limit == null
        ? await orderedRequest
        : await orderedRequest.limit(query.limit!);
    return response as List<dynamic>;
  }
}
