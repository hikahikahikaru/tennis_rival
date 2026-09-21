import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/models/match_history_item.dart';
import 'package:mobile/repositories/match_history_repository.dart';
import 'package:mobile/services/match_history_service.dart';

const userA = '11111111-1111-1111-1111-111111111111';
const userB = '22222222-2222-2222-2222-222222222222';

void main() {
  group('MatchHistoryService', () {
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
  });
}

class _FakeMatchHistoryRepository implements MatchHistoryRepository {
  final Map<String, List<Completer<List<MatchHistoryItem>>>> responses;
  final Map<String, int> fetchCounts = {};

  _FakeMatchHistoryRepository({
    this.responses = const {},
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
}

List<MatchHistoryItem> _matchesFor(String userId) {
  return [
    MatchHistoryItem(
      matchDate: DateTime(2026, 8, 24),
      opponentName: userId == userA ? '西やん' : 'たけし',
      scoreText: '6-4, 6-3',
      isWin: true,
    ),
  ];
}
