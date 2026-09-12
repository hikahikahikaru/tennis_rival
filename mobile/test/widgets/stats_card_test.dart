import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/models/user_stats.dart';
import 'package:mobile/widgets/stats_card.dart';

void main() {
  Widget buildSubject() {
    return const MaterialApp(
      home: Scaffold(
        body: StatsCard(
          stats: UserStats(wins: 4, losses: 2),
        ),
      ),
    );
  }

  testWidgets('shows record and win rate', (WidgetTester tester) async {
    await tester.pumpWidget(buildSubject());

    // 本体と同じ文字列生成関数に依存せず、表示仕様そのものを検証する。
    expect(find.text('4勝 2敗'), findsOneWidget);
    expect(find.text('67%'), findsOneWidget);
  });

  testWidgets('shows title', (WidgetTester tester) async {
    await tester.pumpWidget(buildSubject());

    expect(find.text('今月の戦績'), findsOneWidget);
  });

  testWidgets('is display-only without interactive widgets',
      (WidgetTester tester) async {
    await tester.pumpWidget(buildSubject());

    expect(tester.widget<StatsCard>(find.byType(StatsCard)),
        isA<StatelessWidget>());
    expect(
      find.descendant(
        of: find.byType(StatsCard),
        matching: find.byType(GestureDetector),
      ),
      findsNothing,
    );
    expect(
      find.descendant(
        of: find.byType(StatsCard),
        matching: find.byType(InkWell),
      ),
      findsNothing,
    );
    expect(
      find.descendant(
        of: find.byType(StatsCard),
        matching: find.byType(ButtonStyleButton),
      ),
      findsNothing,
    );
  });
}
