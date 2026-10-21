import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import '../constants/app_sizes.dart';
import '../constants/app_strings.dart';
import '../constants/app_text_styles.dart';
import '../models/group_member_match.dart';

/// メンバー視点の試合（日付・対戦相手・スコア・勝敗バッジ）を表示するカード。
class MemberMatchCard extends StatelessWidget {
  final GroupMemberMatch match;

  const MemberMatchCard({super.key, required this.match});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.groupCardPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    match.dateText,
                    style: AppTextStyles.matchCardDate,
                  ),
                ),
                _buildResultBadge(),
              ],
            ),
            const SizedBox(height: AppSizes.groupCardTextSpacing),
            Text(
              AppStrings.memberStatsVersus(match.opponentName),
              style: AppTextStyles.groupCardName,
            ),
            const SizedBox(height: AppSizes.groupCardTextSpacing),
            Text(
              match.scoreText,
              style: AppTextStyles.groupCardMemberCount,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultBadge() {
    final isWin = match.isWin;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.groupDetailBadgeHorizontalPadding,
        vertical: AppSizes.groupDetailBadgeVerticalPadding,
      ),
      decoration: BoxDecoration(
        color: isWin
            ? AppColors.matchWinBackground
            : AppColors.matchLoseBackground,
        borderRadius: BorderRadius.circular(AppSizes.groupDetailBadgeRadius),
      ),
      child: Text(
        isWin
            ? AppStrings.memberStatsBadgeWin
            : AppStrings.memberStatsBadgeLose,
        style: AppTextStyles.matchCardStatus.copyWith(
          color: isWin ? AppColors.matchWin : AppColors.matchLose,
        ),
      ),
    );
  }
}
