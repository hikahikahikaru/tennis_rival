import 'package:flutter/material.dart';

import '../constants/app_sizes.dart';
import '../constants/app_strings.dart';
import '../constants/app_text_styles.dart';
import '../mocks/mock_data.dart';
import '../models/group_member.dart';
import '../models/group_member_match.dart';
import '../models/member_match_filter.dart';
import '../widgets/member_match_card.dart';
import '../widgets/member_stats_summary_card.dart';
import '../widgets/underline_tab_bar.dart';

/// グループメンバーの戦績画面。DB連携は別issueのため、現在はモックデータを表示する。
class GroupMemberStatsScreen extends StatefulWidget {
  final GroupMember member;
  final String? groupName;
  final List<GroupMemberMatch>? matches;

  const GroupMemberStatsScreen({
    super.key,
    required this.member,
    this.groupName,
    this.matches,
  });

  @override
  State<GroupMemberStatsScreen> createState() => _GroupMemberStatsScreenState();
}

class _GroupMemberStatsScreenState extends State<GroupMemberStatsScreen> {
  var _selectedFilter = MemberMatchFilter.all;

  List<GroupMemberMatch> get _filteredMatches {
    final matches = widget.matches ?? MockData.memberMatches;
    return matches.where(_selectedFilter.includes).toList();
  }

  @override
  Widget build(BuildContext context) {
    final matches = _filteredMatches;

    return Scaffold(
      appBar: AppBar(
        title: Text(AppStrings.memberStatsTitle(widget.member.name)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSizes.screenPadding),
          children: [
            MemberStatsSummaryCard(
              member: widget.member,
              groupName: widget.groupName ?? MockData.groupDetail.name,
            ),
            const SizedBox(height: AppSizes.spacingLarge),
            UnderlineTabBar(
              labels: MemberMatchFilter.values.map((tab) => tab.label).toList(),
              selectedIndex: _selectedFilter.index,
              onChanged: (index) => setState(
                () => _selectedFilter = MemberMatchFilter.values[index],
              ),
            ),
            const SizedBox(height: AppSizes.spacingLarge),
            Row(
              children: [
                const Expanded(
                  child: Text(
                    AppStrings.memberStatsMatchListTitle,
                    style: AppTextStyles.groupDetailSectionTitle,
                  ),
                ),
                Text(
                  AppStrings.memberStatsSectionCount(matches.length),
                  style: AppTextStyles.groupDetailSectionCount,
                ),
              ],
            ),
            const SizedBox(height: AppSizes.spacingMedium),
            if (matches.isEmpty)
              const Center(child: Text(AppStrings.memberStatsMatchListEmpty)),
            for (final match in matches) ...[
              MemberMatchCard(match: match),
              const SizedBox(height: AppSizes.spacingMedium),
            ],
          ],
        ),
      ),
    );
  }
}
