import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/models/match_history_item.dart';
import 'package:mobile/models/match_history_query.dart';
import 'package:mobile/models/match_type.dart';
import 'package:mobile/repositories/match_history_repository.dart';
import 'package:mobile/services/match_history_service.dart';

const userA = '11111111-1111-1111-1111-111111111111';
const userB = '22222222-2222-2222-2222-222222222222';

void main() {
  group('MatchHistoryService', () {
    test(
        'loads requested month through the repository without using home cache',
        () async {
      final repository = _FakeMatchHistoryRepository();
      final service = MatchHistoryService(repository: repository);
      final query = MatchHistoryQuery.forMonth(
        currentUserId: userA,
        year: 2026,
        month: 8,
        matchTypes: const {MatchType.singles},
      );

      final matches = await service.loadMatches(query);

      expect(matches, hasLength(1));
      expect(repository.lastQuery, same(query));
      expect(service.cachedRecentMatches(currentUserId: userA), isEmpty);
    });

    test('caches the startup month by user and calendar month', () async {
      final repository = _FakeMatchHistoryRepository();
      final service = MatchHistoryService(repository: repository);

      final august = await service.loadMatchesByMonth(
        currentUserId: userA,
        year: 2026,
        month: 8,
      );
      final cachedAugust = await service.loadMatchesByMonth(
        currentUserId: userA,
        year: 2026,
        month: 8,
      );
      final september = await service.loadMatchesByMonth(
        currentUserId: userA,
        year: 2026,
        month: 9,
      );
      final otherUserAugust = await service.loadMatchesByMonth(
        currentUserId: userB,
        year: 2026,
        month: 8,
      );

      expect(identical(august, cachedAugust), isTrue);
      expect(august.single.opponentName, '2026-8');
      expect(september.single.opponentName, '2026-9');
      expect(otherUserAugust.single.opponentName, '2026-8');
      expect(repository.monthFetchCount, 3);
      expect(
        service.cachedMatchesByMonth(
          currentUserId: userA,
          year: 2026,
          month: 8,
        ),
        same(august),
      );
    });

    test('shares an in-flight request for the same cached month key', () async {
      final response = Completer<List<MatchHistoryItem>>();
      final repository = _FakeMatchHistoryRepository(
        monthResponses: {'2026-8': response},
      );
      final service = MatchHistoryService(repository: repository);

      final first = service.loadMatchesByMonth(
        currentUserId: userA,
        year: 2026,
        month: 8,
      );
      final second = service.loadMatchesByMonth(
        currentUserId: userA,
        year: 2026,
        month: 8,
      );

      expect(identical(first, second), isTrue);
      expect(repository.monthFetchCount, 1);
      response.complete([_matchFor(userA, '8月の試合')]);
      await Future.wait([first, second]);
    });

    test('does not mix responses for different users and months', () async {
      final repository = _FakeMatchHistoryRepository();
      final service = MatchHistoryService(repository: repository);
      final augustQuery = MatchHistoryQuery.forMonth(
        currentUserId: userA,
        year: 2026,
        month: 8,
      );
      final septemberQuery = MatchHistoryQuery.forMonth(
        currentUserId: userB,
        year: 2026,
        month: 9,
        matchTypes: const {MatchType.doubles},
      );

      final augustMatches = await service.loadMatches(augustQuery);
      final septemberMatches = await service.loadMatches(septemberQuery);

      expect(augustMatches.single.opponentName, '2026-8');
      expect(septemberMatches.single.opponentName, '2026-9');
      expect(repository.receivedQueries, [augustQuery, septemberQuery]);
    });

    test('returns an empty list for an empty month and forwards errors',
        () async {
      final repository = _FakeMatchHistoryRepository(
        monthResponses: {
          '2026-7': const [],
          '2026-6': Exception('DB error'),
        },
      );
      final service = MatchHistoryService(repository: repository);

      final emptyMatches = await service.loadMatches(
        MatchHistoryQuery.forMonth(
          currentUserId: userA,
          year: 2026,
          month: 7,
        ),
      );
      expect(emptyMatches, isEmpty);

      await expectLater(
        service.loadMatches(
          MatchHistoryQuery.forMonth(
            currentUserId: userA,
            year: 2026,
            month: 6,
          ),
        ),
        throwsA(isA<Exception>()),
      );
    });

    test('reuses preloaded cache without another repository request', () async {
      final repository = _FakeMatchHistoryRepository();
      final service = MatchHistoryService(repository: repository);

      final preloaded = await service.loadRecentMatches(currentUserId: userA);
      final loadedByHome =
          await service.loadRecentMatches(currentUserId: userA);

      expect(preloaded, same(loadedByHome));
      expect(
          service.cachedRecentMatches(currentUserId: userA), same(preloaded));
      expect(repository.fetchCounts[userA], 1);
    });

    test('shares one in-flight request for the same user', () async {
      final response = Completer<List<MatchHistoryItem>>();
      final repository = _FakeMatchHistoryRepository(responses: {
        userA: [response],
      });
      final service = MatchHistoryService(repository: repository);

      final first = service.loadRecentMatches(currentUserId: userA);
      final second = service.loadRecentMatches(currentUserId: userA);

      expect(identical(first, second), isTrue);
      expect(repository.fetchCounts[userA], 1);

      response.complete(const []);
      await Future.wait([first, second]);
    });

    test('starts separate requests and caches for different users', () async {
      final userAResponse = Completer<List<MatchHistoryItem>>();
      final userBResponse = Completer<List<MatchHistoryItem>>();
      final repository = _FakeMatchHistoryRepository(responses: {
        userA: [userAResponse],
        userB: [userBResponse],
      });
      final service = MatchHistoryService(repository: repository);

      final requestA = service.loadRecentMatches(currentUserId: userA);
      final requestB = service.loadRecentMatches(currentUserId: userB);

      expect(identical(requestA, requestB), isFalse);
      expect(repository.fetchCounts[userA], 1);
      expect(repository.fetchCounts[userB], 1);

      userAResponse.complete(const []);
      userBResponse.complete(const []);
      await Future.wait([requestA, requestB]);
    });

    test('allows another request after a failure', () async {
      final failedResponse = Completer<List<MatchHistoryItem>>();
      final retryResponse = Completer<List<MatchHistoryItem>>();
      final repository = _FakeMatchHistoryRepository(responses: {
        userA: [failedResponse, retryResponse],
      });
      final service = MatchHistoryService(repository: repository);

      final failedRequest = service.loadRecentMatches(currentUserId: userA);
      final failedExpectation = expectLater(
        failedRequest,
        throwsA(isA<Exception>()),
      );
      failedResponse.completeError(Exception('DB error'));
      await failedExpectation;

      final retryRequest = service.loadRecentMatches(currentUserId: userA);
      expect(repository.fetchCounts[userA], 2);

      retryResponse.complete(const []);
      await retryRequest;
    });

    test('forceRefresh bypasses a completed cache', () async {
      final repository = _FakeMatchHistoryRepository();
      final service = MatchHistoryService(repository: repository);

      await service.loadRecentMatches(currentUserId: userA);
      await service.loadRecentMatches(
        currentUserId: userA,
        forceRefresh: true,
      );

      expect(repository.fetchCounts[userA], 2);
    });

    test('does not cache a response that started before cache invalidation',
        () async {
      final staleResponse = Completer<List<MatchHistoryItem>>();
      final freshResponse = Completer<List<MatchHistoryItem>>();
      final repository = _FakeMatchHistoryRepository(responses: {
        userA: [staleResponse, freshResponse],
      });
      final service = MatchHistoryService(repository: repository);

      final staleRequest = service.loadRecentMatches(currentUserId: userA);
      service.clearCache();
      final freshRequest = service.loadRecentMatches(currentUserId: userA);

      final staleMatch = _matchFor(userA, '古い試合');
      staleResponse.complete([staleMatch]);
      await staleRequest;
      expect(service.cachedRecentMatches(currentUserId: userA), isEmpty);

      final freshMatch = _matchFor(userA, '新しい試合');
      freshResponse.complete([freshMatch]);
      await freshRequest;

      expect(service.cachedRecentMatches(currentUserId: userA), [freshMatch]);
    });

    test('memo update is not overwritten by an older in-flight response',
        () async {
      final initialResponse = Completer<List<MatchHistoryItem>>()
        ..complete([_matchFor(userA, '西やん', personalMemo: '更新前')]);
      final staleResponse = Completer<List<MatchHistoryItem>>();
      final repository = _FakeMatchHistoryRepository(responses: {
        userA: [initialResponse, staleResponse],
      });
      final service = MatchHistoryService(repository: repository);

      await service.loadRecentMatches(currentUserId: userA);
      final staleRequest = service.loadRecentMatches(
        currentUserId: userA,
        forceRefresh: true,
      );
      service.updatePersonalMemo(
        currentUserId: userA,
        matchId: 'match-id',
        personalMemo: '更新後',
      );

      staleResponse.complete([
        _matchFor(userA, '西やん', personalMemo: '更新前'),
      ]);
      await staleRequest;

      expect(
        service.cachedRecentMatches(currentUserId: userA).single.personalMemo,
        '更新後',
      );
    });
  });
}

class _FakeMatchHistoryRepository implements MatchHistoryRepository {
  final Map<String, List<Completer<List<MatchHistoryItem>>>> responses;
  final Map<String, Object> monthResponses;
  final Map<String, int> fetchCounts = {};
  final List<MatchHistoryQuery> receivedQueries = [];
  int monthFetchCount = 0;
  MatchHistoryQuery? lastQuery;

  _FakeMatchHistoryRepository({
    this.responses = const {},
    this.monthResponses = const {},
  });

  @override
  Future<List<MatchHistoryItem>> fetchRecentMatches(String currentUserId) {
    fetchCounts.update(
      currentUserId,
      (count) => count + 1,
      ifAbsent: () => 1,
    );

    final queuedResponses = responses[currentUserId];
    if (queuedResponses == null) {
      return Future.value(_matchesFor(currentUserId));
    }
    return queuedResponses.removeAt(0).future;
  }

  @override
  Future<List<MatchHistoryItem>> fetchMatches(MatchHistoryQuery query) async {
    monthFetchCount++;
    lastQuery = query;
    receivedQueries.add(query);
    final monthKey = '${query.startDate!.year}-${query.startDate!.month}';
    final response = monthResponses[monthKey];
    if (response is Exception) {
      throw response;
    }
    if (response is Completer<List<MatchHistoryItem>>) {
      return response.future;
    }
    if (response is List) {
      return response.cast<MatchHistoryItem>();
    }
    return [_matchesFor(query.currentUserId, monthKey).single];
  }
}

List<MatchHistoryItem> _matchesFor(String userId, [String? opponentName]) {
  return [
    _matchFor(
      userId,
      opponentName ?? (userId == userA ? '西やん' : 'たけし'),
    ),
  ];
}

MatchHistoryItem _matchFor(
  String userId,
  String opponentName, {
  String? personalMemo,
}) {
  return MatchHistoryItem(
    matchId: 'match-id',
    matchDate: DateTime(2026, 8, 24),
    opponentName: opponentName,
    scoreText: '6-4, 6-3',
    isWin: true,
    personalMemo: personalMemo,
  );
}
