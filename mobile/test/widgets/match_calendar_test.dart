import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/constants/app_theme.dart';
import 'package:mobile/widgets/match_calendar.dart';

void main() {
  Future<void> pumpCalendar(
    WidgetTester tester, {
    DateTime? displayedMonth,
    Iterable<DateTime> matchDates = const [],
    DateTime? selectedDate,
    ValueChanged<DateTime>? onDateSelected,
    ValueChanged<DateTime>? onMonthChanged,
  }) {
    return tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 390,
              child: MatchCalendar(
                displayedMonth: displayedMonth ?? DateTime(2026, 8),
                matchDates: matchDates,
                selectedDate: selectedDate,
                onDateSelected: onDateSelected ?? (_) {},
                onMonthChanged: onMonthChanged ?? (_) {},
              ),
            ),
          ),
        ),
      ),
    );
  }

  testWidgets('shows the specified month and weekdays from Sunday to Saturday',
      (tester) async {
    await pumpCalendar(tester);

    expect(find.text('2026年8月'), findsOneWidget);
    const weekdays = ['日', '月', '火', '水', '木', '金', '土'];
    final positions = weekdays
        .map((weekday) => tester.getCenter(find.text(weekday)).dx)
        .toList();
    expect(positions, orderedEquals([...positions]..sort()));
  });

  testWidgets('lays out only target month dates with the first weekday offset',
      (tester) async {
    await pumpCalendar(tester);

    expect(find.text('1'), findsOneWidget);
    expect(find.text('31'), findsOneWidget);
    expect(find.text('32'), findsNothing);

    // 2026年8月1日は土曜なので、翌日の2日は次の行の日曜に配置される。
    final first =
        tester.getCenter(find.byKey(const ValueKey('match-calendar-day-1')));
    final second =
        tester.getCenter(find.byKey(const ValueKey('match-calendar-day-2')));
    expect(first.dx, greaterThan(second.dx));
    expect(second.dy, greaterThan(first.dy));
  });

  testWidgets('shows match dots and selected styling by calendar date',
      (tester) async {
    await pumpCalendar(
      tester,
      matchDates: [
        DateTime(2026, 8, 16, 23, 59),
        DateTime(2026, 8, 24, 8),
      ],
      selectedDate: DateTime(2026, 8, 16, 12),
    );

    expect(find.byKey(const ValueKey('match-calendar-dot-16')), findsOneWidget);
    expect(find.byKey(const ValueKey('match-calendar-dot-24')), findsOneWidget);
    expect(
      find.byKey(const ValueKey('match-calendar-selected-16')),
      findsOneWidget,
    );
  });

  testWidgets('notifies the parent when a date is tapped', (tester) async {
    DateTime? selected;
    await pumpCalendar(tester, onDateSelected: (date) => selected = date);

    await tester.tap(find.byKey(const ValueKey('match-calendar-day-24')));

    expect(selected, DateTime(2026, 8, 24));
  });

  testWidgets('notifies the previous and next month', (tester) async {
    final changedMonths = <DateTime>[];
    await pumpCalendar(
      tester,
      onMonthChanged: changedMonths.add,
    );

    await tester.tap(find.byTooltip('前月'));
    await tester.tap(find.byTooltip('翌月'));

    expect(changedMonths, [DateTime(2026, 7), DateTime(2026, 9)]);
  });

  testWidgets('moves from December to January of the next year',
      (tester) async {
    DateTime? changedMonth;
    await pumpCalendar(
      tester,
      displayedMonth: DateTime(2026, 12),
      onMonthChanged: (month) => changedMonth = month,
    );

    await tester.tap(find.byTooltip('翌月'));

    expect(changedMonth, DateTime(2027, 1));
  });

  testWidgets('moves from January to December of the previous year',
      (tester) async {
    DateTime? changedMonth;
    await pumpCalendar(
      tester,
      displayedMonth: DateTime(2026, 1),
      onMonthChanged: (month) => changedMonth = month,
    );

    await tester.tap(find.byTooltip('前月'));

    expect(changedMonth, DateTime(2025, 12));
  });

  testWidgets('renders normally without a selected date', (tester) async {
    await pumpCalendar(tester, selectedDate: null);

    expect(find.text('2026年8月'), findsOneWidget);
    expect(
        find.byKey(const ValueKey('match-calendar-selected-16')), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
