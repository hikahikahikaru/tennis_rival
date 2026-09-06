import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_sizes.dart';
import '../constants/app_text_styles.dart';

// 「試合日」や「対戦相手」を選ぶための、アイコン付きの入力枠
class SelectionField extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final VoidCallback onTap;

  const SelectionField({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppSizes.selectionFieldRadius),
      child: Container(
        padding: const EdgeInsets.all(AppSizes.selectionFieldPadding),
        decoration: BoxDecoration(
          // 枠線の色を定数から読み込む
          border: Border.all(color: AppColors.borderLight),
          borderRadius: BorderRadius.circular(AppSizes.selectionFieldRadius),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // タイトルの文字スタイルを定数から読み込む
                Text(title, style: AppTextStyles.selectionFieldTitle),
                // すき間のサイズを定数から読み込む
                const SizedBox(height: AppSizes.spacingSmall),
                // 値の文字スタイルを定数から読み込む
                Text(value, style: AppTextStyles.selectionFieldValue),
              ],
            ),
            Icon(icon, color: AppColors.primary),
          ],
        ),
      ),
    );
  }
}
