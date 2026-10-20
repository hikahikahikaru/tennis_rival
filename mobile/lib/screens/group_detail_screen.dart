import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../constants/app_sizes.dart';
import '../constants/app_strings.dart';
import '../constants/app_text_styles.dart';
import '../mocks/mock_data.dart';
import '../models/group_detail.dart';
import '../models/group_detail_tab.dart';
import '../models/group_match_summary.dart';
import '../models/group_member.dart';
import '../widgets/group_info_panel.dart';
import '../widgets/group_match_card.dart';
import '../widgets/group_member_card.dart';
import '../widgets/underline_tab_bar.dart';
import 'group_member_stats_screen.dart';

/// グループ詳細画面。DB連携は別issueのため、現在はモックデータを表示する。
class GroupDetailScreen extends StatefulWidget {
  final GroupDetail? group;
  final List<GroupMember>? members;
  final List<GroupMatchSummary>? matches;

  const GroupDetailScreen({
    super.key,
    this.group,
    this.members,
    this.matches,
  });

  @override
  State<GroupDetailScreen> createState() => _GroupDetailScreenState();
}

class _GroupDetailScreenState extends State<GroupDetailScreen> {
  var _selectedTab = GroupDetailTab.members;

  GroupDetail get _group => widget.group ?? MockData.groupDetail;
  List<GroupMember> get _members => widget.members ?? MockData.groupMembers;
  List<GroupMatchSummary> get _matches =>
      widget.matches ?? MockData.groupMatches;

  Future<void> _copyInviteCode() async {
    final messenger = ScaffoldMessenger.of(context);
    await Clipboard.setData(ClipboardData(text: _group.inviteCode));
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      const SnackBar(content: Text(AppStrings.groupInviteCodeCopied)),
    );
  }

  void _openMemberStats(GroupMember member) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => GroupMemberStatsScreen(
          member: member,
          groupName: _group.name,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.groupDetailTitle),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSizes.screenPadding),
          children: [
            GroupInfoPanel(
              group: _group,
              onCopyInviteCode: _copyInviteCode,
            ),
            const SizedBox(height: AppSizes.spacingLarge),
            UnderlineTabBar(
              labels: GroupDetailTab.values.map((tab) => tab.label).toList(),
              selectedIndex: _selectedTab.index,
              onChanged: (index) =>
                  setState(() => _selectedTab = GroupDetailTab.values[index]),
            ),
            const SizedBox(height: AppSizes.spacingLarge),
            ..._buildTabContent(),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildTabContent() {
    return switch (_selectedTab) {
      GroupDetailTab.members => _buildSection(
          title: AppStrings.groupMemberListTitle,
          countText: AppStrings.groupMemberSectionCount(_members.length),
          emptyMessage: AppStrings.groupMemberListEmpty,
          cards: _members
              .map(
                (m) => GroupMemberCard(
                  member: m,
                  onTap: () => _openMemberStats(m),
                ),
              )
              .toList(),
        ),
      GroupDetailTab.matches => _buildSection(
          title: AppStrings.groupMatchListTitle,
          countText: AppStrings.groupMatchSectionCount(_matches.length),
          emptyMessage: AppStrings.groupMatchListEmpty,
          cards: _matches.map((m) => GroupMatchCard(match: m)).toList(),
        ),
    };
  }

  List<Widget> _buildSection({
    required String title,
    required String countText,
    required String emptyMessage,
    required List<Widget> cards,
  }) {
    return [
      Row(
        children: [
          Expanded(
            child: Text(title, style: AppTextStyles.groupDetailSectionTitle),
          ),
          Text(
            countText,
            style: AppTextStyles.groupDetailSectionCount,
          ),
        ],
      ),
      const SizedBox(height: AppSizes.spacingMedium),
      if (cards.isEmpty) Center(child: Text(emptyMessage)),
      for (final card in cards) ...[
        card,
        const SizedBox(height: AppSizes.spacingMedium),
      ],
    ];
  }
}
