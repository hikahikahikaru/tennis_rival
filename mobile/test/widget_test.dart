import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/main.dart';
import 'package:mobile/screens/match_entry_screen.dart';

void main() {
  Future<void> pumpHome(
    WidgetTester tester, {
    Size? screenSize,
  }) async {
    if (screenSize != null) {
      tester.view.physicalSize = screenSize;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
    }

    await tester.pumpWidget(const MyApp());
  }

  testWidgets(
    'shows greeting, sample stats, pending count, and recent matches',
    (WidgetTester tester) async {
      await pumpHome(tester);

      // 本体の文字列生成関数に依存せず、画面仕様として見える文言を検証する。
      expect(find.text('Tennis Rival'), findsOneWidget);
      expect(find.text('こんにちは、たけしさん'), findsOneWidget);
      expect(find.text('4勝 2敗'), findsOneWidget);
      expect(find.text('67%'), findsOneWidget);
      expect(find.text('確認待ちの試合'), findsOneWidget);
      expect(find.text('1件'), findsOneWidget);
      expect(find.text('最近の試合'), findsOneWidget);
      expect(find.text('8月24日'), findsOneWidget);
      expect(find.text('vs 西やん'), findsOneWidget);
      expect(find.text('6-4, 6-3'), findsOneWidget);
      expect(find.text('8月18日'), findsOneWidget);
      expect(find.text('vs ピンちゃん'), findsOneWidget);
      expect(find.text('4-6, 7-5, 10-8'), findsOneWidget);
    },
  );

  testWidgets('opens match entry screen from record button',
      (WidgetTester tester) async {
    await pumpHome(tester);

    await tester.tap(find.text('試合結果を記録'));
    await tester.pumpAndSettle();

    expect(find.byType(MatchEntryScreen), findsOneWidget);
  });

  testWidgets('opens match entry screen from entry bottom navigation item',
      (WidgetTester tester) async {
    await pumpHome(tester);

    await tester.tap(find.text('登録'));
    await tester.pumpAndSettle();

    expect(find.byType(MatchEntryScreen), findsOneWidget);
  });

  testWidgets('shows SnackBar guidance for unimplemented home actions',
      (WidgetTester tester) async {
    await pumpHome(tester);

    await tester.tap(find.byTooltip('通知'));
    await tester.pump();
    expect(find.text('通知機能は未実装です'), findsOneWidget);

    await tester.ensureVisible(find.text('確認する'));
    await tester.tap(find.text('確認する'));
    await tester.pump();
    expect(find.text('確認待ち画面は未実装です'), findsOneWidget);

    await tester.tap(find.text('戦績'));
    await tester.pump();
    expect(find.text('この機能は未実装です'), findsOneWidget);
  });

  testWidgets('does not overflow at 320px width while scrolling',
      (WidgetTester tester) async {
    await pumpHome(tester, screenSize: const Size(320, 700));

    expect(tester.takeException(), isNull);
    await tester.drag(
        find.byType(SingleChildScrollView), const Offset(0, -600));
    await tester.pump();
    expect(tester.takeException(), isNull);
  });

  testWidgets('does not overflow at 390px width while scrolling',
      (WidgetTester tester) async {
    await pumpHome(tester, screenSize: const Size(390, 700));

    expect(tester.takeException(), isNull);
    await tester.drag(
        find.byType(SingleChildScrollView), const Offset(0, -600));
    await tester.pump();
    expect(tester.takeException(), isNull);
  });
}
