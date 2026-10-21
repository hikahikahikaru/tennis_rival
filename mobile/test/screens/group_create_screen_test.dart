import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/screens/group_create_screen.dart';
import 'package:mobile/widgets/labeled_text_field.dart';

void main() {
  testWidgets('LabeledTextField shows label, required mark and hint',
      (WidgetTester tester) async {
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
      (WidgetTester tester) async {
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

  testWidgets('LabeledTextField shows errorText', (WidgetTester tester) async {
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

  testWidgets('GroupCreateScreen shows fields, note and create button',
      (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: GroupCreateScreen()));

    expect(find.byType(LabeledTextField), findsNWidgets(2));
    expect(find.text('グループの説明（任意）'), findsOneWidget);
    expect(find.text('作成後、メンバーを招待できます。'), findsOneWidget);
    expect(find.widgetWithText(ElevatedButton, 'グループ作成'), findsOneWidget);
  });

  testWidgets('GroupCreateScreen shows error when name is empty',
      (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: GroupCreateScreen()));

    await tester.tap(find.widgetWithText(ElevatedButton, 'グループ作成'));
    await tester.pump();

    expect(find.text('グループ名を入力してください'), findsOneWidget);
    expect(find.text('グループ作成は未実装です'), findsNothing);
  });

  testWidgets('GroupCreateScreen clears error when typing',
      (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: GroupCreateScreen()));

    await tester.tap(find.widgetWithText(ElevatedButton, 'グループ作成'));
    await tester.pump();
    await tester.enterText(find.byType(TextField).first, '週末テニス');
    await tester.pump();

    expect(find.text('グループ名を入力してください'), findsNothing);
  });

  testWidgets('GroupCreateScreen shows message when name is entered',
      (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: GroupCreateScreen()));

    await tester.enterText(find.byType(TextField).first, '週末テニス');
    await tester.tap(find.widgetWithText(ElevatedButton, 'グループ作成'));
    await tester.pump();

    expect(find.text('グループ作成は未実装です'), findsOneWidget);
  });
}
