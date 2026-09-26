import '../constants/app_strings.dart';
import 'match_set_score.dart';
import 'match_format.dart';
import 'match_type.dart';

/// ホーム画面の最近の試合へ表示する、閲覧者視点へ変換済みの試合履歴。
class MatchHistoryItem {
  final String? matchId;
  final DateTime matchDate;
  final String currentUserName;
  final String opponentName;
  final String scoreText;
  final bool? isWin;
  final MatchFormat matchFormat;
  final List<MatchSetScore> setScores;
  final String? personalMemo;

  const MatchHistoryItem({
    this.matchId,
    required this.matchDate,
    this.currentUserName = AppStrings.scoreMy,
    required this.opponentName,
    required this.scoreText,
    required this.isWin,
    this.matchFormat = MatchFormat.oneSet,
    this.setScores = const [],
    this.personalMemo,
  });

  String get displayDate {
    final localDate = matchDate.toLocal();
    return '${localDate.month}月${localDate.day}日';
  }

  String get detailDate {
    final localDate = matchDate.toLocal();
    final weekday = AppStrings.weekdaysJapanese[localDate.weekday - 1];
    return '${localDate.year}年${localDate.month}月${localDate.day}日（$weekday）';
  }

  int get myWonSetCount => setScores.where((score) => score.isMyWin).length;

  int get opponentWonSetCount =>
      setScores.where((score) => score.opponentScore > score.myScore).length;

  /// DB行を閲覧者視点の表示データへ変換する。
  static MatchHistoryItem? fromRow(
    Object? row, {
    required String currentUserId,
  }) {
    final rowMap = _asMap(row);
    final matchMap = _asMap(rowMap?['matches']);
    if (matchMap == null ||
        _asInt(matchMap['match_type']) != MatchType.singles.dbValue) {
      return null;
    }

    final participantRows = _asList(matchMap['match_participants']);
    final participantIds = participantRows
        .map(_asMap)
        .whereType<Map<String, dynamic>>()
        .map((participant) => participant['participant_id'] as String?)
        .whereType<String>()
        .toSet();
    if (!participantIds.contains(currentUserId)) {
      return null;
    }

    return MatchHistoryItem(
      matchId: matchMap['match_id'] as String?,
      matchDate: _parseDate(matchMap['dt_match']),
      currentUserName: _findCurrentUserName(participantRows, currentUserId),
      opponentName: _findOpponentName(participantRows, currentUserId),
      scoreText: _buildScoreText(
        setScores: _buildSetScores(
          matchMap: matchMap,
          participantIds: participantIds,
          currentUserId: currentUserId,
        ),
      ),
      isWin: _resolveResult(
        winnerId: matchMap['winner'] as String?,
        participantIds: participantIds,
        currentUserId: currentUserId,
      ),
      matchFormat: _formatFromSetCount(matchMap['total_set_amount']),
      setScores: _buildSetScores(
        matchMap: matchMap,
        participantIds: participantIds,
        currentUserId: currentUserId,
      ),
      personalMemo: _findPersonalMemo(
        rowMap?['match_memos'],
        currentUserId,
      ),
    );
  }

  static String? _findPersonalMemo(
    Object? memoResponse,
    String currentUserId,
  ) {
    final memoRows = switch (memoResponse) {
      Map() => [memoResponse],
      List() => memoResponse,
      _ => const <Object?>[],
    };

    for (final memoRow in memoRows) {
      final memo = _asMap(memoRow);
      if (memo?['user_id'] != currentUserId) {
        continue;
      }

      final value = memo?['memo'];
      if (value is! String || value.trim().isEmpty) {
        return null;
      }
      return value.trim();
    }
    return null;
  }

  static String _findCurrentUserName(
    List<dynamic> participantRows,
    String currentUserId,
  ) {
    for (final participantRow in participantRows) {
      final participant = _asMap(participantRow);
      if (participant?['participant_id'] != currentUserId) {
        continue;
      }

      final userName = _asMap(participant?['users'])?['user_name'] as String?;
      if (userName != null && userName.isNotEmpty) {
        return userName;
      }
    }
    return AppStrings.scoreMy;
  }

  static String _findOpponentName(
    List<dynamic> participantRows,
    String currentUserId,
  ) {
    for (final participantRow in participantRows) {
      final participant = _asMap(participantRow);
      if (participant == null ||
          participant['participant_id'] == currentUserId) {
        continue;
      }

      final userName = _asMap(participant['users'])?['user_name'] as String?;
      if (userName != null && userName.isNotEmpty) {
        return userName;
      }
    }
    return AppStrings.matchOpponentUnknown;
  }

  static List<MatchSetScore> _buildSetScores({
    required Map<String, dynamic> matchMap,
    required Set<String> participantIds,
    required String currentUserId,
  }) {
    final score1UserId = matchMap['score1_user_id'] as String?;
    if (score1UserId == null || !participantIds.contains(score1UserId)) {
      // 登録者側が不明な保存済みデータでは、スコアの左右を推測しない。
      return const [];
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

      // score1は登録者側なので、閲覧者が相手側なら通常スコアとタイブレークを左右反転する。
      return MatchSetScore(
        myScore: viewerIsScore1 ? score1 : score2,
        opponentScore: viewerIsScore1 ? score2 : score1,
        myTiebreakScore: viewerIsScore1 ? tScore1 : tScore2,
        opponentTiebreakScore: viewerIsScore1 ? tScore2 : tScore1,
      );
    }).toList();

    if (setScores.isEmpty) {
      return const [];
    }
    return setScores;
  }

  static String _buildScoreText({
    required List<MatchSetScore> setScores,
  }) {
    if (setScores.isEmpty) {
      return AppStrings.matchScoreUnknown;
    }
    return setScores.map((score) => score.displayScore).join(', ');
  }

  static MatchFormat _formatFromSetCount(Object? value) {
    return value != null && _asInt(value) == MatchFormat.threeSets.setCount
        ? MatchFormat.threeSets
        : MatchFormat.oneSet;
  }

  static bool? _resolveResult({
    required String? winnerId,
    required Set<String> participantIds,
    required String currentUserId,
  }) {
    if (winnerId == null || !participantIds.contains(winnerId)) {
      // 勝者が未保存または参加者外なら、敗北と推測せず判定不能にする。
      return null;
    }
    return winnerId == currentUserId;
  }

  static Map<String, dynamic>? _asMap(Object? value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return Map<String, dynamic>.from(value);
    return null;
  }

  static List<dynamic> _asList(Object? value) {
    return value is List ? value : const [];
  }

  static DateTime _parseDate(Object? value) {
    return value is DateTime ? value : DateTime.parse(value as String);
  }

  static int _asInt(Object? value) {
    return value is int ? value : int.parse(value.toString());
  }

  static int? _asNullableInt(Object? value) {
    return value == null ? null : _asInt(value);
  }
}
