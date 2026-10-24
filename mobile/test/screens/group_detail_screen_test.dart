import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/mocks/mock_data.dart';
import 'package:mobile/models/group_detail.dart';
import 'package:mobile/models/group_match_summary.dart';
import 'package:mobile/models/group_member.dart';
import 'package:mobile/screens/group_detail_screen.dart';
import 'package:mobile/screens/group_list_screen.dart';
import 'package:mobile/widgets/group_info_panel.dart';
import 'package:mobile/widgets/group_match_card.dart';
import 'package:mobile/widgets/group_member_card.dart';
import 'package:mobile/widgets/invite_code_box.dart';
import 'package:mobile/widgets/underline_tab_bar.dart';

void main() {
  final detail = GroupDetail(
    id: 'g1',
    name: '週末テニス',
    description: '毎週土曜日に活動します。',
    createdAt: DateTime(2026, 4, 1),
    adminName: 'たけし',
    inviteCode: 'ABC123',
    memberCount: 3,
  );

  Widget wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

  // ListViewは画面外の項目を生成しないため、縦長の表示領域を使う。
  Future<void> useTallViewport(WidgetTester tester) async {
    tester.view.physicalSize = const Size(800, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
  }

  group('GroupMember', () {
    test('winRatePercentage rounds the win rate', () {
      const member = GroupMember(id: 'u', name: 'a', wins: 8, losses: 4);
      expect(member.winRatePercentage, 67);
    });

    test('winRatePercentage is 0 when there are no matches', () {
      const member = GroupMember(id: 'u', name: 'a', wins: 0, losses: 0);
      expect(member.winRatePercentage, 0);
    });
  });

  test('GroupDetail and GroupMatchSummary format dates', () {
    expect(detail.createdDateText, '2026年4月1日');
    final match = GroupMatchSummary(
      id: 'm',
      matchDate: DateTime(2026, 8, 24),
      player1Name: 'a',
      player2Name: 'b',
      winnerName: 'a',
      scoreText: '6-4',
    );
    expect(match.dateText, '2026年8月24日');
  });

  testWidgets('GroupMemberCard shows record and admin badge',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      wrap(
        const GroupMemberCard(
          member: GroupMember(
            id: 'u',
            name: 'たけし',
            wins: 12,
            losses: 8,
            isAdmin: true,
          ),
        ),
      ),
    );

    expect(find.text('たけし'), findsOneWidget);
    expect(find.text('管理者'), findsOneWidget);
    expect(find.text('12勝 8敗（勝率60%）'), findsOneWidget);
  });

  testWidgets('GroupMemberCard hides admin badge for non-admin',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      wrap(
        const GroupMemberCard(
          member: GroupMember(id: 'u', name: '西やん', wins: 1, losses: 1),
        ),
      ),
    );

    expect(find.text('管理者'), findsNothing);
  });

  testWidgets('GroupMatchCard shows match information',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      wrap(
        GroupMatchCard(
          match: GroupMatchSummary(
            id: 'm',
            matchDate: DateTime(2026, 8, 24),
            player1Name: 'たけし',
            player2Name: '西やん',
            winnerName: 'たけし',
            scoreText: '6-4, 6-3',
          ),
        ),
      ),
    );

    expect(find.text('2026年8月24日'), findsOneWidget);
    expect(find.text('たけし vs 西やん'), findsOneWidget);
    expect(find.text('スコア：6-4, 6-3'), findsOneWidget);
    expect(find.text('勝者：たけし'), findsOneWidget);
  });

  testWidgets('InviteCodeBox shows code and calls onCopy',
      (WidgetTester tester) async {
    var copied = 0;
    await tester.pumpWidget(
      wrap(InviteCodeBox(inviteCode: 'ABC123', onCopy: () => copied++)),
    );

    expect(find.text('ABC123'), findsOneWidget);
    await tester.tap(find.text('コピー'));

    expect(copied, 1);
  });

  testWidgets('UnderlineTabBar calls onChanged with tapped index',
      (WidgetTester tester) async {
    int? changed;
    await tester.pumpWidget(
      wrap(
        UnderlineTabBar(
          labels: const ['A', 'B'],
          selectedIndex: 0,
          onChanged: (i) => changed = i,
        ),
      ),
    );

    await tester.tap(find.text('B'));

    expect(changed, 1);
  });

  testWidgets('GroupInfoPanel collapses and expands',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      wrap(GroupInfoPanel(group: detail, onCopyInviteCode: () {})),
    );

    expect(find.text('毎週土曜日に活動します。'), findsOneWidget);
    expect(find.text('作成日：2026年4月1日'), findsOneWidget);
    expect(find.text('管理者：たけし'), findsOneWidget);
    expect(find.byType(InviteCodeBox), findsOneWidget);

    await tester.tap(find.byType(IconButton));
    await tester.pump();

    expect(find.text('週末テニス'), findsOneWidget);
    expect(find.text('毎週土曜日に活動します。'), findsNothing);
    expect(find.byType(InviteCodeBox), findsNothing);

    await tester.tap(find.byType(IconButton));
    await tester.pump();

    expect(find.byType(InviteCodeBox), findsOneWidget);
  });

  group('GroupDetailScreen', () {
    testWidgets('shows members tab by default', (WidgetTester tester) async {
      await useTallViewport(tester);
      await tester.pumpWidget(const MaterialApp(home: GroupDetailScreen()));

      expect(find.text('メンバー一覧'), findsOneWidget);
      expect(find.byType(GroupMemberCard), findsNWidgets(3));
      expect(find.byType(GroupMatchCard), findsNothing);
    });

    testWidgets('switches to matches tab', (WidgetTester tester) async {
      await useTallViewport(tester);
      await tester.pumpWidget(const MaterialApp(home: GroupDetailScreen()));

      await tester.tap(find.widgetWithText(InkWell, '戦績'));
      await tester.pump();

      expect(find.text('グループ内の試合'), findsOneWidget);
      expect(find.byType(GroupMatchCard), findsNWidgets(2));
      expect(find.byType(GroupMemberCard), findsNothing);
    });

    testWidgets('shows empty messages', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: GroupDetailScreen(
              group: detail, members: const [], matches: const []),
        ),
      );
      expect(find.text('メンバーはまだいません'), findsOneWidget);

      await tester.tap(find.widgetWithText(InkWell, '戦績'));
      await tester.pump();
      expect(find.text('グループ内の試合はまだありません'), findsOneWidget);
    });

    testWidgets('copies invite code to clipboard', (WidgetTester tester) async {
      String? copiedText;
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (call) async {
          if (call.method == 'Clipboard.setData') {
            copiedText = (call.arguments as Map)['text'] as String?;
          }
          return null;
        },
      );
      addTearDown(
        () => tester.binding.defaultBinaryMessenger
            .setMockMethodCallHandler(SystemChannels.platform, null),
      );

      await tester.pumpWidget(
        MaterialApp(home: GroupDetailScreen(group: detail)),
      );
      await tester.tap(find.text('コピー'));
      await tester.pump();

      expect(copiedText, 'ABC123');
      expect(find.text('招待コードをコピーしました'), findsOneWidget);
    });
  });

  testWidgets('GroupListScreen opens detail screen from group card',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: GroupListScreen(groups: MockData.groups)),
    );

    await tester.tap(find.text('週末テニス'));
    await tester.pumpAndSettle();

    expect(find.byType(GroupDetailScreen), findsOneWidget);
  });

  testWidgets('selecting group A passes its ID and shows only group A data',
      (WidgetTester tester) async {
    await useTallViewport(tester);
    await tester.pumpWidget(
      const MaterialApp(home: GroupListScreen(groups: MockData.groups)),
    );

    await tester.tap(find.text('週末テニス'));
    await tester.pumpAndSettle();

    final screen = tester.widget<GroupDetailScreen>(
      find.byType(GroupDetailScreen),
    );
    final panel = tester.widget<GroupInfoPanel>(find.byType(GroupInfoPanel));
    expect(screen.groupId, 'group-1');
    expect(panel.group.id, 'group-1');
    expect(find.text('毎週土曜日に活動するテニス仲間です。'), findsOneWidget);
    expect(find.text('さくら'), findsNothing);
  });

  testWidgets('selecting group B passes its ID and shows only group B data',
      (WidgetTester tester) async {
    await useTallViewport(tester);
    await tester.pumpWidget(
      const MaterialApp(home: GroupListScreen(groups: MockData.groups)),
    );

    await tester.tap(find.text('テニスサークル'));
    await tester.pumpAndSettle();

    final screen = tester.widget<GroupDetailScreen>(
      find.byType(GroupDetailScreen),
    );
    final panel = tester.widget<GroupInfoPanel>(find.byType(GroupInfoPanel));
    expect(screen.groupId, 'group-2');
    expect(panel.group.id, 'group-2');
    expect(find.text('平日の夜を中心に活動するテニスサークルです。'), findsOneWidget);
    expect(find.text('さくら'), findsOneWidget);
    expect(find.text('ピンちゃん'), findsNothing);

    await tester.tap(find.widgetWithText(InkWell, '戦績'));
    await tester.pump();
    expect(find.text('西やん vs さくら'), findsOneWidget);
    expect(find.text('たけし vs 西やん'), findsNothing);
  });

  testWidgets('unknown group ID shows an error without fallback data',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: GroupDetailScreen(groupId: 'unknown-group')),
    );

    expect(find.text('グループ情報が見つかりません'), findsOneWidget);
    expect(find.text(MockData.groups.first.name), findsNothing);
    expect(find.byType(GroupInfoPanel), findsNothing);
  });
}
