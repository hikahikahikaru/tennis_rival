import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/constants/app_theme.dart';
import 'package:mobile/screens/match_history_screen.dart';
import 'package:mobile/widgets/match_calendar.dart';
import 'package:mobile/widgets/match_card.dart';
import 'package:mobile/widgets/stats_card.dart';

void main() {
  Future<void> pumpScreen(
    WidgetTester tester, {
    Size? screenSize,
  }) async {
    if (screenSize != null) {
      tester.view.physicalSize = screenSize;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
    }

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: MatchHistoryScreen(initialMonth: DateTime(2026, 8)),
      ),
    );
  }

  testWidgets('shows the summary, calendar, and multiple match cards',
      (tester) async {
    await pumpScreen(tester);

    expect(find.text('戦績'), findsOneWidget);
    expect(find.byType(StatsCard), findsOneWidget);
    expect(find.byType(MatchCalendar), findsOneWidget);
    expect(find.text('月間戦績'), findsOneWidget);
    expect(find.text('今月の戦績'), findsNothing);
    expect(find.text('試合一覧'), findsOneWidget);
    expect(find.byType(MatchCard), findsNWidgets(2));
    expect(find.text('2勝 2敗'), findsOneWidget);
    expect(find.text('50%'), findsOneWidget);
    expect(find.text('vs 西やん'), findsOneWidget);
    expect(find.text('vs ピンちゃん'), findsOneWidget);
  });

  testWidgets('changes the displayed month with calendar controls',
      (tester) async {
    await pumpScreen(tester);

    expect(find.text('2026年8月'), findsOneWidget);
    await tester.tap(find.byTooltip('翌月'));
    await tester.pump();
    expect(find.text('2026年9月'), findsOneWidget);

    await tester.tap(find.byTooltip('前月'));
    await tester.pump();
    expect(find.text('2026年8月'), findsOneWidget);
  });

  testWidgets('updates the selected date without breaking the screen',
      (tester) async {
    await pumpScreen(tester);

    await tester.tap(find.byKey(const ValueKey('match-calendar-day-24')));
    await tester.pump();

    expect(
      find.byKey(const ValueKey('match-calendar-selected-24')),
      findsOneWidget,
    );
    expect(find.byType(MatchCard), findsNWidgets(2));
    expect(tester.takeException(), isNull);
  });

  testWidgets('scrolls without overflow on a small smartphone', (tester) async {
    await pumpScreen(tester, screenSize: const Size(320, 568));

    await tester.drag(
        find.byType(SingleChildScrollView), const Offset(0, -700));
    await tester.pumpAndSettle();

    expect(find.text('vs ピンちゃん'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
