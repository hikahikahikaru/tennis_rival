import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/models/group_summary.dart';
import 'package:mobile/screens/group_list_screen.dart';
import 'package:mobile/widgets/group_card.dart';

void main() {
  Widget buildSubject({List<GroupSummary>? groups}) {
    return MaterialApp(
      home: groups == null
          ? const GroupListScreen()
          : GroupListScreen(groups: groups),
    );
  }

  testWidgets('shows mock groups and action buttons',
      (WidgetTester tester) async {
    await tester.pumpWidget(buildSubject());

    expect(find.text('所属グループ'), findsOneWidget);
    expect(find.text('週末テニス'), findsOneWidget);
    expect(find.text('テニスサークル'), findsOneWidget);
    expect(find.text('グループ作成'), findsOneWidget);
    expect(find.text('グループに参加'), findsOneWidget);
  });

  testWidgets('shows empty message when there are no groups',
      (WidgetTester tester) async {
    await tester.pumpWidget(buildSubject(groups: const []));

    expect(find.text('所属しているグループはまだありません'), findsOneWidget);
    expect(find.byType(GroupCard), findsNothing);
  });

  testWidgets('keeps action buttons visible with many groups',
      (WidgetTester tester) async {
    final groups = List.generate(
      30,
      (i) => GroupSummary(id: 'g$i', name: 'グループ$i', memberCount: i + 1),
    );
    await tester.pumpWidget(buildSubject(groups: groups));

    expect(find.text('グループ作成'), findsOneWidget);
    expect(find.text('グループに参加'), findsOneWidget);
  });

  testWidgets('shows message when create button is tapped',
      (WidgetTester tester) async {
    await tester.pumpWidget(buildSubject());

    await tester.tap(find.text('グループ作成'));
    await tester.pump();

    expect(find.text('この機能は未実装です'), findsOneWidget);
  });
}
