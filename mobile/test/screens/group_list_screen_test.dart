import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/mocks/mock_data.dart';
import 'package:mobile/models/group_summary.dart';
import 'package:mobile/repositories/group_repository.dart';
import 'package:mobile/screens/group_create_screen.dart';
import 'package:mobile/screens/group_list_screen.dart';
import 'package:mobile/services/group_service.dart';
import 'package:mobile/widgets/group_card.dart';

void main() {
  Widget buildSubject({List<GroupSummary>? groups, GroupService? service}) {
    return MaterialApp(
      home: GroupListScreen(groups: groups, groupService: service),
    );
  }

  testWidgets('shows directly injected groups and action buttons',
      (tester) async {
    await tester.pumpWidget(buildSubject(groups: MockData.groups));

    expect(find.text('所属グループ'), findsOneWidget);
    expect(find.text('週末テニス'), findsOneWidget);
    expect(find.text('テニスサークル'), findsOneWidget);
    expect(find.text('グループ作成'), findsOneWidget);
    expect(find.text('グループに参加'), findsOneWidget);
  });

  testWidgets('shows loading then groups returned by the service',
      (tester) async {
    final response = Completer<List<GroupSummary>>();
    final repository = _FakeGroupRepository(fetchResponses: [response.future]);

    await tester.pumpWidget(
      buildSubject(service: GroupService(repository: repository)),
    );

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text('グループを読み込み中です'), findsOneWidget);

    response.complete(MockData.groups);
    await tester.pumpAndSettle();

    expect(find.text('週末テニス'), findsOneWidget);
    expect(find.text('テニスサークル'), findsOneWidget);
  });

  testWidgets('shows empty message when the service returns no groups',
      (tester) async {
    final repository = _FakeGroupRepository(
      fetchResponses: [Future.value(const [])],
    );

    await tester.pumpWidget(
      buildSubject(service: GroupService(repository: repository)),
    );
    await tester.pumpAndSettle();

    expect(find.text('所属しているグループはまだありません'), findsOneWidget);
    expect(find.byType(GroupCard), findsNothing);
  });

  testWidgets('retries a failed load with forceRefresh', (tester) async {
    final failedResponse = Completer<List<GroupSummary>>();
    final repository = _FakeGroupRepository(fetchResponses: [
      failedResponse.future,
      Future.value(MockData.groups),
    ]);

    await tester.pumpWidget(
      buildSubject(service: GroupService(repository: repository)),
    );
    failedResponse.completeError(Exception('DB error'));
    await tester.pumpAndSettle();

    expect(find.text('グループの取得に失敗しました'), findsOneWidget);
    await tester.tap(find.text('再試行'));
    await tester.pumpAndSettle();

    expect(find.text('週末テニス'), findsOneWidget);
    expect(repository.fetchCount, 2);
  });

  testWidgets('refreshes the list after a group is created', (tester) async {
    const created = GroupSummary(
      id: 'created-group',
      name: '新しいグループ',
      memberCount: 1,
    );
    final repository = _FakeGroupRepository(fetchResponses: [
      Future.value(const []),
      Future.value(const [created]),
    ]);

    await tester.pumpWidget(
      buildSubject(service: GroupService(repository: repository)),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('グループ作成'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, '新しいグループ');
    await tester.tap(find.widgetWithText(ElevatedButton, 'グループ作成'));
    await tester.pumpAndSettle();

    expect(find.byType(GroupCreateScreen), findsNothing);
    expect(find.text('新しいグループ'), findsOneWidget);
    expect(repository.fetchCount, 2);
    expect(repository.createCount, 1);
  });

  testWidgets('does not overwrite a refreshed list with an older response',
      (tester) async {
    final oldResponse = Completer<List<GroupSummary>>();
    final refreshedResponse = Completer<List<GroupSummary>>();
    final repository = _FakeGroupRepository(fetchResponses: [
      oldResponse.future,
      refreshedResponse.future,
    ]);

    await tester.pumpWidget(
      buildSubject(service: GroupService(repository: repository)),
    );
    await tester.tap(find.text('グループ作成'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    await tester.enterText(find.byType(TextField).first, '新しいグループ');
    await tester.tap(find.widgetWithText(ElevatedButton, 'グループ作成'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    refreshedResponse.complete(const [
      GroupSummary(
        id: 'new-group',
        name: '新しい一覧',
        memberCount: 1,
      ),
    ]);
    await tester.pumpAndSettle();
    expect(find.text('新しい一覧'), findsOneWidget);

    oldResponse.complete(const [
      GroupSummary(id: 'old-group', name: '古い一覧', memberCount: 1),
    ]);
    await tester.pumpAndSettle();

    expect(find.text('新しい一覧'), findsOneWidget);
    expect(find.text('古い一覧'), findsNothing);
  });

  testWidgets('keeps action buttons visible with many injected groups',
      (tester) async {
    final groups = List.generate(
      30,
      (i) => GroupSummary(id: 'g$i', name: 'グループ$i', memberCount: i + 1),
    );
    await tester.pumpWidget(buildSubject(groups: groups));

    expect(find.text('グループ作成'), findsOneWidget);
    expect(find.text('グループに参加'), findsOneWidget);
  });

  testWidgets('opens create screen when create button is tapped',
      (tester) async {
    final service = GroupService(repository: _FakeGroupRepository());
    await tester.pumpWidget(
      buildSubject(groups: MockData.groups, service: service),
    );

    await tester.tap(find.text('グループ作成'));
    await tester.pumpAndSettle();

    expect(find.byType(GroupCreateScreen), findsOneWidget);
  });
}

class _FakeGroupRepository implements GroupRepository {
  _FakeGroupRepository({this.fetchResponses = const []});

  final List<Future<List<GroupSummary>>> fetchResponses;
  var fetchCount = 0;
  var createCount = 0;

  @override
  String? get currentUserId => 'user-1';

  @override
  Future<List<GroupSummary>> fetchGroups() {
    final index = fetchCount++;
    if (index < fetchResponses.length) return fetchResponses[index];
    return Future.value(const []);
  }

  @override
  Future<String> createGroup({
    required String name,
    String? description,
  }) async {
    createCount++;
    return 'created-group';
  }
}
