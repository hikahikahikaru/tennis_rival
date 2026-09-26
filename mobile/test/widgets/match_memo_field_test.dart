import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/constants/app_theme.dart';
import 'package:mobile/widgets/match_memo_field.dart';

void main() {
  Widget buildSubject({
    String initialValue = '',
    required ValueChanged<String> onChanged,
  }) {
    return MaterialApp(
      theme: AppTheme.lightTheme,
      home: Scaffold(
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: MatchMemoField(
            initialValue: initialValue,
            onChanged: onChanged,
          ),
        ),
      ),
    );
  }

  testWidgets('shows the title and initial memo', (tester) async {
    await tester.pumpWidget(
      buildSubject(
        initialValue: 'バックハンドが安定していた',
        onChanged: (_) {},
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
        onChanged: (_) {},
      ),
    );

    await tester.pumpWidget(
      buildSubject(
        initialValue: '変更後のメモ',
        onChanged: (_) {},
      ),
    );

    expect(find.text('変更前のメモ'), findsNothing);
    expect(find.text('変更後のメモ'), findsOneWidget);
  });

  testWidgets('passes the current memo to onChanged when edited',
      (tester) async {
    String? changedMemo;
    await tester.pumpWidget(
      buildSubject(onChanged: (memo) => changedMemo = memo),
    );

    await tester.enterText(find.byType(TextField), '次回はサーブを改善する');

    expect(changedMemo, '次回はサーブを改善する');
  });

  testWidgets('does not contain a save button', (tester) async {
    await tester.pumpWidget(
      buildSubject(onChanged: (_) {}),
    );

    expect(find.byType(ElevatedButton), findsNothing);
    expect(find.text('保存する'), findsNothing);
  });
}
