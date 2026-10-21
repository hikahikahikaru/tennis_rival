import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/models/group_summary.dart';
import 'package:mobile/widgets/group_card.dart';
import 'package:mobile/widgets/secondary_button.dart';

void main() {
  const group = GroupSummary(id: 'g1', name: '週末テニス', memberCount: 3);

  testWidgets('GroupCard shows group name and member count',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: GroupCard(group: group))),
    );

    expect(find.text('週末テニス'), findsOneWidget);
    expect(find.text('メンバー 3人'), findsOneWidget);
  });

  testWidgets('GroupCard calls onTap when tapped', (WidgetTester tester) async {
    var tapped = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: GroupCard(group: group, onTap: () => tapped++)),
      ),
    );

    await tester.tap(find.byType(GroupCard));

    expect(tapped, 1);
  });

  testWidgets('SecondaryButton shows label and calls onPressed',
      (WidgetTester tester) async {
    var pressed = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SecondaryButton(label: '閉じる', onPressed: () => pressed++),
        ),
      ),
    );

    expect(find.text('閉じる'), findsOneWidget);
    await tester.tap(find.byType(OutlinedButton));

    expect(pressed, 1);
  });
}
