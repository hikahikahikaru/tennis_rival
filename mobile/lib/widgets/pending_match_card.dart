import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import '../constants/app_sizes.dart';
import '../constants/app_strings.dart';
import '../constants/app_text_styles.dart';

/// 確認待ち件数と操作だけを外部から受け取り、表示とcallback呼び出しだけを担うカード。
class PendingMatchCard extends StatelessWidget {
  final int pendingCount;
  final VoidCallback onConfirm;

  const PendingMatchCard({
    super.key,
    required this.pendingCount,
    required this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.pendingMatchBackground,
        border: Border.all(color: AppColors.pendingMatchBorder),
        borderRadius: BorderRadius.circular(AppSizes.cardRadius),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.pendingMatchCardPadding),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final textScale = MediaQuery.textScalerOf(context).scale(1);
            final useWideLayout = constraints.maxWidth >=
                    AppSizes.pendingMatchCardWideLayoutMinWidth &&
                textScale <= AppSizes.pendingMatchCardCompactTextScaleThreshold;

            return useWideLayout ? _buildWideContent() : _buildCompactContent();
          },
        ),
      ),
    );
  }

  Widget _buildWideContent() {
    return Row(
      children: [
        _buildIcon(),
        const SizedBox(width: AppSizes.pendingMatchCardContentSpacing),
        Expanded(child: _buildTitleAndBadge()),
        const SizedBox(width: AppSizes.pendingMatchCardContentSpacing),
        _buildConfirmButton(),
      ],
    );
  }

  Widget _buildCompactContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            _buildIcon(),
            const SizedBox(width: AppSizes.pendingMatchCardContentSpacing),
            Expanded(child: _buildTitleAndBadge()),
          ],
        ),
        const SizedBox(height: AppSizes.pendingMatchCardContentSpacing),
        Align(
          alignment: Alignment.centerRight,
          child: _buildConfirmButton(),
        ),
      ],
    );
  }

  Widget _buildIcon() {
    return Container(
      width: AppSizes.pendingMatchCardIconBackgroundSize,
      height: AppSizes.pendingMatchCardIconBackgroundSize,
      decoration: const BoxDecoration(
        color: AppColors.pendingMatchHighlightBackground,
        shape: BoxShape.circle,
      ),
      child: const Icon(
        Icons.access_time,
        size: AppSizes.pendingMatchCardIconSize,
        color: AppColors.primary,
      ),
    );
  }

  Widget _buildTitleAndBadge() {
    return Wrap(
      spacing: AppSizes.scoreHeaderSpacing,
      runSpacing: AppSizes.spacingSmall,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        const Text(
          AppStrings.pendingMatchCardTitle,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: AppTextStyles.pendingMatchCardTitle,
        ),
        _buildCountBadge(),
      ],
    );
  }

  Widget _buildCountBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.pendingMatchCardBadgeHorizontalPadding,
        vertical: AppSizes.pendingMatchCardBadgeVerticalPadding,
      ),
      decoration: BoxDecoration(
        color: AppColors.pendingMatchHighlightBackground,
        borderRadius: BorderRadius.circular(AppSizes.matchCardStatusRadius),
      ),
      child: Text(
        AppStrings.pendingMatchCardCount(pendingCount),
        style: AppTextStyles.pendingMatchCardBadge,
      ),
    );
  }

  Widget _buildConfirmButton() {
    return OutlinedButton(
      onPressed: onConfirm,
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.primary,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSizes.pendingMatchCardButtonHorizontalPadding,
          vertical: AppSizes.pendingMatchCardButtonVerticalPadding,
        ),
        side: const BorderSide(color: AppColors.primary),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSizes.selectionFieldRadius),
        ),
        textStyle: AppTextStyles.pendingMatchCardButton,
      ),
      child: const Text(AppStrings.pendingMatchCardConfirm),
    );
  }
}
