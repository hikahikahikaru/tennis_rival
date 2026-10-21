import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import '../constants/app_sizes.dart';
import '../constants/app_text_styles.dart';

/// 下線で選択中を示すタブバー。選択状態は親Widgetが保持する。
class UnderlineTabBar extends StatelessWidget {
  final List<String> labels;
  final int selectedIndex;
  final ValueChanged<int> onChanged;

  const UnderlineTabBar({
    super.key,
    required this.labels,
    required this.selectedIndex,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var i = 0; i < labels.length; i++)
          Expanded(
            child: InkWell(
              onTap: () => onChanged(i),
              child: Container(
                alignment: Alignment.center,
                padding: const EdgeInsets.symmetric(
                  vertical: AppSizes.groupDetailTabVerticalPadding,
                ),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      width: AppSizes.groupDetailTabIndicatorHeight,
                      color: i == selectedIndex
                          ? AppColors.primary
                          : AppColors.cardBorder,
                    ),
                  ),
                ),
                child: Text(
                  labels[i],
                  style: AppTextStyles.groupDetailTab.copyWith(
                    color: i == selectedIndex
                        ? AppColors.primary
                        : AppColors.textSecondary,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
