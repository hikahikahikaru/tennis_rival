import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import '../constants/app_sizes.dart';
import '../constants/app_strings.dart';
import '../constants/app_text_styles.dart';

/// 今月の勝敗と勝率を表示する読み取り専用のサマリーカード。
class StatsCard extends StatelessWidget {
  final int wins;
  final int losses;
  final int winRatePercentage;

  const StatsCard({
    super.key,
    required this.wins,
    required this.losses,
    required this.winRatePercentage,
  });

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        border: Border.all(color: AppColors.cardBorder),
        borderRadius: BorderRadius.circular(AppSizes.cardRadius),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.statsCardPadding),
        child: Row(
          children: [
            _buildIcon(),
            const SizedBox(width: AppSizes.statsCardContentSpacing),
            Expanded(child: _buildRecord()),
            const SizedBox(width: AppSizes.statsCardContentSpacing),
            Flexible(child: _buildWinRate()),
          ],
        ),
      ),
    );
  }

  Widget _buildIcon() {
    return Container(
      width: AppSizes.statsCardIconBackgroundSize,
      height: AppSizes.statsCardIconBackgroundSize,
      decoration: const BoxDecoration(
        color: AppColors.matchWinBackground,
        shape: BoxShape.circle,
      ),
      child: const Icon(
        Icons.emoji_events_outlined,
        size: AppSizes.statsCardIconSize,
        color: AppColors.primary,
      ),
    );
  }

  Widget _buildRecord() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text(
          AppStrings.statsCardTitle,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppTextStyles.statsCardTitle,
        ),
        const SizedBox(height: AppSizes.statsCardTextSpacing),
        Text(
          AppStrings.statsCardRecord(wins, losses),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppTextStyles.statsCardRecord,
        ),
      ],
    );
  }

  Widget _buildWinRate() {
    return FittedBox(
      fit: BoxFit.scaleDown,
      alignment: Alignment.centerRight,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            AppStrings.statsCardWinRateLabel,
            style: AppTextStyles.statsCardWinRateLabel,
          ),
          const SizedBox(height: AppSizes.statsCardTextSpacing),
          Text(
            AppStrings.statsCardWinRate(winRatePercentage),
            style: AppTextStyles.statsCardWinRate,
          ),
        ],
      ),
    );
  }
}
