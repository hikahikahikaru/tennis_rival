import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/models/group_summary.dart';
import 'package:mobile/repositories/group_repository.dart';
import 'package:mobile/screens/group_create_screen.dart';
import 'package:mobile/services/group_service.dart';
import 'package:mobile/widgets/labeled_text_field.dart';

void main() {
  testWidgets('LabeledTextField shows label, required mark and hint',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: LabeledTextField(
            label: 'グループ名',
            hint: '例：週末テニス',
            controller: TextEditingController(),
            isRequired: true,
          ),
        ),
      ),
    );

    expect(find.textContaining('グループ名'), findsOneWidget);
    expect(find.textContaining('※'), findsOneWidget);
    expect(find.text('例：週末テニス'), findsOneWidget);
  });

  testWidgets('LabeledTextField hides required mark by default',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: LabeledTextField(
            label: '説明',
            hint: 'ヒント',
            controller: TextEditingController(),
          ),
        ),
      ),
    );

    expect(find.textContaining('※'), findsNothing);
  });

  testWidgets('LabeledTextField shows errorText', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: LabeledTextField(
            label: '名前',
            hint: 'ヒント',
            controller: TextEditingController(),
            errorText: 'エラー',
          ),
        ),
      ),
    );

    expect(find.text('エラー'), findsOneWidget);
  });

  testWidgets('shows fields, note and create button', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: GroupCreateScreen()));

    expect(find.byType(LabeledTextField), findsNWidgets(2));
    expect(find.text('グループの説明（任意）'), findsOneWidget);
    expect(find.text('作成後、メンバーを招待できます。'), findsOneWidget);
    expect(find.widgetWithText(ElevatedButton, 'グループ作成'), findsOneWidget);
  });

  testWidgets('does not create a group when its name is empty', (tester) async {
    final repository = _FakeGroupRepository();
    await tester.pumpWidget(_subject(repository));

    await tester.tap(find.widgetWithText(ElevatedButton, 'グループ作成'));
    await tester.pump();

    expect(find.text('グループ名を入力してください'), findsOneWidget);
    expect(repository.createCount, 0);
  });

  testWidgets('clears the required error when typing', (tester) async {
    await tester.pumpWidget(_subject(_FakeGroupRepository()));

    await tester.tap(find.widgetWithText(ElevatedButton, 'グループ作成'));
    await tester.pump();
    await tester.enterText(find.byType(TextField).first, '週末テニス');
    await tester.pump();

    expect(find.text('グループ名を入力してください'), findsNothing);
  });

  testWidgets('prevents duplicate submissions while creating', (tester) async {
    final createResponse = Completer<String>();
    final repository =
        _FakeGroupRepository(createResponse: createResponse.future);
    await tester.pumpWidget(_subject(repository));
    await tester.enterText(find.byType(TextField).first, '週末テニス');

    await tester.tap(find.widgetWithText(ElevatedButton, 'グループ作成'));
    await tester.pump();
    expect(find.text('作成中...'), findsOneWidget);
    await tester.tap(
      find.widgetWithText(ElevatedButton, '作成中...'),
      warnIfMissed: false,
    );
    await tester.pump();

    expect(repository.createCount, 1);
    createResponse.complete('group-1');
    await tester.pumpAndSettle();
  });

  testWidgets('shows an error and keeps the screen after creation fails',
      (tester) async {
    final createResponse = Completer<String>();
    final repository = _FakeGroupRepository(
      createResponse: createResponse.future,
    );
    await tester.pumpWidget(_subject(repository));
    await tester.enterText(find.byType(TextField).first, '週末テニス');

    await tester.tap(find.widgetWithText(ElevatedButton, 'グループ作成'));
    createResponse.completeError(Exception('DB error'));
    await tester.pumpAndSettle();

    expect(find.text('グループの作成に失敗しました'), findsOneWidget);
    expect(find.byType(GroupCreateScreen), findsOneWidget);
    expect(find.text('週末テニス'), findsOneWidget);
  });

  testWidgets('shows authentication guidance for an unauthenticated user',
      (tester) async {
    final repository = _FakeGroupRepository(authenticatedUserId: null);
    await tester.pumpWidget(_subject(repository));
    await tester.enterText(find.byType(TextField).first, '週末テニス');

    await tester.tap(find.widgetWithText(ElevatedButton, 'グループ作成'));
    await tester.pumpAndSettle();

    expect(find.text('ログインが必要です'), findsOneWidget);
    expect(repository.createCount, 0);
  });
}

Widget _subject(_FakeGroupRepository repository) {
  return MaterialApp(
    home: GroupCreateScreen(
      groupService: GroupService(repository: repository),
    ),
  );
}

class _FakeGroupRepository implements GroupRepository {
  _FakeGroupRepository({
    this.authenticatedUserId = 'user-1',
    Future<String>? createResponse,
  }) : _createResponse = createResponse ?? Future.value('group-1');

  final String? authenticatedUserId;
  final Future<String> _createResponse;
  var createCount = 0;

  @override
  String? get currentUserId => authenticatedUserId;

  @override
  Future<List<GroupSummary>> fetchGroups() async => const [];

  @override
  Future<String> createGroup({
    required String name,
    String? description,
  }) {
    createCount++;
    return _createResponse;
  }
}
