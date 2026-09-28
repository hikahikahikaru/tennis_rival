import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/match_history_item.dart';
import '../models/match_type.dart';

abstract class MatchHistoryRepository {
  /// ホーム表示用に、直近2件のシングルス試合を取得する。
  Future<List<MatchHistoryItem>> fetchRecentMatches(String currentUserId);

  /// ユーザー・期間・種別・件数など、指定条件に合う試合を取得する。
  Future<List<MatchHistoryItem>> fetchMatches(MatchHistoryQuery query);
}

/// 試合履歴取得の可変条件。期間を省略すると全期間、件数を省略すると上限なし。
class MatchHistoryQuery {
  final String currentUserId;
  final DateTime? startDate;
  final DateTime? endDateExclusive;
  final Set<MatchType>? matchTypes;
  final int? limit;
  final bool ascending;

  MatchHistoryQuery({
    required this.currentUserId,
    this.startDate,
    this.endDateExclusive,
    this.matchTypes,
    this.limit,
    this.ascending = false,
  }) {
    if (startDate != null &&
        endDateExclusive != null &&
        !startDate!.isBefore(endDateExclusive!)) {
      throw ArgumentError('startDate must be before endDateExclusive');
    }
    if (limit != null && limit! <= 0) {
      throw ArgumentError.value(limit, 'limit', 'must be greater than zero');
    }
  }

  static const String table = 'match_participants';
  static const String participantColumn = 'participant_id';
  static const String matchTypeColumn = 'matches.match_type';
  static const String matchDateFilterColumn = 'matches.dt_match';
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

  factory MatchHistoryQuery.forMonth({
    required String currentUserId,
    required int year,
    required int month,
    Set<MatchType>? matchTypes,
  }) {
    if (month < 1 || month > 12) {
      throw ArgumentError.value(month, 'month', 'must be between 1 and 12');
    }
    final startDate = DateTime(year, month);
    return MatchHistoryQuery(
      currentUserId: currentUserId,
      startDate: startDate,
      endDateExclusive: DateTime(year, month + 1),
      matchTypes: matchTypes,
    );
  }

  factory MatchHistoryQuery.recent(String currentUserId) {
    return MatchHistoryQuery(
      currentUserId: currentUserId,
      matchTypes: const {MatchType.singles},
      limit: recentMatchLimit,
    );
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
