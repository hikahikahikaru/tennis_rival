import 'package:flutter/material.dart';

import '../constants/app_sizes.dart';
import '../constants/app_strings.dart';
import '../constants/app_text_styles.dart';
import '../models/match_history_item.dart';
import 'match_card.dart';

/// 最近の試合について、取得状態に応じた表示と再試行操作を担当する。
class RecentMatchList extends StatelessWidget {
  final bool isLoading;
  final Object? error;
  final List<MatchHistoryItem> matches;
  final VoidCallback onRetry;
  final Future<void> Function(MatchHistoryItem match) onMatchTap;

  const RecentMatchList({
    super.key,
    required this.isLoading,
    required this.error,
    required this.matches,
    required this.onRetry,
    required this.onMatchTap,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: AppSizes.spacingLarge),
        child: Center(
          child: Column(
            children: [
              CircularProgressIndicator(),
              SizedBox(height: AppSizes.spacingMedium),
              Text(
                AppStrings.homeRecentMatchesLoading,
                style: AppTextStyles.opponentPickerEmpty,
              ),
            ],
          ),
        ),
      );
    }

    if (error != null) {
      return Center(
        child: Column(
          children: [
            const Text(
              AppStrings.homeRecentMatchesFetchFailed,
              style: AppTextStyles.opponentPickerError,
            ),
            const SizedBox(height: AppSizes.spacingSmall),
            OutlinedButton(
              onPressed: onRetry,
              child: const Text(AppStrings.retry),
            ),
          ],
        ),
      );
    }

    if (matches.isEmpty) {
      return const Text(
        AppStrings.homeRecentMatchesEmpty,
        style: AppTextStyles.opponentPickerEmpty,
      );
    }

    return Column(
      children: [
        for (final match in matches) ...[
          MatchCard(
            date: match.displayDate,
            opponentName: match.opponentName,
            score: match.scoreText,
            isWin: match.isWin,
            onTap: () => onMatchTap(match),
          ),
          const SizedBox(height: AppSizes.spacingMedium),
        ],
      ],
    );
  }
}
