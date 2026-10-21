import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import '../constants/app_sizes.dart';
import '../constants/app_strings.dart';
import '../constants/app_text_styles.dart';
import '../models/group_member.dart';

/// メンバーのグループ内戦績（試合数・勝ち・負け・勝率）を表示するサマリーカード。
class MemberStatsSummaryCard extends StatelessWidget {
  final GroupMember member;
  final String groupName;

  const MemberStatsSummaryCard({
    super.key,
    required this.member,
    required this.groupName,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.memberStatsCardPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(member.name, style: AppTextStyles.memberStatsName),
            const SizedBox(height: AppSizes.memberStatsLabelSpacing),
            Text(
              AppStrings.memberStatsSubtitle(groupName),
              style: AppTextStyles.memberStatsLabel,
            ),
            const SizedBox(height: AppSizes.memberStatsBlockSpacing),
            _buildDivider(),
            const SizedBox(height: AppSizes.memberStatsBlockSpacing),
            Row(
              children: [
                _buildStat(
                  AppStrings.memberStatsMatchCountLabel,
                  AppStrings.statsCardMatchCount(member.totalMatches),
                  AppTextStyles.memberStatsValue,
                ),
                _buildStat(
                  AppStrings.memberStatsWinsLabel,
                  AppStrings.memberStatsWins(member.wins),
                  AppTextStyles.memberStatsWinValue,
                ),
                _buildStat(
                  AppStrings.memberStatsLossesLabel,
                  AppStrings.memberStatsLosses(member.losses),
                  AppTextStyles.memberStatsLoseValue,
                ),
              ],
            ),
            const SizedBox(height: AppSizes.memberStatsBlockSpacing),
            _buildDivider(),
            const SizedBox(height: AppSizes.memberStatsBlockSpacing),
            Row(
              children: [
                const Expanded(
                  child: Text(
                    AppStrings.memberStatsWinRateLabel,
                    style: AppTextStyles.memberStatsLabel,
                  ),
                ),
                Text(
                  AppStrings.statsCardWinRate(member.winRatePercentage),
                  style: AppTextStyles.memberStatsWinRate,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return const Divider(
      height: AppSizes.memberStatsDividerThickness,
      thickness: AppSizes.memberStatsDividerThickness,
      color: AppColors.cardBorder,
    );
  }

  Widget _buildStat(String label, String value, TextStyle valueStyle) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AppTextStyles.memberStatsLabel),
          const SizedBox(height: AppSizes.memberStatsLabelSpacing),
          Text(value, style: valueStyle),
        ],
      ),
    );
  }
}
