import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/constants/app_theme.dart';
import 'package:mobile/models/match_format.dart';
import 'package:mobile/models/match_history_item.dart';
import 'package:mobile/models/match_set_score.dart';
import 'package:mobile/widgets/match_detail_sheet.dart';
import 'package:mobile/widgets/match_memo_field.dart';

void main() {
  Future<void> showDetail(
    WidgetTester tester,
    MatchHistoryItem match, {
    Future<String?> Function(String memo)? onSaveMemo,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () => MatchDetailSheet.show(
                context,
                match: match,
                onSaveMemo: onSaveMemo ??
                    (memo) async {
                      final normalized = memo.trim();
                      return normalized.isEmpty ? null : normalized;
                    },
              ),
              child: const Text('詳細を開く'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('詳細を開く'));
    await tester.pumpAndSettle();
  }

  testWidgets('long opponent name does not overflow the detail sheet',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(320, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final match = MatchHistoryItem(
      matchId: 'match-1',
      matchDate: DateTime(2026, 8, 24),
      currentUserName: 'たけし',
      opponentName: 'とても長い対戦相手の名前で横幅に収まらない場合の表示確認用',
      scoreText: '6-4, 6-3',
      isWin: true,
      matchFormat: MatchFormat.threeSets,
      setScores: const [
        MatchSetScore(myScore: 6, opponentScore: 4),
        MatchSetScore(myScore: 6, opponentScore: 3),
      ],
    );

    await showDetail(tester, match);

    expect(find.text(match.opponentName), findsNWidgets(2));
    expect(tester.takeException(), isNull);
  });

  testWidgets('shows the fetched personal memo', (tester) async {
    final match = MatchHistoryItem(
      matchDate: DateTime(2026, 8, 24),
      opponentName: '西やん',
      scoreText: '6-4',
      isWin: true,
      personalMemo: 'バックハンドが安定していた',
    );

    await showDetail(tester, match);

    expect(find.text('個人メモ'), findsOneWidget);
    expect(find.text('バックハンドが安定していた'), findsOneWidget);
  });

  testWidgets('shows an empty state when the personal memo is unregistered',
      (tester) async {
    final match = MatchHistoryItem(
      matchDate: DateTime(2026, 8, 24),
      opponentName: '西やん',
      scoreText: '6-4',
      isWin: true,
    );

    await showDetail(tester, match);

    expect(find.text('個人メモ'), findsOneWidget);
    expect(find.text('メモはまだありません'), findsOneWidget);
  });

  testWidgets('enters memo editing from the pencil icon', (tester) async {
    await showDetail(tester, _matchWithMemo('保存済みメモ'));

    await tester.tap(find.byTooltip('個人メモを編集'));
    await tester.pump();

    expect(find.byType(MatchMemoField), findsOneWidget);
    expect(find.text('保存済みメモ'), findsOneWidget);
    expect(find.text('キャンセル'), findsOneWidget);
    expect(find.text('保存する'), findsOneWidget);
    expect(find.byTooltip('個人メモを編集'), findsNothing);
  });

  testWidgets('enters memo editing by tapping the memo body', (tester) async {
    await showDetail(tester, _matchWithMemo('保存済みメモ'));

    await tester.tap(find.text('保存済みメモ'));
    await tester.pump();

    expect(find.byType(MatchMemoField), findsOneWidget);
    expect(find.text('保存済みメモ'), findsOneWidget);
  });

  testWidgets('enters memo editing from the unregistered empty state',
      (tester) async {
    await showDetail(tester, _matchWithMemo(null));

    await tester.tap(find.text('メモはまだありません'));
    await tester.pump();

    expect(find.byType(MatchMemoField), findsOneWidget);
    final field = tester.widget<TextField>(find.byType(TextField));
    expect(field.controller!.text, isEmpty);
  });

  testWidgets('cancels editing and restores the saved memo', (tester) async {
    await showDetail(tester, _matchWithMemo('保存済みメモ'));
    await tester.tap(find.text('保存済みメモ'));
    await tester.pump();
    await tester.enterText(find.byType(TextField), '編集中のメモ');

    await tester.tap(find.text('キャンセル'));
    await tester.pump();

    expect(find.byType(MatchMemoField), findsNothing);
    expect(find.text('保存済みメモ'), findsOneWidget);
    expect(find.text('編集中のメモ'), findsNothing);
  });

  testWidgets('closes the detail sheet after the memo save succeeds',
      (tester) async {
    String? requestedMemo;
    await showDetail(
      tester,
      _matchWithMemo('保存済みメモ'),
      onSaveMemo: (memo) async {
        requestedMemo = memo;
        return memo.trim();
      },
    );
    await tester.tap(find.text('保存済みメモ'));
    await tester.pump();
    await tester.enterText(find.byType(TextField), ' 更新後のメモ ');

    await tester.tap(find.text('保存する'));
    await tester.pumpAndSettle();

    expect(requestedMemo, ' 更新後のメモ ');
    expect(find.byType(MatchDetailSheet), findsNothing);
    expect(find.text('詳細を開く'), findsOneWidget);
  });

  testWidgets('disables memo actions while one save is in progress',
      (tester) async {
    final response = Completer<String?>();
    var saveCount = 0;
    await showDetail(
      tester,
      _matchWithMemo('保存済みメモ'),
      onSaveMemo: (memo) {
        saveCount++;
        return response.future;
      },
    );
    await tester.tap(find.text('保存済みメモ'));
    await tester.pump();

    await tester.tap(find.text('保存する'));
    await tester.pump();

    final saveButton = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, '保存中...'),
    );
    final cancelButton = tester.widget<OutlinedButton>(
      find.widgetWithText(OutlinedButton, 'キャンセル'),
    );
    expect(saveButton.onPressed, isNull);
    expect(cancelButton.onPressed, isNull);
    expect(saveCount, 1);
    expect(find.byType(MatchDetailSheet), findsOneWidget);

    response.complete('保存済みメモ');
    await tester.pumpAndSettle();

    expect(find.byType(MatchDetailSheet), findsNothing);
  });

  testWidgets('does not dismiss from a barrier tap while saving',
      (tester) async {
    final response = Completer<String?>();
    await showDetail(
      tester,
      _matchWithMemo('保存済みメモ'),
      onSaveMemo: (_) => response.future,
    );
    await tester.tap(find.text('保存済みメモ'));
    await tester.pump();
    await tester.tap(find.text('保存する'));
    await tester.pump();

    await tester.tapAt(const Offset(5, 5));
    await tester.pump();

    expect(find.byType(MatchDetailSheet), findsOneWidget);

    response.complete('保存済みメモ');
    await tester.pumpAndSettle();
    expect(find.byType(MatchDetailSheet), findsNothing);
  });

  testWidgets('does not dismiss from a back action while saving',
      (tester) async {
    final response = Completer<String?>();
    await showDetail(
      tester,
      _matchWithMemo('保存済みメモ'),
      onSaveMemo: (_) => response.future,
    );
    await tester.tap(find.text('保存済みメモ'));
    await tester.pump();
    await tester.tap(find.text('保存する'));
    await tester.pump();

    await tester.binding.handlePopRoute();
    await tester.pump();

    expect(find.byType(MatchDetailSheet), findsOneWidget);

    response.complete('保存済みメモ');
    await tester.pumpAndSettle();
    expect(find.byType(MatchDetailSheet), findsNothing);
  });

  testWidgets('keeps the draft and shows an error after save failure',
      (tester) async {
    var shouldFail = true;
    await showDetail(
      tester,
      _matchWithMemo('保存済みメモ'),
      onSaveMemo: (memo) async {
        if (shouldFail) {
          throw Exception('save failed');
        }
        return memo;
      },
    );
    await tester.tap(find.text('保存済みメモ'));
    await tester.pump();
    await tester.enterText(find.byType(TextField), '消してはいけない入力');

    await tester.tap(find.text('保存する'));
    await tester.pumpAndSettle();

    expect(find.byType(MatchMemoField), findsOneWidget);
    expect(find.text('消してはいけない入力'), findsOneWidget);
    expect(find.text('メモの保存に失敗しました。もう一度お試しください'), findsOneWidget);
    final saveButton = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, '保存する'),
    );
    expect(saveButton.onPressed, isNotNull);

    shouldFail = false;
    await tester.tap(find.text('保存する'));
    await tester.pumpAndSettle();

    expect(find.byType(MatchDetailSheet), findsNothing);
  });
}

MatchHistoryItem _matchWithMemo(String? memo) {
  return MatchHistoryItem(
    matchId: 'match-1',
    matchDate: DateTime(2026, 8, 24),
    opponentName: '西やん',
    scoreText: '6-4',
    isWin: true,
    personalMemo: memo,
  );
}
