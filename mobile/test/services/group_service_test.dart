import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/models/group_summary.dart';
import 'package:mobile/repositories/group_repository.dart';
import 'package:mobile/services/group_service.dart';

const userA = '11111111-1111-1111-1111-111111111111';
const userB = '22222222-2222-2222-2222-222222222222';

void main() {
  group('GroupService', () {
    test('reuses the cached groups and forceRefresh fetches them again',
        () async {
      final repository = _FakeGroupRepository();
      final service = GroupService(repository: repository);

      final first = await service.loadGroups();
      final cached = await service.loadGroups();
      final refreshed = await service.loadGroups(forceRefresh: true);

      expect(first, same(cached));
      expect(first.single.name, 'グループ-$userA');
      expect(refreshed.single.name, 'グループ-$userA');
      expect(repository.fetchCounts[userA], 2);
    });

    test('shares an in-flight request for the same user', () async {
      final response = Completer<List<GroupSummary>>();
      final repository = _FakeGroupRepository(responses: {
        userA: [response],
      });
      final service = GroupService(repository: repository);

      final first = service.loadGroups();
      final second = service.loadGroups();

      expect(identical(first, second), isTrue);
      expect(repository.fetchCounts[userA], 1);
      response.complete(const []);
      await Future.wait([first, second]);
    });

    test('keeps caches separate when the authenticated user changes', () async {
      final repository = _FakeGroupRepository();
      final service = GroupService(repository: repository);

      final groupsA = await service.loadGroups();
      repository.authenticatedUserId = userB;
      final groupsB = await service.loadGroups();
      repository.authenticatedUserId = userA;
      final cachedA = await service.loadGroups();

      expect(groupsA.single.name, 'グループ-$userA');
      expect(groupsB.single.name, 'グループ-$userB');
      expect(cachedA, same(groupsA));
      expect(repository.fetchCounts, {userA: 1, userB: 1});
    });

    test('does not cache an old result after user change and clearCache',
        () async {
      final oldResponse = Completer<List<GroupSummary>>();
      final repository = _FakeGroupRepository(responses: {
        userA: [oldResponse],
      });
      final service = GroupService(repository: repository);

      final oldRequest = service.loadGroups();
      service.clearCache();
      repository.authenticatedUserId = userB;
      final groupsB = await service.loadGroups();
      oldResponse.complete(const [
        GroupSummary(id: 'old', name: '古い結果', memberCount: 1),
      ]);
      await oldRequest;

      repository.authenticatedUserId = userA;
      expect(service.cachedGroups(), isEmpty);
      repository.authenticatedUserId = userB;
      expect(service.cachedGroups(), same(groupsB));
    });

    test('clears the current user cache after creating a group', () async {
      final repository = _FakeGroupRepository();
      final service = GroupService(repository: repository);
      await service.loadGroups();

      final createdId = await service.createGroup(
        name: '新規グループ',
        description: '説明',
      );

      expect(createdId, 'created-group');
      expect(service.cachedGroups(), isEmpty);
      expect(repository.createdNames, ['新規グループ']);
      await service.loadGroups();
      expect(repository.fetchCounts[userA], 2);
    });

    test('does not clear cache when group creation fails', () async {
      final repository = _FakeGroupRepository()..createError = Exception('失敗');
      final service = GroupService(repository: repository);
      final cached = await service.loadGroups();

      await expectLater(
        service.createGroup(name: '失敗するグループ'),
        throwsA(isA<Exception>()),
      );

      expect(service.cachedGroups(), same(cached));
    });

    test('rejects operations when no user is authenticated', () async {
      final repository = _FakeGroupRepository()..authenticatedUserId = null;
      final service = GroupService(repository: repository);

      expect(
        () => service.loadGroups(),
        throwsA(isA<GroupAuthenticationRequiredException>()),
      );
      await expectLater(
        service.createGroup(name: '未認証'),
        throwsA(isA<GroupAuthenticationRequiredException>()),
      );
      expect(repository.fetchCounts, isEmpty);
    });
  });
}

class _FakeGroupRepository implements GroupRepository {
  _FakeGroupRepository({this.responses = const {}});

  final Map<String, List<Completer<List<GroupSummary>>>> responses;
  final Map<String, int> fetchCounts = {};
  final List<String> createdNames = [];
  String? authenticatedUserId = userA;
  Object? createError;

  @override
  String? get currentUserId => authenticatedUserId;

  @override
  Future<List<GroupSummary>> fetchGroups() {
    final userId = authenticatedUserId!;
    final fetchIndex = fetchCounts.update(
      userId,
      (count) => count + 1,
      ifAbsent: () => 1,
    );
    final queued = responses[userId];
    if (queued != null && queued.length >= fetchIndex) {
      return queued[fetchIndex - 1].future;
    }
    return Future.value([
      GroupSummary(
        id: 'group-$userId',
        name: 'グループ-$userId',
        memberCount: 1,
      ),
    ]);
  }

  @override
  Future<String> createGroup({
    required String name,
    String? description,
  }) async {
    final error = createError;
    if (error != null) throw error;
    createdNames.add(name);
    return 'created-group';
  }
}
