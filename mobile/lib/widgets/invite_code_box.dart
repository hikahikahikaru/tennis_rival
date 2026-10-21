import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import '../constants/app_sizes.dart';
import '../constants/app_strings.dart';
import '../constants/app_text_styles.dart';

/// 招待コードの表示とコピー操作を提供するボックス。コピー処理は親Widgetへ委譲する。
class InviteCodeBox extends StatelessWidget {
  final String inviteCode;
  final VoidCallback onCopy;

  const InviteCodeBox({
    super.key,
    required this.inviteCode,
    required this.onCopy,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSizes.groupDetailCardPadding),
      decoration: BoxDecoration(
        color: AppColors.matchWinBackground,
        borderRadius: BorderRadius.circular(AppSizes.cardRadius),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            AppStrings.groupInviteCodeTitle,
            style: AppTextStyles.infoBoxTitle,
          ),
          const SizedBox(height: AppSizes.groupDetailTextSpacing),
          Row(
            children: [
              Expanded(
                child: Container(
                  height: AppSizes.groupDetailCodeFieldHeight,
                  alignment: Alignment.centerLeft,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSizes.selectionFieldPadding,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.cardBackground,
                    border: Border.all(color: AppColors.cardBorder),
                    borderRadius:
                        BorderRadius.circular(AppSizes.selectionFieldRadius),
                  ),
                  child: Text(
                    inviteCode,
                    style: AppTextStyles.groupDetailInviteCode,
                  ),
                ),
              ),
              const SizedBox(width: AppSizes.groupDetailCodeSpacing),
              TextButton(
                onPressed: onCopy,
                child: const Text(
                  AppStrings.groupInviteCodeCopy,
                  style: AppTextStyles.groupDetailCopyButton,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSizes.groupDetailTextSpacing),
          const Text(
            AppStrings.groupInviteCodeNote,
            style: AppTextStyles.infoBoxBody,
          ),
        ],
      ),
    );
  }
}
