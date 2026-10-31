import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/models/group_member.dart';
import 'package:mobile/models/group_member_match.dart';
import 'package:mobile/models/match_sort_condition.dart';
import 'package:mobile/screens/group_detail_screen.dart';
import 'package:mobile/screens/group_member_stats_screen.dart';
import 'package:mobile/widgets/group_member_card.dart';
import 'package:mobile/widgets/match_card.dart';
import 'package:mobile/widgets/member_stats_summary_card.dart';

void main() {
  const member = GroupMember(id: 'u2', name: '西やん', wins: 10, losses: 10);

  final matches = [
    GroupMemberMatch(
      id: 'a',
      matchDate: DateTime(2026, 8, 24),
      opponentName: 'たけし',
      scoreText: '4-6, 3-6',
      isWin: false,
    ),
    GroupMemberMatch(
      id: 'b',
      matchDate: DateTime(2026, 8, 18),
      opponentName: 'ピンちゃん',
      scoreText: '6-4, 7-5',
      isWin: true,
    ),
  ];

  Widget wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

  test('GroupMember.totalMatches sums wins and losses', () {
    expect(member.totalMatches, 20);
  });

  test('GroupMemberMatch formats date', () {
    expect(matches.first.dateText, '2026年8月24日');
  });

  test('MatchSortCondition filters by result', () {
    List<String> ids(MatchSortCondition c) => c
        .apply(matches, dateOf: (m) => m.matchDate, isWinOf: (m) => m.isWin)
        .map((m) => m.id)
        .toList();

    expect(ids(const MatchSortCondition()), ['a', 'b']);
    expect(
      ids(const MatchSortCondition(result: MatchResultFilter.wins)),
      ['b'],
    );
    expect(
      ids(const MatchSortCondition(result: MatchResultFilter.losses)),
      ['a'],
    );
  });

  test('MatchSortCondition sorts by date and filters by period', () {
    List<String> ids(MatchSortCondition c) => c
        .apply(matches, dateOf: (m) => m.matchDate, isWinOf: (m) => m.isWin)
        .map((m) => m.id)
        .toList();

    expect(
      ids(const MatchSortCondition(order: MatchDateOrder.oldestFirst)),
      ['b', 'a'],
    );
    expect(
      ids(
        MatchSortCondition(
          period: DateTimeRange(
            start: DateTime(2026, 8, 18),
            end: DateTime(2026, 8, 20),
          ),
        ),
      ),
      ['b'],
    );
  });

  testWidgets('MemberStatsSummaryCard shows record', (tester) async {
    await tester.pumpWidget(
      wrap(const MemberStatsSummaryCard(member: member, groupName: '週末テニス')),
    );

    expect(find.text('西やん'), findsOneWidget);
    expect(find.text('週末テニスでの対戦成績'), findsOneWidget);
    expect(find.text('20試合'), findsOneWidget);
    expect(find.text('10勝'), findsOneWidget);
    expect(find.text('10敗'), findsOneWidget);
    expect(find.text('50%'), findsOneWidget);
  });

  testWidgets('GroupMemberCard calls onTap', (tester) async {
    var tapped = 0;
    await tester.pumpWidget(
      wrap(GroupMemberCard(member: member, onTap: () => tapped++)),
    );

    await tester.tap(find.byType(GroupMemberCard));

    expect(tapped, 1);
  });

  group('GroupMemberStatsScreen', () {
    setUp(() {
      final binding = TestWidgetsFlutterBinding.ensureInitialized();
      binding.platformDispatcher.views.first
        ..physicalSize = const Size(800, 2400)
        ..devicePixelRatio = 1.0;
      addTearDown(binding.platformDispatcher.views.first.resetPhysicalSize);
    });

    Widget buildSubject({List<GroupMemberMatch>? list}) => MaterialApp(
          home: GroupMemberStatsScreen(
            member: member,
            groupName: '週末テニス',
            matches: list ?? matches,
          ),
        );

    testWidgets('shows title and all matches by default', (tester) async {
      await tester.pumpWidget(buildSubject());

      expect(find.text('西やんの戦績'), findsOneWidget);
      expect(find.byType(MatchCard), findsNWidgets(2));
      expect(find.text('全2試合'), findsOneWidget);
    });

    testWidgets('filters wins and losses by chip', (tester) async {
      await tester.pumpWidget(buildSubject());

      await tester.tap(find.widgetWithText(ChoiceChip, '勝った試合'));
      await tester.pump();
      expect(find.byType(MatchCard), findsOneWidget);
      expect(find.text('vs ピンちゃん'), findsOneWidget);
      expect(find.text('全1試合'), findsOneWidget);

      await tester.tap(find.widgetWithText(ChoiceChip, '負けた試合'));
      await tester.pump();
      expect(find.byType(MatchCard), findsOneWidget);
      expect(find.text('vs たけし'), findsOneWidget);
    });

    testWidgets('sorts by date order', (tester) async {
      await tester.pumpWidget(buildSubject());

      await tester.tap(find.widgetWithText(ChoiceChip, '古い順'));
      await tester.pump();

      final first = tester.getTopLeft(find.text('vs ピンちゃん'));
      final second = tester.getTopLeft(find.text('vs たけし'));
      expect(first.dy, lessThan(second.dy));
    });

    testWidgets('shows empty message when no matches', (tester) async {
      await tester.pumpWidget(buildSubject(list: const []));

      expect(find.text('該当する試合はありません'), findsOneWidget);
      expect(find.text('全0試合'), findsOneWidget);
    });
  });

  testWidgets('GroupDetailScreen opens member stats from member card',
      (tester) async {
    tester.view.physicalSize = const Size(800, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const MaterialApp(home: GroupDetailScreen()));

    await tester.tap(find.text('西やん'));
    await tester.pumpAndSettle();

    expect(find.byType(GroupMemberStatsScreen), findsOneWidget);
    expect(find.text('西やんの戦績'), findsOneWidget);
  });
}
