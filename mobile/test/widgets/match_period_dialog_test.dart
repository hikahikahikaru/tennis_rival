import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/models/match_sort_condition.dart';
import 'package:mobile/widgets/match_period_dialog.dart';
import 'package:mobile/widgets/match_sort_bar.dart';

void main() {
  test('MatchPeriodDialog.parse accepts only real yyyyMMdd dates', () {
    expect(MatchPeriodDialog.parse('20260824'), DateTime(2026, 8, 24));
    expect(MatchPeriodDialog.parse('20260230'), isNull);
    expect(MatchPeriodDialog.parse('2026082'), isNull);
  });

  Future<void> openDialog(
    WidgetTester tester,
    ValueNotifier<MatchSortCondition> condition,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ValueListenableBuilder(
            valueListenable: condition,
            builder: (_, value, __) => MatchSortBar(
              condition: value,
              onChanged: (v) => condition.value = v,
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('期間を指定').first);
    await tester.pumpAndSettle();
  }

  testWidgets('applies typed period and can clear it', (tester) async {
    final condition = ValueNotifier(const MatchSortCondition());
    await openDialog(tester, condition);

    await tester.enterText(find.byType(TextField).at(0), '20160101');
    await tester.enterText(find.byType(TextField).at(1), '20161231');
    await tester.tap(find.text('適用'));
    await tester.pumpAndSettle();

    expect(condition.value.from, DateTime(2016, 1, 1));
    expect(condition.value.to, DateTime(2016, 12, 31));

    await tester.tap(find.byIcon(Icons.close));
    await tester.pump();
    expect(condition.value.from, isNull);
    expect(condition.value.to, isNull);
  });

  testWidgets('shows errors for invalid or reversed input', (tester) async {
    final condition = ValueNotifier(const MatchSortCondition());
    await openDialog(tester, condition);

    await tester.enterText(find.byType(TextField).at(0), '2026');
    await tester.tap(find.text('適用'));
    await tester.pump();
    expect(find.text('日付をyyyyMMddの8桁で入力してください'), findsOneWidget);

    await tester.enterText(find.byType(TextField).at(0), '20260301');
    await tester.enterText(find.byType(TextField).at(1), '20260201');
    await tester.tap(find.text('適用'));
    await tester.pump();
    expect(find.text('終了日は開始日以降にしてください'), findsOneWidget);
  });

  testWidgets('calendar button opens at the typed date', (tester) async {
    final condition = ValueNotifier(const MatchSortCondition());
    await openDialog(tester, condition);

    await tester.enterText(find.byType(TextField).at(0), '20160105');
    await tester.tap(find.byIcon(Icons.calendar_month).first);
    await tester.pumpAndSettle();

    expect(find.text('January 2016'), findsOneWidget);
  });
}
