import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import '../constants/app_sizes.dart';
import '../constants/app_strings.dart';
import '../constants/app_text_styles.dart';
import '../models/group_summary.dart';

/// グループ名とメンバー数を表示するカード。
class GroupCard extends StatelessWidget {
  final GroupSummary group;
  final VoidCallback? onTap;

  const GroupCard({
    super.key,
    required this.group,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final borderRadius = BorderRadius.circular(AppSizes.cardRadius);

    return Material(
      color: AppColors.cardBackground,
      shape: RoundedRectangleBorder(
        borderRadius: borderRadius,
        side: const BorderSide(color: AppColors.cardBorder),
      ),
      child: InkWell(
        borderRadius: borderRadius,
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppSizes.groupCardPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                group.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.groupCardName,
              ),
              const SizedBox(height: AppSizes.groupCardTextSpacing),
              Text(
                AppStrings.groupMemberCount(group.memberCount),
                style: AppTextStyles.groupCardMemberCount,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
