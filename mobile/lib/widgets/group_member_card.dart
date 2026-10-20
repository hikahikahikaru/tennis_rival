import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import '../constants/app_sizes.dart';
import '../constants/app_strings.dart';
import '../constants/app_text_styles.dart';
import '../models/group_member.dart';

/// メンバー名・管理者バッジ・グループ内戦績を表示するカード。
class GroupMemberCard extends StatelessWidget {
  final GroupMember member;
  final VoidCallback? onTap;

  const GroupMemberCard({super.key, required this.member, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppSizes.groupCardPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Flexible(
                    child: Text(
                      member.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.groupCardName,
                    ),
                  ),
                  if (member.isAdmin) ...[
                    const SizedBox(width: AppSizes.groupDetailTextSpacing),
                    _buildAdminBadge(),
                  ],
                ],
              ),
              const SizedBox(height: AppSizes.groupCardTextSpacing),
              Text(
                AppStrings.groupMemberRecord(
                  member.wins,
                  member.losses,
                  member.winRatePercentage,
                ),
                style: AppTextStyles.groupCardMemberCount,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAdminBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.groupDetailBadgeHorizontalPadding,
        vertical: AppSizes.groupDetailBadgeVerticalPadding,
      ),
      decoration: BoxDecoration(
        color: AppColors.matchWinBackground,
        borderRadius: BorderRadius.circular(AppSizes.groupDetailBadgeRadius),
      ),
      child: const Text(
        AppStrings.groupAdminBadge,
        style: AppTextStyles.groupDetailAdminBadge,
      ),
    );
  }
}
