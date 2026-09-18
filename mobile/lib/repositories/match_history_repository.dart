import 'package:supabase_flutter/supabase_flutter.dart';

import '../constants/app_strings.dart';
import '../models/match_history_item.dart';
import '../models/match_set_score.dart';

abstract class MatchHistoryRepository {
  Future<List<MatchHistoryItem>> fetchRecentMatches(String currentUserId);
}

class MatchHistoryQuery {
  final String currentUserId;

  const MatchHistoryQuery._({required this.currentUserId});

  static const String table = 'match_participants';
  static const String participantColumn = 'participant_id';
  static const String matchTypeColumn = 'matches.match_type';
  static const int singlesMatchType = 1;
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

/// Supabaseから試合履歴を取得し、画面がそのまま表示できる形へ変換するRepository。
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
    return _toMatchHistoryItems(rows, currentUserId);
  }

  Future<List<dynamic>> fetchRows(MatchHistoryQuery query) async {
    // 閲覧者の参加行で絞り、同じ試合に属する全参加者も埋め込んで対戦相手を得る。
    final response = await client
        .from(MatchHistoryQuery.table)
        .select(MatchHistoryQuery.select)
        .eq(MatchHistoryQuery.participantColumn, query.currentUserId)
        .eq(MatchHistoryQuery.matchTypeColumn,
            MatchHistoryQuery.singlesMatchType)
        .order(
          MatchHistoryQuery.matchDateOrderColumn,
          referencedTable: MatchHistoryQuery.matchesReferencedTable,
          ascending: false,
        );

    return response as List<dynamic>;
  }

  List<MatchHistoryItem> _toMatchHistoryItems(
    List<dynamic> rows,
    String currentUserId,
  ) {
    final items = <MatchHistoryItem>[];

    for (final row in rows) {
      final rowMap = _asMap(row);
      if (rowMap == null) {
        continue;
      }

      final matchMap = _asMap(rowMap['matches']);
      if (matchMap == null) {
        continue;
      }

      if (_asInt(matchMap['match_type']) !=
          MatchHistoryQuery.singlesMatchType) {
        continue;
      }

      final participantRows = _asList(matchMap['match_participants']);
      final participantIds = participantRows
          .map(_asMap)
          .whereType<Map<String, dynamic>>()
          .map((participant) => participant['participant_id'] as String?)
          .whereType<String>()
          .toSet();

      if (!participantIds.contains(currentUserId)) {
        continue;
      }

      final opponentName = _findOpponentName(participantRows, currentUserId);
      final score1UserId = matchMap['score1_user_id'] as String?;
      final scoreText = _buildScoreText(
        matchMap: matchMap,
        participantIds: participantIds,
        currentUserId: currentUserId,
        score1UserId: score1UserId,
      );
      final isWin = _resolveResult(
        winnerId: matchMap['winner'] as String?,
        participantIds: participantIds,
        currentUserId: currentUserId,
      );

      items.add(
        MatchHistoryItem(
          matchDate: _parseDate(matchMap['dt_match']),
          opponentName: opponentName,
          scoreText: scoreText,
          isWin: isWin,
        ),
      );
    }

    items.sort((a, b) => b.matchDate.compareTo(a.matchDate));
    return items;
  }

  String _findOpponentName(
      List<dynamic> participantRows, String currentUserId) {
    for (final participantRow in participantRows) {
      final participant = _asMap(participantRow);
      if (participant == null ||
          participant['participant_id'] == currentUserId) {
        continue;
      }

      final user = _asMap(participant['users']);
      final userName = user?['user_name'] as String?;
      if (userName != null && userName.isNotEmpty) {
        return userName;
      }
    }

    return AppStrings.unselected;
  }

  String _buildScoreText({
    required Map<String, dynamic> matchMap,
    required Set<String> participantIds,
    required String currentUserId,
    required String? score1UserId,
  }) {
    if (score1UserId == null || !participantIds.contains(score1UserId)) {
      // score1の所有者が不明な保存済みデータでは、左右を推測せず安全に不明表示にする。
      return AppStrings.matchScoreUnknown;
    }

    final viewerIsScore1 = score1UserId == currentUserId;
    final setRows = _asList(matchMap['set_scores'])
        .map(_asMap)
        .whereType<Map<String, dynamic>>()
        .toList()
      ..sort((a, b) => _asInt(a['set_no']).compareTo(_asInt(b['set_no'])));

    final setScores = setRows.map((setRow) {
      final score1 = _asInt(setRow['score1']);
      final score2 = _asInt(setRow['score2']);
      final tScore1 = _asNullableInt(setRow['t_score1']);
      final tScore2 = _asNullableInt(setRow['t_score2']);

      // score1は登録者側の値なので、閲覧者がscore2側なら通常スコアもタイブレークも左右を入れ替える。
      return MatchSetScore(
        myScore: viewerIsScore1 ? score1 : score2,
        opponentScore: viewerIsScore1 ? score2 : score1,
        myTiebreakScore: viewerIsScore1 ? tScore1 : tScore2,
        opponentTiebreakScore: viewerIsScore1 ? tScore2 : tScore1,
      );
    }).toList();

    if (setScores.isEmpty) {
      return AppStrings.matchScoreUnknown;
    }

    return setScores.map((setScore) => setScore.displayScore).join(', ');
  }

  bool? _resolveResult({
    required String? winnerId,
    required Set<String> participantIds,
    required String currentUserId,
  }) {
    if (winnerId == null || !participantIds.contains(winnerId)) {
      // winnerが未保存または参加者外の場合、相手勝利とは断定しない。
      return null;
    }

    return winnerId == currentUserId;
  }

  Map<String, dynamic>? _asMap(Object? value) {
    if (value is Map<String, dynamic>) {
      return value;
    }

    if (value is Map) {
      return Map<String, dynamic>.from(value);
    }

    return null;
  }

  List<dynamic> _asList(Object? value) {
    if (value is List) {
      return value;
    }

    return const [];
  }

  DateTime _parseDate(Object? value) {
    if (value is DateTime) {
      return value;
    }

    return DateTime.parse(value as String);
  }

  int _asInt(Object? value) {
    if (value is int) {
      return value;
    }

    return int.parse(value.toString());
  }

  int? _asNullableInt(Object? value) {
    if (value == null) {
      return null;
    }

    return _asInt(value);
  }
}
