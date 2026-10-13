import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mobile/models/match_detail.dart';
import 'package:mobile/repositories/match_detail_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

const currentUserId = '11111111-1111-1111-1111-111111111111';
const opponentId = '22222222-2222-2222-2222-222222222222';
const outsiderId = '99999999-9999-9999-9999-999999999999';

void main() {
  group('SupabaseMatchDetailRepository', () {
    test('fetches one match with participants, scores, and set winners',
        () async {
      final requests = <http.Request>[];
      final client = SupabaseClient(
        'https://example.test',
        'test-anon-key',
        httpClient: MockClient((request) async {
          requests.add(request);
          return http.Response(
            jsonEncode([
              _matchRow(
                sets: [
                  _setScore(
                    setNo: 2,
                    score1: 6,
                    score2: 3,
                    winnerId: currentUserId,
                  ),
                  _setScore(
                    setNo: 1,
                    score1: 7,
                    score2: 6,
                    winnerId: currentUserId,
                    tScore1: 8,
                    tScore2: 6,
                  ),
                ],
              ),
            ]),
            200,
            headers: {'content-type': 'application/json'},
            request: request,
          );
        }),
      );
      addTearDown(client.dispose);

      final detail =
          await SupabaseMatchDetailRepository(client: client).fetchMatchDetail(
        matchId: 'match-1',
        currentUserId: currentUserId,
      );

      final request = requests.single;
      expect(request.url.path, '/rest/v1/matches');
      expect(request.url.queryParameters['match_id'], 'eq.match-1');
      expect(request.url.queryParameters['limit'], '1');
      expect(request.url.queryParameters['select'], contains('set_winner'));
      expect(
        request.url.queryParameters['select'],
        contains('match_participants'),
      );
      expect(detail.matchId, 'match-1');
      expect(detail.historyItem.matchId, 'match-1');
      expect(detail.opponentId, opponentId);
      expect(detail.opponentName, '西やん');
      expect(detail.winnerId, currentUserId);
      expect(detail.isWin, isTrue);
      expect(detail.sets.map((set) => set.setNumber), [1, 2]);
      expect(detail.setScores.map((score) => score.displayScore), [
        '7-6 (8-6)',
        '6-3',
      ]);
      expect(
        detail.sets.map((set) => set.winnerId),
        [currentUserId, currentUserId],
      );
    });

    test('allows an existing personal memo to be carried into the history item',
        () async {
      final detail = await _FakeMatchDetailRepository(
        rows: [_matchRow()],
      ).fetchMatchDetail(
        matchId: 'match-1',
        currentUserId: currentUserId,
      );

      final historyItem = detail.historyItem.copyWithPersonalMemo('既存の個人メモ');

      expect(historyItem.personalMemo, '既存の個人メモ');
      expect(historyItem.opponentName, '西やん');
      expect(historyItem.setScores.single.displayScore, '6-4');
    });

    test('swaps scores for score2 participant and marks a loss', () async {
      final repository = _FakeMatchDetailRepository(
        rows: [
          _matchRow(
            winnerId: currentUserId,
            score1UserId: currentUserId,
            sets: [
              _setScore(
                setNo: 1,
                score1: 7,
                score2: 6,
                winnerId: currentUserId,
                tScore1: 8,
                tScore2: 6,
              ),
            ],
          ),
        ],
      );

      final detail = await repository.fetchMatchDetail(
        matchId: 'match-1',
        currentUserId: opponentId,
      );

      expect(detail.opponentId, currentUserId);
      expect(detail.opponentName, 'たけし');
      expect(detail.isWin, isFalse);
      expect(detail.setScores.single.displayScore, '6-7 (6-8)');
      expect(detail.sets.single.winnerId, currentUserId);
    });

    test('supports one through three sets and sorts by set number', () async {
      for (var setCount = 1; setCount <= 3; setCount++) {
        final sets = [
          for (var setNo = setCount; setNo >= 1; setNo--)
            _setScore(
              setNo: setNo,
              score1: 6,
              score2: 4,
              winnerId: currentUserId,
            ),
        ];
        final detail = await _FakeMatchDetailRepository(
          rows: [_matchRow(sets: sets)],
        ).fetchMatchDetail(
          matchId: 'match-1',
          currentUserId: currentUserId,
        );

        expect(
          detail.sets.map((set) => set.setNumber),
          [for (var setNo = 1; setNo <= setCount; setNo++) setNo],
        );
      }
    });

    test('keeps an unknown result when winner is null', () async {
      final detail = await _FakeMatchDetailRepository(
        rows: [_matchRow(winnerId: null)],
      ).fetchMatchDetail(
        matchId: 'match-1',
        currentUserId: currentUserId,
      );

      expect(detail.winnerId, isNull);
      expect(detail.isWin, isNull);
    });

    test('keeps scores unknown when score1 user is null', () async {
      final detail = await _FakeMatchDetailRepository(
        rows: [_matchRow(score1UserId: null)],
      ).fetchMatchDetail(
        matchId: 'match-1',
        currentUserId: currentUserId,
      );

      expect(detail.historyItem.scoreText, 'スコア不明');
      expect(detail.setScores, isEmpty);
      expect(detail.sets.single.score, isNull);
    });

    test('keeps a set winner unknown when set winner is null', () async {
      final detail = await _FakeMatchDetailRepository(
        rows: [
          _matchRow(
            sets: [
              _setScore(
                setNo: 1,
                score1: 6,
                score2: 4,
                winnerId: null,
              ),
            ],
          ),
        ],
      ).fetchMatchDetail(
        matchId: 'match-1',
        currentUserId: currentUserId,
      );

      expect(detail.setScores.single.displayScore, '6-4');
      expect(detail.sets.single.winnerId, isNull);
    });

    test('throws not found when the match ID does not exist', () async {
      final repository = _FakeMatchDetailRepository(rows: const []);

      await expectLater(
        repository.fetchMatchDetail(
          matchId: 'missing-match',
          currentUserId: currentUserId,
        ),
        throwsA(isA<MatchDetailNotFoundException>()),
      );
    });

    test('throws participant mismatch when viewer is not in the match',
        () async {
      final repository = _FakeMatchDetailRepository(rows: [_matchRow()]);

      await expectLater(
        repository.fetchMatchDetail(
          matchId: 'match-1',
          currentUserId: outsiderId,
        ),
        throwsA(isA<MatchDetailParticipantMismatchException>()),
      );
    });

    test('throws incomplete data when participant relation is missing',
        () async {
      final repository = _FakeMatchDetailRepository(
        rows: [
          _matchRow(
            participants: [_participant(currentUserId, 'たけし')],
          ),
        ],
      );

      await expectLater(
        repository.fetchMatchDetail(
          matchId: 'match-1',
          currentUserId: currentUserId,
        ),
        throwsA(isA<IncompleteMatchDetailException>()),
      );
    });

    test('forwards Supabase communication failures', () async {
      final client = SupabaseClient(
        'https://example.test',
        'test-anon-key',
        httpClient: MockClient((request) async {
          return http.Response(
            jsonEncode({'message': 'DB error'}),
            500,
            headers: {'content-type': 'application/json'},
            request: request,
          );
        }),
      );
      addTearDown(client.dispose);

      await expectLater(
        SupabaseMatchDetailRepository(client: client).fetchMatchDetail(
          matchId: 'match-1',
          currentUserId: currentUserId,
        ),
        throwsA(isA<PostgrestException>()),
      );
    });
  });
}

class _FakeMatchDetailRepository extends SupabaseMatchDetailRepository {
  final List<dynamic> rows;

  _FakeMatchDetailRepository({required this.rows});

  @override
  Future<List<dynamic>> fetchRows(String matchId) async => rows;
}

Map<String, dynamic> _matchRow({
  String matchId = 'match-1',
  String? winnerId = currentUserId,
  String? score1UserId = currentUserId,
  List<Map<String, dynamic>>? participants,
  List<Map<String, dynamic>>? sets,
}) {
  return {
    'match_id': matchId,
    'dt_match': '2026-08-24T10:00:00+09:00',
    'match_type': 1,
    'total_set_amount': 3,
    'winner': winnerId,
    'score1_user_id': score1UserId,
    'match_participants': participants ??
        [
          _participant(currentUserId, 'たけし'),
          _participant(opponentId, '西やん'),
        ],
    'set_scores': sets ??
        [
          _setScore(
            setNo: 1,
            score1: 6,
            score2: 4,
            winnerId: currentUserId,
          ),
        ],
  };
}

Map<String, dynamic> _participant(String userId, String displayName) {
  return {
    'participant_id': userId,
    'users': {
      'user_id': userId,
      'user_name': displayName,
    },
  };
}

Map<String, dynamic> _setScore({
  required int setNo,
  required int score1,
  required int score2,
  required String? winnerId,
  int? tScore1,
  int? tScore2,
}) {
  return {
    'set_no': setNo,
    'score1': score1,
    'score2': score2,
    't_score1': tScore1,
    't_score2': tScore2,
    'set_winner': winnerId,
  };
}
