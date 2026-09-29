import 'match_type.dart';

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
