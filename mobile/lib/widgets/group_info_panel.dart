import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import '../constants/app_sizes.dart';
import '../constants/app_strings.dart';
import '../constants/app_text_styles.dart';
import '../models/group_detail.dart';
import 'invite_code_box.dart';

/// グループ詳細と招待コードをまとめて表示し、折り畳みできるパネル。
class GroupInfoPanel extends StatefulWidget {
  final GroupDetail group;
  final VoidCallback onCopyInviteCode;
  final bool initiallyExpanded;

  const GroupInfoPanel({
    super.key,
    required this.group,
    required this.onCopyInviteCode,
    this.initiallyExpanded = true,
  });

  @override
  State<GroupInfoPanel> createState() => _GroupInfoPanelState();
}

class _GroupInfoPanelState extends State<GroupInfoPanel> {
  late bool _isExpanded = widget.initiallyExpanded;

  @override
  Widget build(BuildContext context) {
    final group = widget.group;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(AppSizes.groupDetailCardPadding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        group.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.groupDetailName,
                      ),
                    ),
                    IconButton(
                      tooltip: _isExpanded
                          ? AppStrings.groupInfoCollapseTooltip
                          : AppStrings.groupInfoExpandTooltip,
                      iconSize: AppSizes.groupDetailToggleIconSize,
                      color: AppColors.primary,
                      icon: Icon(
                        _isExpanded
                            ? Icons.keyboard_arrow_up
                            : Icons.keyboard_arrow_down,
                      ),
                      onPressed: () =>
                          setState(() => _isExpanded = !_isExpanded),
                    ),
                  ],
                ),
                if (_isExpanded) ...[
                  const SizedBox(height: AppSizes.groupDetailTextSpacing),
                  Text(
                    group.description,
                    style: AppTextStyles.groupDetailDescription,
                  ),
                  const SizedBox(height: AppSizes.groupDetailInfoRowSpacing),
                  Wrap(
                    spacing: AppSizes.groupDetailInfoRowSpacing,
                    runSpacing: AppSizes.groupDetailTextSpacing,
                    children: [
                      Text(
                        AppStrings.groupMemberCount(group.memberCount),
                        style: AppTextStyles.groupDetailMeta,
                      ),
                      Text(
                        AppStrings.groupCreatedDate(group.createdDateText),
                        style: AppTextStyles.groupDetailMeta,
                      ),
                      Text(
                        AppStrings.groupAdminName(group.adminName),
                        style: AppTextStyles.groupDetailMeta,
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
        if (_isExpanded) ...[
          const SizedBox(height: AppSizes.spacingMedium),
          InviteCodeBox(
            inviteCode: group.inviteCode,
            onCopy: widget.onCopyInviteCode,
          ),
        ],
      ],
    );
  }
}
