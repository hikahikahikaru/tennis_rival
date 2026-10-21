import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/screens/group_create_screen.dart';
import 'package:mobile/screens/group_join_screen.dart';
import 'package:mobile/screens/group_list_screen.dart';
import 'package:mobile/widgets/info_box.dart';
import 'package:mobile/widgets/labeled_text_field.dart';

void main() {
  final joinButton = find.widgetWithText(ElevatedButton, 'グループに参加');

  testWidgets('InfoBox shows title and body', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: InfoBox(title: 'タイトル', body: '本文')),
      ),
    );

    expect(find.text('タイトル'), findsOneWidget);
    expect(find.text('本文'), findsOneWidget);
  });

  testWidgets('GroupJoinScreen shows fields, info box and join button',
      (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: GroupJoinScreen()));

    expect(find.byType(LabeledTextField), findsNWidgets(2));
    expect(find.textContaining('招待コード'), findsWidgets);
    expect(find.text('招待コードとは？'), findsOneWidget);
    expect(joinButton, findsOneWidget);
  });

  testWidgets('GroupJoinScreen shows errors when both fields are empty',
      (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: GroupJoinScreen()));

    await tester.tap(joinButton);
    await tester.pump();

    expect(find.text('グループ名を入力してください'), findsOneWidget);
    expect(find.text('招待コードを入力してください'), findsOneWidget);
    expect(find.text('グループ参加は未実装です'), findsNothing);
  });

  testWidgets('GroupJoinScreen shows only invite code error when name entered',
      (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: GroupJoinScreen()));

    await tester.enterText(find.byType(TextField).first, '週末テニス');
    await tester.tap(joinButton);
    await tester.pump();

    expect(find.text('グループ名を入力してください'), findsNothing);
    expect(find.text('招待コードを入力してください'), findsOneWidget);
  });

  testWidgets('GroupJoinScreen clears error when typing',
      (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: GroupJoinScreen()));

    await tester.tap(joinButton);
    await tester.pump();
    await tester.enterText(find.byType(TextField).last, 'ABC123');
    await tester.pump();

    expect(find.text('招待コードを入力してください'), findsNothing);
  });

  testWidgets('GroupJoinScreen shows message when both fields are entered',
      (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: GroupJoinScreen()));

    await tester.enterText(find.byType(TextField).first, '週末テニス');
    await tester.enterText(find.byType(TextField).last, 'ABC123');
    await tester.tap(joinButton);
    await tester.pump();

    expect(find.text('グループ参加は未実装です'), findsOneWidget);
  });

  testWidgets('GroupListScreen opens join screen from join button',
      (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: GroupListScreen()));

    await tester.tap(find.text('グループに参加'));
    await tester.pumpAndSettle();

    expect(find.byType(GroupJoinScreen), findsOneWidget);
    expect(find.byType(GroupCreateScreen), findsNothing);
  });
}
