import 'match_format.dart';
import 'match_history_item.dart';
import 'match_set_score.dart';
import 'match_type.dart';

/// 試合詳細取得に必要な関連データが不足していることを表す。
class IncompleteMatchDetailException implements Exception {
  final String message;

  const IncompleteMatchDetailException(this.message);

  @override
  String toString() => 'IncompleteMatchDetailException: $message';
}

/// 閲覧者が対象試合の参加者ではないことを表す。
class MatchDetailParticipantMismatchException implements Exception {
  final String matchId;
  final String currentUserId;

  const MatchDetailParticipantMismatchException({
    required this.matchId,
    required this.currentUserId,
  });

  @override
  String toString() =>
      'MatchDetailParticipantMismatchException: $currentUserId is not a participant of $matchId';
}

/// 対象外の試合種別が指定されたことを表す。
class UnsupportedMatchDetailTypeException implements Exception {
  final Object? matchType;

  const UnsupportedMatchDetailTypeException(this.matchType);

  @override
  String toString() =>
      'UnsupportedMatchDetailTypeException: match type $matchType is not supported';
}

class MatchDetailParticipant {
  final String userId;
  final String displayName;

  const MatchDetailParticipant({
    required this.userId,
    required this.displayName,
  });
}

class MatchDetailSet {
  final int setNumber;
  final MatchSetScore? score;
  final String? winnerId;

  const MatchDetailSet({
    required this.setNumber,
    required this.score,
    required this.winnerId,
  });
}

/// DB行を、閲覧者視点のスコアと参加者情報を持つ試合詳細へ変換する。
class MatchDetail {
  final MatchHistoryItem historyItem;
  final String currentUserId;
  final String opponentId;
  final String? winnerId;
  final List<MatchDetailParticipant> participants;
  final List<MatchDetailSet> sets;

  const MatchDetail({
    required this.historyItem,
    required this.currentUserId,
    required this.opponentId,
    required this.winnerId,
    required this.participants,
    required this.sets,
  });

  String get matchId => historyItem.matchId!;
  DateTime get matchDate => historyItem.matchDate;
  MatchType get matchType => historyItem.matchType;
  MatchFormat get matchFormat => historyItem.matchFormat;
  String get currentUserName => historyItem.currentUserName;
  String get opponentName => historyItem.opponentName;
  bool? get isWin => historyItem.isWin;
  List<MatchSetScore> get setScores => historyItem.setScores;

  factory MatchDetail.fromRow(
    Object? row, {
    required String currentUserId,
  }) {
    try {
      return _fromRow(row, currentUserId: currentUserId);
    } on MatchDetailParticipantMismatchException {
      rethrow;
    } on UnsupportedMatchDetailTypeException {
      rethrow;
    } on IncompleteMatchDetailException {
      rethrow;
    } catch (error) {
      throw IncompleteMatchDetailException(
        'Failed to parse related match data: $error',
      );
    }
  }

  static MatchDetail _fromRow(
    Object? row, {
    required String currentUserId,
  }) {
    final matchMap = _asMap(row);
    final matchId = matchMap?['match_id'] as String?;
    if (matchMap == null || matchId == null || matchId.isEmpty) {
      throw const IncompleteMatchDetailException('match_id is missing');
    }

    final matchTypeValue = _asInt(matchMap['match_type']);
    if (matchTypeValue != MatchType.singles.dbValue) {
      throw UnsupportedMatchDetailTypeException(matchMap['match_type']);
    }

    final participants = _buildParticipants(matchMap['match_participants']);
    final participantIds = participants.map((item) => item.userId).toSet();
    if (!participantIds.contains(currentUserId)) {
      throw MatchDetailParticipantMismatchException(
        matchId: matchId,
        currentUserId: currentUserId,
      );
    }
    if (participants.length != 2 || participantIds.length != 2) {
      throw const IncompleteMatchDetailException(
        'A singles match must have exactly two participants',
      );
    }

    final rawWinnerId = matchMap['winner'] as String?;
    final winnerId = participantIds.contains(rawWinnerId) ? rawWinnerId : null;

    // 一覧と同じ変換処理を通し、スコア左右・対戦相手名・勝敗の解釈を一元化する。
    final historyItem = MatchHistoryItem.fromRow(
      {'matches': matchMap},
      currentUserId: currentUserId,
    );
    if (historyItem == null) {
      throw const IncompleteMatchDetailException(
        'Failed to build viewer-oriented match data',
      );
    }

    final setRows = _asList(matchMap['set_scores'])
        .map(_asMap)
        .whereType<Map<String, dynamic>>()
        .toList()
      ..sort((a, b) => _asInt(a['set_no']).compareTo(_asInt(b['set_no'])));
    if (setRows.isEmpty || setRows.length > MatchFormat.threeSets.setCount) {
      throw const IncompleteMatchDetailException(
        'set score data is missing or inconsistent',
      );
    }

    final hasViewerOrientedScores =
        historyItem.setScores.length == setRows.length;

    final sets = <MatchDetailSet>[];
    for (var index = 0; index < setRows.length; index++) {
      final setRow = setRows[index];
      final rawSetWinnerId = setRow['set_winner'] as String?;
      final setWinnerId =
          participantIds.contains(rawSetWinnerId) ? rawSetWinnerId : null;
      sets.add(
        MatchDetailSet(
          setNumber: _asInt(setRow['set_no']),
          score: hasViewerOrientedScores ? historyItem.setScores[index] : null,
          winnerId: setWinnerId,
        ),
      );
    }

    final opponent = participants.singleWhere(
      (participant) => participant.userId != currentUserId,
    );
    return MatchDetail(
      historyItem: historyItem,
      currentUserId: currentUserId,
      opponentId: opponent.userId,
      winnerId: winnerId,
      participants: List.unmodifiable(participants),
      sets: List.unmodifiable(sets),
    );
  }

  static List<MatchDetailParticipant> _buildParticipants(Object? value) {
    return _asList(value).map((row) {
      final participant = _asMap(row);
      final userId = participant?['participant_id'] as String?;
      final displayName =
          _asMap(participant?['users'])?['user_name'] as String?;
      if (userId == null ||
          userId.isEmpty ||
          displayName == null ||
          displayName.isEmpty) {
        throw const IncompleteMatchDetailException(
          'participant data is missing',
        );
      }
      return MatchDetailParticipant(
        userId: userId,
        displayName: displayName,
      );
    }).toList();
  }

  static Map<String, dynamic>? _asMap(Object? value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return Map<String, dynamic>.from(value);
    return null;
  }

  static List<dynamic> _asList(Object? value) {
    return value is List ? value : const [];
  }

  static int _asInt(Object? value) {
    return value is int ? value : int.parse(value.toString());
  }
}
