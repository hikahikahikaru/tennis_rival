import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import '../constants/app_sizes.dart';
import '../constants/app_strings.dart';
import '../constants/app_text_styles.dart';

class MatchCard extends StatelessWidget {
  final String date;
  final String opponentName;
  final String score;
  final bool isWin;

  const MatchCard({
    super.key,
    required this.date,
    required this.opponentName,
    required this.score,
    required this.isWin,
  });

  @override
  Widget build(BuildContext context) {
    final statusText =
        isWin ? AppStrings.matchCardWin : AppStrings.matchCardLose;
    final statusBackgroundColor =
        isWin ? AppColors.matchWinBackground : AppColors.matchLoseBackground;
    final statusTextColor = isWin ? AppColors.matchWin : AppColors.matchLose;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.matchCardPadding),
        child: Row(
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.calendar_today_outlined,
                  size: AppSizes.matchCardIconSize,
                  color: AppColors.primary,
                ),
                const SizedBox(height: AppSizes.matchDateIconSpacing),
                Text(
                  date,
                  style: AppTextStyles.matchCardDate,
                ),
              ],
            ),
            const SizedBox(width: AppSizes.matchDateIconSpacing),
            Container(
              width: AppSizes.matchDateDividerWidth,
              height: AppSizes.matchDateDividerHeight,
              color: AppColors.cardBorder,
            ),
            const SizedBox(width: AppSizes.matchResultSpacing),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${AppStrings.matchCardVs} $opponentName',
                    style: AppTextStyles.matchCardOpponent,
                  ),
                  const SizedBox(height: AppSizes.matchContentSpacing),
                  Text(
                    score,
                    style: AppTextStyles.matchCardScore,
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSizes.matchCardStatusHorizontalPadding,
                vertical: AppSizes.matchCardStatusVerticalPadding,
              ),
              decoration: BoxDecoration(
                color: statusBackgroundColor,
                borderRadius: BorderRadius.circular(
                  AppSizes.matchCardStatusRadius,
                ),
              ),
              child: Text(
                statusText,
                style: AppTextStyles.matchCardStatus.copyWith(
                  color: statusTextColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
