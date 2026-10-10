import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/models/match_detail.dart';
import 'package:mobile/models/match_format.dart';
import 'package:mobile/models/match_history_item.dart';
import 'package:mobile/models/match_set_score.dart';
import 'package:mobile/models/match_type.dart';
import 'package:mobile/repositories/match_detail_repository.dart';
import 'package:mobile/services/match_detail_service.dart';

void main() {
  test('loads a match detail through the repository', () async {
    final repository = _FakeMatchDetailRepository();
    final service = MatchDetailService(repository: repository);

    final detail = await service.loadMatchDetail(
      matchId: 'match-1',
      currentUserId: 'user-1',
    );

    expect(repository.receivedMatchId, 'match-1');
    expect(repository.receivedCurrentUserId, 'user-1');
    expect(detail.matchId, 'match-1');
  });

  test('forwards repository errors', () async {
    const error = MatchDetailNotFoundException('missing-match');
    final service = MatchDetailService(
      repository: _FakeMatchDetailRepository(error: error),
    );

    await expectLater(
      service.loadMatchDetail(
        matchId: 'missing-match',
        currentUserId: 'user-1',
      ),
      throwsA(same(error)),
    );
  });
}

class _FakeMatchDetailRepository implements MatchDetailRepository {
  final Object? error;
  String? receivedMatchId;
  String? receivedCurrentUserId;

  _FakeMatchDetailRepository({this.error});

  @override
  Future<MatchDetail> fetchMatchDetail({
    required String matchId,
    required String currentUserId,
  }) async {
    receivedMatchId = matchId;
    receivedCurrentUserId = currentUserId;
    if (error != null) throw error!;

    return MatchDetail(
      historyItem: MatchHistoryItem(
        matchId: matchId,
        matchDate: DateTime(2026, 8, 24),
        currentUserName: 'たけし',
        opponentName: '西やん',
        scoreText: '6-4',
        isWin: true,
        matchType: MatchType.singles,
        matchFormat: MatchFormat.oneSet,
        setScores: const [
          MatchSetScore(myScore: 6, opponentScore: 4),
        ],
      ),
      currentUserId: currentUserId,
      opponentId: 'user-2',
      winnerId: currentUserId,
      participants: const [
        MatchDetailParticipant(userId: 'user-1', displayName: 'たけし'),
        MatchDetailParticipant(userId: 'user-2', displayName: '西やん'),
      ],
      sets: const [
        MatchDetailSet(
          setNumber: 1,
          score: MatchSetScore(myScore: 6, opponentScore: 4),
          winnerId: 'user-1',
        ),
      ],
    );
  }
}
