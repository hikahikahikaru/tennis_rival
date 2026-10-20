import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import '../constants/app_sizes.dart';
import '../constants/app_text_styles.dart';

/// タイトルと説明文を表示する、入力補助用の情報ボックス。
class InfoBox extends StatelessWidget {
  final String title;
  final String body;

  const InfoBox({
    super.key,
    required this.title,
    required this.body,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSizes.infoBoxPadding),
      decoration: BoxDecoration(
        color: AppColors.matchWinBackground,
        borderRadius: BorderRadius.circular(AppSizes.cardRadius),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppTextStyles.infoBoxTitle),
          const SizedBox(height: AppSizes.infoBoxTextSpacing),
          Text(body, style: AppTextStyles.infoBoxBody),
        ],
      ),
    );
  }
}
