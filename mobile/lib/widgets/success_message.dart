import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_sizes.dart';
import '../constants/app_strings.dart';
import '../constants/app_text_styles.dart';

class SuccessMessage extends StatelessWidget {
  final String opponentName;

  const SuccessMessage({
    super.key,
    required this.opponentName,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: AppSizes.successIconCircleSize,
          height: AppSizes.successIconCircleSize,
          decoration: const BoxDecoration(
            color: AppColors.successBackground,
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.check,
            size: AppSizes.successIconSize,
            color: AppColors.successIcon,
          ),
        ),
        const SizedBox(height: AppSizes.spacingLarge),
        const Text(
          AppStrings.requestSentMain,
          style: AppTextStyles.successTitle,
        ),
        const SizedBox(height: AppSizes.spacingMedium),
        Text(
          AppStrings.requestSentSub(opponentName),
          style: AppTextStyles.successSubTitle,
        ),
        const SizedBox(height: AppSizes.spacingSmall), // ここは既存の4.0か8.0で調整
        const Text(
          AppStrings.requestSentDetail,
          style: AppTextStyles.successDetail,
        ),
      ],
    );
  }
}
