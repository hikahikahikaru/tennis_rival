import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mobile/models/match_type.dart';
import 'package:mobile/repositories/match_history_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

const String takeshiId = '11111111-1111-1111-1111-111111111111';
const String nishiyanId = '22222222-2222-2222-2222-222222222222';
const String pinchanId = '33333333-3333-3333-3333-333333333333';
const String outsiderId = '99999999-9999-9999-9999-999999999999';

void main() {
  group('SupabaseMatchHistoryRepository', () {
    test('shares an in-flight request for the same user', () async {
      final response = Completer<List<dynamic>>();
      final repository = _ControllableSupabaseMatchHistoryRepository({
        takeshiId: [response],
      });

      final first = repository.fetchRecentMatches(takeshiId);
      final second = repository.fetchRecentMatches(takeshiId);

      expect(identical(first, second), isTrue);
      expect(repository.fetchCounts[takeshiId], 1);

      response.complete(const []);
      await Future.wait([first, second]);
    });

    test('starts separate in-flight requests for different users', () async {
      final takeshiResponse = Completer<List<dynamic>>();
      final nishiyanResponse = Completer<List<dynamic>>();
      final repository = _ControllableSupabaseMatchHistoryRepository({
        takeshiId: [takeshiResponse],
        nishiyanId: [nishiyanResponse],
      });

      final takeshiRequest = repository.fetchRecentMatches(takeshiId);
      final nishiyanRequest = repository.fetchRecentMatches(nishiyanId);

      expect(identical(takeshiRequest, nishiyanRequest), isFalse);
      expect(repository.fetchCounts[takeshiId], 1);
      expect(repository.fetchCounts[nishiyanId], 1);

      takeshiResponse.complete(const []);
      nishiyanResponse.complete(const []);
      await Future.wait([takeshiRequest, nishiyanRequest]);
    });

    test('allows retry after a shared request fails', () async {
      final failedResponse = Completer<List<dynamic>>();
      final retryResponse = Completer<List<dynamic>>();
      final repository = _ControllableSupabaseMatchHistoryRepository({
        takeshiId: [failedResponse, retryResponse],
      });

      final failedRequest = repository.fetchRecentMatches(takeshiId);
      final failedExpectation = expectLater(
        failedRequest,
        throwsA(isA<Exception>()),
      );
      failedResponse.completeError(Exception('DB error'));
      await failedExpectation;

      final retryRequest = repository.fetchRecentMatches(takeshiId);
      expect(repository.fetchCounts[takeshiId], 2);

      retryResponse.complete(const []);
      await retryRequest;
    });

    test('sends filtered single request and converts its HTTP response',
        () async {
      final requests = <http.Request>[];
      // 偽HTTPで実際のfetchRowsを通し、生成された条件と変換結果を別々に確認する。
      final client = SupabaseClient(
        'https://example.test',
        'test-anon-key',
        httpClient: MockClient((request) async {
          requests.add(request);
          return http.Response(
            jsonEncode([
              _matchRow(
                matchId: 'match-1',
                dtMatch: '2026-08-24T10:00:00+09:00',
                winner: takeshiId,
                score1UserId: takeshiId,
                participants: [
                  _participant(takeshiId, 'たけし'),
                  _participant(nishiyanId, '西やん'),
                ],
                sets: [
                  _setScore(
                      setNo: 1, score1: 7, score2: 6, tScore1: 8, tScore2: 6),
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

      final matches = await SupabaseMatchHistoryRepository(client: client)
          .fetchRecentMatches(takeshiId);

      expect(requests, hasLength(1));
      final request = requests.single;
      expect(request.method, 'GET');
      expect(request.url.origin, 'https://example.test');
      expect(request.url.path, '/rest/v1/match_participants');
      final query = request.url.queryParameters;
      expect(query['select'], contains('matches!inner('));
      expect(query['select'], contains('score1_user_id'));
      expect(query['select'],
          contains('set_scores(set_no,score1,score2,t_score1,t_score2)'));
      expect(query['select'],
          contains('users!match_participants_participant_id_fkey'));
      expect(query['participant_id'], 'eq.$takeshiId');
      expect(query['matches.match_type'], 'eq.1');
      expect(query['order'], 'matches(dt_match).desc.nullslast');
      expect(query['limit'], '5');
      expect(matches, hasLength(1));
      expect(matches.single.opponentName, '西やん');
      expect(matches.single.scoreText, '7-6 (8-6)');
      expect(matches.single.isWin, isTrue);
      // 結合名の妥当性は実DBのスキーマ適用後に別途確認する。
    });

    test('builds singles match query and excludes matches without current user',
        () async {
      final repository = _FakeSupabaseMatchHistoryRepository(
        rows: [
          _matchRow(
            matchId: 'other-match',
            dtMatch: '2026-08-25 10:00:00+09',
            winner: outsiderId,
            score1UserId: outsiderId,
            participants: [
              _participant(outsiderId, '別ユーザー'),
              _participant(pinchanId, 'ピンちゃん'),
            ],
            sets: [
              _setScore(setNo: 1, score1: 6, score2: 4),
            ],
          ),
          _matchRow(
            matchId: 'takeshi-match',
            dtMatch: '2026-08-24 10:00:00+09',
            winner: takeshiId,
            score1UserId: takeshiId,
            participants: [
              _participant(takeshiId, 'たけし'),
              _participant(nishiyanId, '西やん'),
            ],
            sets: [
              _setScore(setNo: 1, score1: 6, score2: 4),
            ],
          ),
        ],
      );

      final matches = await repository.fetchRecentMatches(takeshiId);
      final query = repository.lastQuery;

      expect(query, isNotNull);
      expect(query!.currentUserId, takeshiId);
      expect(MatchHistoryQuery.table, 'match_participants');
      expect(MatchHistoryQuery.participantColumn, 'participant_id');
      expect(MatchHistoryQuery.matchTypeColumn, 'matches.match_type');
      expect(MatchHistoryQuery.recentMatchLimit, 5);
      expect(MatchType.singles.dbValue, 1);
      expect(MatchHistoryQuery.select, contains('score1_user_id'));
      expect(MatchHistoryQuery.select, contains('set_scores'));
      expect(MatchHistoryQuery.select, contains('match_participants'));
      expect(matches, hasLength(1));
      expect(matches.single.opponentName, '西やん');
    });

    test('preserves DB date order and sorts sets by set number', () async {
      final repository = _FakeSupabaseMatchHistoryRepository(
        rows: [
          _matchRow(
            matchId: 'new-match',
            dtMatch: '2026-08-24 10:00:00+09',
            winner: takeshiId,
            score1UserId: takeshiId,
            participants: [
              _participant(takeshiId, 'たけし'),
              _participant(nishiyanId, '西やん'),
            ],
            sets: [
              _setScore(setNo: 2, score1: 6, score2: 4),
              _setScore(
                setNo: 1,
                score1: 7,
                score2: 6,
                tScore1: 8,
                tScore2: 6,
              ),
            ],
          ),
          _matchRow(
            matchId: 'old-match',
            dtMatch: '2026-08-18 14:00:00+09',
            winner: takeshiId,
            score1UserId: takeshiId,
            participants: [
              _participant(takeshiId, 'たけし'),
              _participant(pinchanId, 'ピンちゃん'),
            ],
            sets: [
              _setScore(setNo: 3, score1: 10, score2: 8),
              _setScore(setNo: 1, score1: 4, score2: 6),
              _setScore(setNo: 2, score1: 7, score2: 5),
            ],
          ),
        ],
      );

      final matches = await repository.fetchRecentMatches(takeshiId);

      expect(matches[0].opponentName, '西やん');
      expect(matches[0].scoreText, '7-6 (8-6), 6-4');
      expect(matches[1].opponentName, 'ピンちゃん');
      expect(matches[1].scoreText, '4-6, 7-5, 10-8');
    });

    test('uses score1 side for registrant view and marks win', () async {
      final repository = _FakeSupabaseMatchHistoryRepository(
        rows: [
          _matchRow(
            matchId: 'registrant-match',
            dtMatch: '2026-08-24 10:00:00+09',
            winner: takeshiId,
            score1UserId: takeshiId,
            participants: [
              _participant(takeshiId, 'たけし'),
              _participant(nishiyanId, '西やん'),
            ],
            sets: [
              _setScore(
                setNo: 1,
                score1: 7,
                score2: 6,
                tScore1: 8,
                tScore2: 6,
              ),
            ],
          ),
        ],
      );

      final matches = await repository.fetchRecentMatches(takeshiId);

      expect(matches.single.scoreText, '7-6 (8-6)');
      expect(matches.single.isWin, isTrue);
    });

    test('swaps scores and tiebreaks for opponent view and marks lose',
        () async {
      final repository = _FakeSupabaseMatchHistoryRepository(
        rows: [
          _matchRow(
            matchId: 'opponent-match',
            dtMatch: '2026-08-24 10:00:00+09',
            winner: takeshiId,
            score1UserId: takeshiId,
            participants: [
              _participant(takeshiId, 'たけし'),
              _participant(nishiyanId, '西やん'),
            ],
            sets: [
              _setScore(
                setNo: 1,
                score1: 7,
                score2: 6,
                tScore1: 8,
                tScore2: 6,
              ),
            ],
          ),
        ],
      );

      final matches = await repository.fetchRecentMatches(nishiyanId);

      expect(matches.single.opponentName, 'たけし');
      expect(matches.single.scoreText, '6-7 (6-8)');
      expect(matches.single.isWin, isFalse);
    });

    test('does not treat null or inconsistent winner as lose', () async {
      final repository = _FakeSupabaseMatchHistoryRepository(
        rows: [
          _matchRow(
            matchId: 'unknown-winner',
            dtMatch: '2026-08-24 10:00:00+09',
            winner: null,
            score1UserId: takeshiId,
            participants: [
              _participant(takeshiId, 'たけし'),
              _participant(nishiyanId, '西やん'),
            ],
            sets: [
              _setScore(setNo: 1, score1: 6, score2: 4),
            ],
          ),
          _matchRow(
            matchId: 'invalid-winner',
            dtMatch: '2026-08-23 10:00:00+09',
            winner: outsiderId,
            score1UserId: takeshiId,
            participants: [
              _participant(takeshiId, 'たけし'),
              _participant(nishiyanId, '西やん'),
            ],
            sets: [
              _setScore(setNo: 1, score1: 6, score2: 4),
            ],
          ),
        ],
      );

      final matches = await repository.fetchRecentMatches(takeshiId);

      expect(matches[0].isWin, isNull);
      expect(matches[1].isWin, isNull);
    });

    test('shows unknown score when score1 user is missing or inconsistent',
        () async {
      final repository = _FakeSupabaseMatchHistoryRepository(
        rows: [
          _matchRow(
            matchId: 'missing-score-side',
            dtMatch: '2026-08-24 10:00:00+09',
            winner: takeshiId,
            score1UserId: null,
            participants: [
              _participant(takeshiId, 'たけし'),
              _participant(nishiyanId, '西やん'),
            ],
            sets: [
              _setScore(setNo: 1, score1: 6, score2: 4),
            ],
          ),
          _matchRow(
            matchId: 'invalid-score-side',
            dtMatch: '2026-08-23 10:00:00+09',
            winner: takeshiId,
            score1UserId: outsiderId,
            participants: [
              _participant(takeshiId, 'たけし'),
              _participant(nishiyanId, '西やん'),
            ],
            sets: [
              _setScore(setNo: 1, score1: 6, score2: 4),
            ],
          ),
        ],
      );

      final matches = await repository.fetchRecentMatches(takeshiId);

      expect(matches[0].scoreText, 'スコア不明');
      expect(matches[1].scoreText, 'スコア不明');
    });
  });
}

class _FakeSupabaseMatchHistoryRepository
    extends SupabaseMatchHistoryRepository {
  final List<dynamic> rows;
  MatchHistoryQuery? lastQuery;

  _FakeSupabaseMatchHistoryRepository({required this.rows});

  @override
  Future<List<dynamic>> fetchRows(MatchHistoryQuery query) async {
    lastQuery = query;
    return rows;
  }
}

class _ControllableSupabaseMatchHistoryRepository
    extends SupabaseMatchHistoryRepository {
  final Map<String, List<Completer<List<dynamic>>>> responses;
  final Map<String, int> fetchCounts = {};

  _ControllableSupabaseMatchHistoryRepository(this.responses);

  @override
  Future<List<dynamic>> fetchRows(MatchHistoryQuery query) {
    fetchCounts.update(
      query.currentUserId,
      (count) => count + 1,
      ifAbsent: () => 1,
    );
    return responses[query.currentUserId]!.removeAt(0).future;
  }
}

Map<String, dynamic> _matchRow({
  required String matchId,
  required String dtMatch,
  required String? winner,
  required String? score1UserId,
  required List<Map<String, dynamic>> participants,
  required List<Map<String, dynamic>> sets,
}) {
  return {
    'match_id': matchId,
    'participant_id': takeshiId,
    'matches': {
      'match_id': matchId,
      'dt_match': dtMatch,
      'match_type': 1,
      'total_set_amount': 3,
      'winner': winner,
      'score1_user_id': score1UserId,
      'match_participants': participants,
      'set_scores': sets,
    },
  };
}

Map<String, dynamic> _participant(String id, String name) {
  return {
    'participant_id': id,
    'users': {
      'user_id': id,
      'user_name': name,
    },
  };
}

Map<String, dynamic> _setScore({
  required int setNo,
  required int score1,
  required int score2,
  int? tScore1,
  int? tScore2,
}) {
  return {
    'set_no': setNo,
    'score1': score1,
    'score2': score2,
    't_score1': tScore1,
    't_score2': tScore2,
  };
}
