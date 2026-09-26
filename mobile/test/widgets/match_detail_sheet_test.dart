import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/constants/app_theme.dart';
import 'package:mobile/models/match_format.dart';
import 'package:mobile/models/match_history_item.dart';
import 'package:mobile/models/match_set_score.dart';
import 'package:mobile/widgets/match_detail_sheet.dart';

void main() {
  Future<void> showDetail(
    WidgetTester tester,
    MatchHistoryItem match,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () => MatchDetailSheet.show(context, match: match),
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
}
