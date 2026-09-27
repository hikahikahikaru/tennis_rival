import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/models/match_history_item.dart';
import 'package:mobile/repositories/match_history_repository.dart';
import 'package:mobile/repositories/match_memo_repository.dart';
import 'package:mobile/services/match_history_service.dart';
import 'package:mobile/services/match_memo_service.dart';

const matchId = 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa';
const currentUserId = '11111111-1111-1111-1111-111111111111';
const opponentUserId = '22222222-2222-2222-2222-222222222222';

void main() {
  group('MatchMemoService', () {
    test('upserts a new memo and updates the history cache', () async {
      final memoRepository = _FakeMatchMemoRepository();
      final historyService = await _historyServiceWithCachedMatch();
      final service = MatchMemoService(
        repository: memoRepository,
        matchHistoryService: historyService,
      );

      final savedMemo = await service.savePersonalMemo(
        matchId: matchId,
        userId: currentUserId,
        memo: ' 新しいメモ ',
      );

      expect(savedMemo, '新しいメモ');
      expect(memoRepository.memos[(matchId, currentUserId)], '新しいメモ');
      expect(
        historyService
            .cachedRecentMatches(currentUserId: currentUserId)
            .single
            .personalMemo,
        '新しいメモ',
      );
    });

    test('updates an existing memo without changing another user memo',
        () async {
      final memoRepository = _FakeMatchMemoRepository(memos: {
        (matchId, currentUserId): '更新前',
        (matchId, opponentUserId): '相手のメモ',
      });
      final service = MatchMemoService(
        repository: memoRepository,
        matchHistoryService: await _historyServiceWithCachedMatch(),
      );

      await service.savePersonalMemo(
        matchId: matchId,
        userId: currentUserId,
        memo: '更新後',
      );

      expect(memoRepository.memos[(matchId, currentUserId)], '更新後');
      expect(memoRepository.memos[(matchId, opponentUserId)], '相手のメモ');
    });

    test('deletes the current user row when the trimmed memo is empty',
        () async {
      final memoRepository = _FakeMatchMemoRepository(memos: {
        (matchId, currentUserId): '削除対象',
        (matchId, opponentUserId): '相手のメモ',
      });
      final historyService = await _historyServiceWithCachedMatch(
        personalMemo: '削除対象',
      );
      final service = MatchMemoService(
        repository: memoRepository,
        matchHistoryService: historyService,
      );

      final savedMemo = await service.savePersonalMemo(
        matchId: matchId,
        userId: currentUserId,
        memo: '   ',
      );

      expect(savedMemo, isNull);
      expect(memoRepository.memos.containsKey((matchId, currentUserId)), false);
      expect(memoRepository.memos[(matchId, opponentUserId)], '相手のメモ');
      expect(
        historyService
            .cachedRecentMatches(currentUserId: currentUserId)
            .single
            .personalMemo,
        isNull,
      );
    });

    test('does not update the cache when persistence fails', () async {
      final memoRepository = _FakeMatchMemoRepository(shouldFail: true);
      final historyService = await _historyServiceWithCachedMatch(
        personalMemo: '保存済み',
      );
      final service = MatchMemoService(
        repository: memoRepository,
        matchHistoryService: historyService,
      );

      await expectLater(
        service.savePersonalMemo(
          matchId: matchId,
          userId: currentUserId,
          memo: '失敗する更新',
        ),
        throwsException,
      );

      expect(
        historyService
            .cachedRecentMatches(currentUserId: currentUserId)
            .single
            .personalMemo,
        '保存済み',
      );
    });
  });
}

Future<MatchHistoryService> _historyServiceWithCachedMatch({
  String? personalMemo,
}) async {
  final historyService = MatchHistoryService(
    repository: _FakeMatchHistoryRepository(personalMemo),
  );
  await historyService.loadRecentMatches(currentUserId: currentUserId);
  return historyService;
}

class _FakeMatchHistoryRepository implements MatchHistoryRepository {
  final String? personalMemo;

  const _FakeMatchHistoryRepository(this.personalMemo);

  @override
  Future<List<MatchHistoryItem>> fetchRecentMatches(String currentUserId) {
    return Future.value([
      MatchHistoryItem(
        matchId: matchId,
        matchDate: DateTime(2026, 8, 24),
        opponentName: '西やん',
        scoreText: '6-4',
        isWin: true,
        personalMemo: personalMemo,
      ),
    ]);
  }
}

class _FakeMatchMemoRepository implements MatchMemoRepository {
  final Map<(String, String), String> memos;
  final bool shouldFail;

  _FakeMatchMemoRepository({
    Map<(String, String), String>? memos,
    this.shouldFail = false,
  }) : memos = {...?memos};

  @override
  Future<void> upsertPersonalMemo({
    required String matchId,
    required String userId,
    required String memo,
  }) async {
    if (shouldFail) {
      throw Exception('save failed');
    }
    memos[(matchId, userId)] = memo;
  }

  @override
  Future<void> deletePersonalMemo({
    required String matchId,
    required String userId,
  }) async {
    if (shouldFail) {
      throw Exception('delete failed');
    }
    memos.remove((matchId, userId));
  }
}
