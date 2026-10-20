import 'package:flutter/material.dart';

import '../constants/app_nav_items.dart';
import '../constants/app_sizes.dart';
import '../constants/app_strings.dart';
import '../constants/app_text_styles.dart';
import '../mocks/mock_data.dart';
import '../models/group_summary.dart';
import '../widgets/bottom_nav_bar.dart';
import '../widgets/group_card.dart';
import '../widgets/primary_button.dart';
import '../widgets/secondary_button.dart';

/// 所属グループの一覧画面。DB連携は別issueのため、現在はモックデータを表示する。
class GroupListScreen extends StatelessWidget {
  final List<GroupSummary> groups;

  const GroupListScreen({
    super.key,
    this.groups = MockData.groups,
  });

  int get _groupNavIndex {
    return appNavItems.indexWhere((item) => item.label == AppStrings.navGroup);
  }

  void _showTemporaryMessage(BuildContext context) {
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      const SnackBar(content: Text(AppStrings.groupUnavailable)),
    );
  }

  void _handleBottomNavTap(BuildContext context, int index) {
    final label = appNavItems[index].label;

    if (label == AppStrings.navGroup) {
      return;
    }

    if (label == AppStrings.navHome) {
      Navigator.pop(context);
      return;
    }

    _showTemporaryMessage(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSizes.screenPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Center(
                child: Text(
                  AppStrings.groupListTitle,
                  style: AppTextStyles.groupListTitle,
                ),
              ),
              const SizedBox(height: AppSizes.spacingLarge),
              const Text(
                AppStrings.groupListSectionTitle,
                style: AppTextStyles.groupListSectionTitle,
              ),
              const SizedBox(height: AppSizes.spacingMedium),
              // 一覧だけをスクロールさせ、下のボタンは常に表示する。
              Expanded(child: _buildGroupList()),
              const SizedBox(height: AppSizes.spacingMedium),
              PrimaryButton(
                label: AppStrings.groupCreate,
                onPressed: () => _showTemporaryMessage(context),
              ),
              const SizedBox(height: AppSizes.spacingMedium),
              SecondaryButton(
                label: AppStrings.groupJoin,
                onPressed: () => _showTemporaryMessage(context),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: CustomBottomNavBar(
        currentIndex: _groupNavIndex,
        onTap: (index) => _handleBottomNavTap(context, index),
      ),
    );
  }

  Widget _buildGroupList() {
    if (groups.isEmpty) {
      return const Center(child: Text(AppStrings.groupListEmpty));
    }

    return ListView.separated(
      itemCount: groups.length,
      separatorBuilder: (context, index) =>
          const SizedBox(height: AppSizes.spacingMedium),
      itemBuilder: (context, index) => GroupCard(group: groups[index]),
    );
  }
}
