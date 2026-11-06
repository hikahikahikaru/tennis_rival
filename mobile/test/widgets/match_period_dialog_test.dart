import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/models/match_sort_condition.dart';
import 'package:mobile/widgets/match_period_dialog.dart';
import 'package:mobile/widgets/match_sort_bar.dart';

void main() {
  test('MatchPeriodDialog.parse accepts only real yyyyMMdd dates', () {
    expect(MatchPeriodDialog.parse('20260824'), DateTime(2026, 8, 24));
    expect(MatchPeriodDialog.parse('20260230'), isNull);
    expect(MatchPeriodDialog.parse('2026082'), isNull);
    expect(MatchPeriodDialog.parse('abcd0824'), isNull);
    expect(MatchPeriodDialog.parse('-0010101'), isNull);
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

  testWidgets('range errors wrap without truncation on a narrow screen',
      (tester) async {
    tester.view.physicalSize = const Size(320, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final condition = ValueNotifier(const MatchSortCondition());
    await openDialog(tester, condition);

    await tester.enterText(find.byType(TextField).first, '19891231');
    await tester.tap(find.text('適用'));
    await tester.pumpAndSettle();

    final lastYear = DateTime.now().year + 1;
    final error = find.text('19900101から${lastYear}1231の範囲で入力してください');
    expect(error, findsOneWidget);
    final paragraph = tester.renderObject<RenderParagraph>(error);
    expect(
        paragraph
            .getBoxesForSelection(TextSelection(
              baseOffset: 0,
              extentOffset: '19900101から${lastYear}1231の範囲で入力してください'.length,
            ))
            .length,
        greaterThan(1));
    expect(paragraph.didExceedMaxLines, isFalse);
    expect(tester.takeException(), isNull);
  });

  testWidgets('accepts both date boundaries and rejects out-of-range dates',
      (tester) async {
    final condition = ValueNotifier(const MatchSortCondition());
    await openDialog(tester, condition);
    final lastYear = DateTime.now().year + 1;

    await tester.enterText(find.byType(TextField).at(0), '19891231');
    await tester.enterText(find.byType(TextField).at(1), '${lastYear + 1}0101');
    await tester.tap(find.text('適用'));
    await tester.pump();
    expect(
      find.text('19900101から${lastYear}1231の範囲で入力してください'),
      findsNWidgets(2),
    );
    expect(condition.value.from, isNull);
    expect(condition.value.to, isNull);

    await tester.enterText(find.byType(TextField).at(0), '19900101');
    await tester.enterText(find.byType(TextField).at(1), '${lastYear}1231');
    await tester.tap(find.text('適用'));
    await tester.pumpAndSettle();
    expect(condition.value.from, DateTime(1990));
    expect(condition.value.to, DateTime(lastYear, 12, 31));
  });

  testWidgets('calendar falls back to today for invalid or out-of-range input',
      (tester) async {
    final condition = ValueNotifier(const MatchSortCondition());
    await openDialog(tester, condition);
    final lastYear = DateTime.now().year + 1;

    for (final input in ['19891231', '${lastYear + 1}0101', '20260230', '']) {
      await tester.enterText(find.byType(TextField).first, input);
      await tester.tap(find.byIcon(Icons.calendar_month).first);
      await tester.pumpAndSettle();
      final picker =
          tester.widget<DatePickerDialog>(find.byType(DatePickerDialog));
      expect(DateUtils.isSameDay(picker.initialDate, DateTime.now()), isTrue);
      expect(tester.takeException(), isNull);
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
    }
  });
}
