import 'package:flutter/material.dart';

import '../constants/app_nav_items.dart';
import '../constants/app_sizes.dart';
import '../constants/app_strings.dart';
import '../constants/app_text_styles.dart';
import '../models/group_summary.dart';
import '../services/group_service.dart';
import '../widgets/bottom_nav_bar.dart';
import '../widgets/group_card.dart';
import '../widgets/primary_button.dart';
import '../widgets/secondary_button.dart';
import 'group_create_screen.dart';
import 'group_detail_screen.dart';
import 'group_join_screen.dart';
import 'match_entry_screen.dart';
import 'match_history_screen.dart';

/// 所属グループを取得し、各グループへの操作を提供する一覧画面。
class GroupListScreen extends StatefulWidget {
  final List<GroupSummary>? groups;
  final GroupService? groupService;

  const GroupListScreen({
    super.key,
    this.groups,
    this.groupService,
  });

  @override
  State<GroupListScreen> createState() => _GroupListScreenState();
}

class _GroupListScreenState extends State<GroupListScreen> {
  late final GroupService _groupService;
  List<GroupSummary> _groups = const [];
  var _isLoading = false;
  var _hasLoadError = false;
  var _loadRequestId = 0;

  @override
  void initState() {
    super.initState();
    _groupService = widget.groupService ?? GroupService.instance;
    final injectedGroups = widget.groups;
    if (injectedGroups != null) {
      _groups = injectedGroups;
    } else {
      _loadGroups();
    }
  }

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

  Future<void> _openGroupCreateScreen(BuildContext context) async {
    final createdGroupId = await Navigator.push<String>(
      context,
      MaterialPageRoute(
        builder: (context) => GroupCreateScreen(groupService: _groupService),
      ),
    );
    if (!mounted || createdGroupId == null) return;
    await _loadGroups(forceRefresh: true);
  }

  Future<void> _loadGroups({bool forceRefresh = false}) async {
    final requestId = ++_loadRequestId;
    setState(() {
      _isLoading = true;
      _hasLoadError = false;
    });
    try {
      final groups = await _groupService.loadGroups(
        forceRefresh: forceRefresh,
      );
      if (!mounted || requestId != _loadRequestId) return;
      setState(() {
        _groups = groups;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted || requestId != _loadRequestId) return;
      setState(() {
        _isLoading = false;
        _hasLoadError = true;
      });
    }
  }

  void _openGroupDetailScreen(BuildContext context, String groupId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => GroupDetailScreen(groupId: groupId),
      ),
    );
  }

  void _openGroupJoinScreen(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const GroupJoinScreen()),
    );
  }

  void _handleBottomNavTap(BuildContext context, int index) {
    final label = appNavItems[index].label;

    if (label == AppStrings.navGroup) {
      return;
    }

    if (label == AppStrings.navHome) {
      Navigator.popUntil(context, (route) => route.isFirst);
      return;
    }

    if (label == AppStrings.navStats) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const MatchHistoryScreen()),
      );
      return;
    }

    if (label == AppStrings.navEntry) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const MatchEntryScreen()),
      );
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
                onPressed: () => _openGroupCreateScreen(context),
              ),
              const SizedBox(height: AppSizes.spacingMedium),
              SecondaryButton(
                label: AppStrings.groupJoin,
                onPressed: () => _openGroupJoinScreen(context),
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
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: AppSizes.spacingMedium),
            Text(AppStrings.groupListLoading),
          ],
        ),
      );
    }

    if (_hasLoadError) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(AppStrings.groupListFetchFailed),
            const SizedBox(height: AppSizes.spacingMedium),
            TextButton(
              onPressed: () => _loadGroups(forceRefresh: true),
              child: const Text(AppStrings.retry),
            ),
          ],
        ),
      );
    }

    if (_groups.isEmpty) {
      return const Center(child: Text(AppStrings.groupListEmpty));
    }

    return ListView.separated(
      itemCount: _groups.length,
      separatorBuilder: (context, index) =>
          const SizedBox(height: AppSizes.spacingMedium),
      itemBuilder: (context, index) => GroupCard(
        group: _groups[index],
        onTap: () => _openGroupDetailScreen(context, _groups[index].id),
      ),
    );
  }
}
