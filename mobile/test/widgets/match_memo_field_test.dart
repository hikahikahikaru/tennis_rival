import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/constants/app_theme.dart';
import 'package:mobile/widgets/match_memo_field.dart';

void main() {
  Widget buildSubject({
    String initialValue = '',
    bool isSaving = false,
    String? errorMessage,
    required ValueChanged<String> onSave,
  }) {
    return MaterialApp(
      theme: AppTheme.lightTheme,
      home: Scaffold(
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: MatchMemoField(
            initialValue: initialValue,
            isSaving: isSaving,
            errorMessage: errorMessage,
            onSave: onSave,
          ),
        ),
      ),
    );
  }

  testWidgets('shows the title and initial memo', (tester) async {
    await tester.pumpWidget(
      buildSubject(
        initialValue: 'バックハンドが安定していた',
        onSave: (_) {},
      ),
    );

    expect(find.text('個人メモ'), findsOneWidget);
    expect(find.text('バックハンドが安定していた'), findsOneWidget);
  });

  testWidgets('updates the memo when the parent changes initialValue',
      (tester) async {
    await tester.pumpWidget(
      buildSubject(
        initialValue: '変更前のメモ',
        onSave: (_) {},
      ),
    );

    await tester.pumpWidget(
      buildSubject(
        initialValue: '変更後のメモ',
        onSave: (_) {},
      ),
    );

    expect(find.text('変更前のメモ'), findsNothing);
    expect(find.text('変更後のメモ'), findsOneWidget);
  });

  testWidgets('allows editing and passes the current memo on save',
      (tester) async {
    String? savedMemo;
    await tester.pumpWidget(
      buildSubject(onSave: (memo) => savedMemo = memo),
    );

    await tester.enterText(find.byType(TextField), '次回はサーブを改善する');
    await tester.tap(find.text('保存する'));

    expect(savedMemo, '次回はサーブを改善する');
  });

  testWidgets('disables save and shows progress while saving', (tester) async {
    var saveCount = 0;
    await tester.pumpWidget(
      buildSubject(
        isSaving: true,
        onSave: (_) => saveCount++,
      ),
    );

    final button = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
    expect(button.onPressed, isNull);
    expect(find.text('保存中...'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    await tester.tap(find.byType(ElevatedButton));
    await tester.tap(find.byType(ElevatedButton));
    expect(saveCount, 0);
  });

  testWidgets('shows an externally supplied error message', (tester) async {
    await tester.pumpWidget(
      buildSubject(
        errorMessage: 'メモの保存に失敗しました',
        onSave: (_) {},
      ),
    );

    expect(find.text('メモの保存に失敗しました'), findsOneWidget);
  });
}
