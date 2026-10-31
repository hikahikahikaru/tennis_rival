import 'package:flutter/material.dart';

import '../constants/app_sizes.dart';
import '../constants/app_strings.dart';
import '../constants/app_text_styles.dart';
import '../mocks/mock_data.dart';
import '../models/group_member.dart';
import '../models/group_member_match.dart';
import '../models/match_sort_condition.dart';
import '../widgets/match_card.dart';
import '../widgets/match_sort_bar.dart';
import '../widgets/member_stats_summary_card.dart';

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
  var _condition = const MatchSortCondition();

  List<GroupMemberMatch> get _filteredMatches {
    final matches = widget.matches ?? MockData.memberMatches;
    return _condition.apply(
      matches,
      dateOf: (m) => m.matchDate,
      isWinOf: (m) => m.isWin,
    );
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
            MatchSortBar(
              condition: _condition,
              onChanged: (value) => setState(() => _condition = value),
            ),
            const SizedBox(height: AppSizes.spacingMedium),
            if (matches.isEmpty)
              const Center(child: Text(AppStrings.memberStatsMatchListEmpty)),
            for (final match in matches) ...[
              MatchCard(
                date: match.dateText,
                opponentName: match.opponentName,
                score: match.scoreText,
                isWin: match.isWin,
              ),
              const SizedBox(height: AppSizes.spacingMedium),
            ],
          ],
        ),
      ),
    );
  }
}
