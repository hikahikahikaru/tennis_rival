import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import '../constants/app_nav_items.dart';
import '../constants/app_sizes.dart';
import '../constants/app_strings.dart';
import '../constants/app_text_styles.dart';
import '../models/user_stats.dart';
import '../widgets/bottom_nav_bar.dart';
import '../widgets/match_card.dart';
import '../widgets/pending_match_card.dart';
import '../widgets/primary_button.dart';
import '../widgets/stats_card.dart';
import 'match_entry_screen.dart';

/// 既存部品の配置と画面遷移・操作の接続を担当するホーム画面。
///
/// DB取得や戦績計算はここでは行わず、取得・計算済みの値を各Widgetへ渡す。
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  // Issue #5では画面確認用の仮データを一か所にまとめる。
  // DB取得対応時はここを取得結果へ差し替え、勝率計算はUserStatsに任せる。
  static const UserStats _sampleStats = UserStats(wins: 4, losses: 2);
  static const int _samplePendingCount = 1;
  static const List<_RecentMatchSample> _sampleRecentMatches = [
    _RecentMatchSample(
      date: '8月24日',
      opponentName: '西やん',
      score: '6-4, 6-3',
      isWin: true,
    ),
    _RecentMatchSample(
      date: '8月18日',
      opponentName: 'ピンちゃん',
      score: '4-6, 7-5, 10-8',
      isWin: true,
    ),
  ];

  int get _homeNavIndex {
    return appNavItems.indexWhere((item) => item.label == AppStrings.navHome);
  }

  void _openMatchEntryScreen(BuildContext context) {
    // 記録ボタンと下部ナビの「登録」は同じ遷移先なので、入口を共通化する。
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const MatchEntryScreen(),
      ),
    );
  }

  void _showTemporaryMessage(BuildContext context, String message) {
    // 通知・確認待ち・未実装タブは遷移先ができるまでSnackBarで仮案内する。
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  void _handleBottomNavTap(BuildContext context, int index) {
    final selectedItem = appNavItems[index];

    if (selectedItem.label == AppStrings.navHome) {
      return;
    }

    if (selectedItem.label == AppStrings.navEntry) {
      _openMatchEntryScreen(context);
      return;
    }

    _showTemporaryMessage(context, AppStrings.homeNavUnavailable);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        // 下部ナビと重ならないようSafeArea内に置き、カード追加に備えて本文を縦スクロールにする。
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSizes.screenPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(context),
              const SizedBox(height: AppSizes.spacingLarge),
              const Text(
                AppStrings.homeGreeting,
                style: AppTextStyles.homeGreeting,
              ),
              const SizedBox(height: AppSizes.scoreSectionSpacing),
              PrimaryButton(
                label: AppStrings.recordMatch,
                icon: Icons.add,
                onPressed: () => _openMatchEntryScreen(context),
              ),
              const SizedBox(height: AppSizes.spacingLarge),
              const StatsCard(stats: _sampleStats),
              const SizedBox(height: AppSizes.scoreSectionSpacing),
              PendingMatchCard(
                pendingCount: _samplePendingCount,
                onConfirm: () {
                  _showTemporaryMessage(
                    context,
                    AppStrings.homePendingMatchUnavailable,
                  );
                },
              ),
              const SizedBox(height: AppSizes.spacingLarge),
              const Text(
                AppStrings.homeRecentMatchesTitle,
                style: AppTextStyles.homeSectionTitle,
              ),
              const SizedBox(height: AppSizes.scoreSectionSpacing),
              for (final match in _sampleRecentMatches) ...[
                MatchCard(
                  date: match.date,
                  opponentName: match.opponentName,
                  score: match.score,
                  isWin: match.isWin,
                ),
                const SizedBox(height: AppSizes.spacingMedium),
              ],
            ],
          ),
        ),
      ),
      bottomNavigationBar: CustomBottomNavBar(
        currentIndex: _homeNavIndex,
        onTap: (index) => _handleBottomNavTap(context, index),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      children: [
        const Icon(
          Icons.sports_tennis,
          color: AppColors.primary,
          size: AppSizes.homeHeaderIconSize,
        ),
        const SizedBox(width: AppSizes.spacingMedium),
        const Expanded(
          child: Text(
            AppStrings.appName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.homeAppName,
          ),
        ),
        IconButton(
          tooltip: AppStrings.homeNotificationTooltip,
          onPressed: () {
            _showTemporaryMessage(
              context,
              AppStrings.homeNotificationUnavailable,
            );
          },
          icon: const Icon(
            Icons.notifications_none,
            color: AppColors.primary,
            size: AppSizes.homeNotificationIconSize,
          ),
        ),
      ],
    );
  }
}

class _RecentMatchSample {
  final String date;
  final String opponentName;
  final String score;
  final bool isWin;

  const _RecentMatchSample({
    required this.date,
    required this.opponentName,
    required this.score,
    required this.isWin,
  });
}
