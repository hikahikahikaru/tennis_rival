import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import '../constants/app_nav_items.dart';
import '../constants/app_sizes.dart';
import '../constants/app_strings.dart';
import '../constants/app_text_styles.dart';
import '../mocks/mock_data.dart';
import '../models/match_history_item.dart';
import '../models/user_stats.dart';
import '../repositories/match_history_repository.dart';
import '../widgets/bottom_nav_bar.dart';
import '../widgets/pending_match_card.dart';
import '../widgets/primary_button.dart';
import '../widgets/recent_match_list.dart';
import '../widgets/stats_card.dart';
import 'match_entry_screen.dart';

/// 既存部品の配置と画面遷移・操作の接続を担当するホーム画面。
///
/// DB通信はRepositoryに委譲し、画面では取得開始と状態表示を担当する。
/// 戦績の計算はUserStatsに任せる。
class HomeScreen extends StatefulWidget {
  final MatchHistoryRepository? matchHistoryRepository;
  final String? currentUserId;

  const HomeScreen({
    super.key,
    this.matchHistoryRepository,
    this.currentUserId,
  });

  // 戦績と確認待ち件数は画面確認用の仮データ。DB対応時に差し替える。
  static const UserStats _sampleStats = UserStats(wins: 4, losses: 2);
  static const int _samplePendingCount = 1;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late MatchHistoryRepository _matchHistoryRepository;
  late String _currentUserId;
  var _isRecentMatchesLoading = true;
  Object? _recentMatchesError;
  List<MatchHistoryItem> _recentMatches = const [];
  int _recentMatchesRequestId = 0;

  @override
  void initState() {
    super.initState();
    _setDependencies();
    _loadRecentMatches();
  }

  @override
  void didUpdateWidget(covariant HomeScreen oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.matchHistoryRepository != widget.matchHistoryRepository ||
        oldWidget.currentUserId != widget.currentUserId) {
      _setDependencies();
      _loadRecentMatches();
    }
  }

  void _setDependencies() {
    _matchHistoryRepository =
        widget.matchHistoryRepository ?? SupabaseMatchHistoryRepository();
    // 認証未実装のため、DB取得時の閲覧者はseed.sqlの仮ユーザーに固定する。
    _currentUserId = widget.currentUserId ?? MockData.currentUserId;
  }

  int get _homeNavIndex {
    return appNavItems.indexWhere((item) => item.label == AppStrings.navHome);
  }

  Future<void> _loadRecentMatches() async {
    // ユーザー変更や再試行が重なっても、古い通信結果で最新の表示を上書きしない。
    final requestId = ++_recentMatchesRequestId;
    setState(() {
      _isRecentMatchesLoading = true;
      _recentMatchesError = null;
    });

    try {
      final matches =
          await _matchHistoryRepository.fetchRecentMatches(_currentUserId);

      if (!mounted || requestId != _recentMatchesRequestId) {
        return;
      }

      setState(() {
        _recentMatches = matches;
        _isRecentMatchesLoading = false;
      });
    } catch (error) {
      if (!mounted || requestId != _recentMatchesRequestId) {
        return;
      }

      setState(() {
        _recentMatches = const [];
        _recentMatchesError = error;
        _isRecentMatchesLoading = false;
      });
    }
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
              const StatsCard(stats: HomeScreen._sampleStats),
              const SizedBox(height: AppSizes.scoreSectionSpacing),
              PendingMatchCard(
                pendingCount: HomeScreen._samplePendingCount,
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
              RecentMatchList(
                isLoading: _isRecentMatchesLoading,
                error: _recentMatchesError,
                matches: _recentMatches,
                onRetry: _loadRecentMatches,
              ),
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
