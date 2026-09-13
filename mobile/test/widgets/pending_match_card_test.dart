import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/widgets/pending_match_card.dart';

void main() {
  Widget buildSubject({
    required int pendingCount,
    VoidCallback? onConfirm,
    double? width,
  }) {
    return MaterialApp(
      home: Scaffold(
        body: Center(
          child: SizedBox(
            width: width,
            child: PendingMatchCard(
              pendingCount: pendingCount,
              onConfirm: onConfirm ?? () {},
            ),
          ),
        ),
      ),
    );
  }

  testWidgets('shows pending match content for one item',
      (WidgetTester tester) async {
    await tester.pumpWidget(buildSubject(pendingCount: 1));

    expect(find.text('確認待ちの試合'), findsOneWidget);
    expect(find.text('1件'), findsOneWidget);
    expect(find.text('確認する'), findsOneWidget);
  });

  testWidgets('shows zero count', (WidgetTester tester) async {
    await tester.pumpWidget(buildSubject(pendingCount: 0));

    expect(find.text('0件'), findsOneWidget);
  });

  testWidgets('calls callback once when confirm button is tapped',
      (WidgetTester tester) async {
    var calledCount = 0;

    await tester.pumpWidget(
      buildSubject(
        pendingCount: 1,
        onConfirm: () {
          calledCount++;
        },
      ),
    );

    await tester.tap(find.text('確認する'));
    await tester.pump();

    expect(calledCount, 1);
  });

  testWidgets('does not overflow at 320px width', (WidgetTester tester) async {
    await tester.pumpWidget(
      buildSubject(
        pendingCount: 1,
        width: 320,
      ),
    );

    expect(tester.takeException(), isNull);
  });
}
