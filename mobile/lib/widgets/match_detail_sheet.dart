import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import '../constants/app_sizes.dart';
import '../constants/app_strings.dart';
import '../constants/app_text_styles.dart';
import '../models/match_history_item.dart';

/// 試合履歴の詳細を表示する再利用可能なBottomSheet。
class MatchDetailSheet extends StatefulWidget {
  final MatchHistoryItem match;

  const MatchDetailSheet({
    super.key,
    required this.match,
  });

  static Future<void> show(
    BuildContext context, {
    required MatchHistoryItem match,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => MatchDetailSheet(
        match: match,
      ),
    );
  }

  @override
  State<MatchDetailSheet> createState() => _MatchDetailSheetState();
}

class _MatchDetailSheetState extends State<MatchDetailSheet> {
  @override
  Widget build(BuildContext context) {
    final match = widget.match;
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.fromLTRB(
          AppSizes.bottomSheetPadding,
          AppSizes.spacingSmall,
          AppSizes.bottomSheetPadding,
          AppSizes.bottomSheetPadding,
        ),
        decoration: const BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppSizes.bottomSheetRadius),
          ),
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Spacer(),
                  const Text(
                    AppStrings.matchDetailTitle,
                    style: AppTextStyles.opponentPickerTitle,
                  ),
                  const Spacer(),
                  IconButton(
                    tooltip: AppStrings.matchConfirmEdit,
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              Text(match.detailDate, style: AppTextStyles.selectionFieldTitle),
              const SizedBox(height: AppSizes.spacingSmall),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildPlayerName(
                    match.currentUserName,
                    showWin: match.isWin == true,
                  ),
                  const Padding(
                    padding:
                        EdgeInsets.symmetric(horizontal: AppSizes.spacingLarge),
                    child: Text(AppStrings.matchCardVs),
                  ),
                  _buildPlayerName(
                    match.opponentName,
                    showWin: match.isWin == false,
                  ),
                ],
              ),
              const SizedBox(height: AppSizes.spacingMedium),
              Center(
                child: Text(
                  match.matchFormat.label,
                  style: AppTextStyles.selectionFieldTitle,
                ),
              ),
              const SizedBox(height: AppSizes.spacingSmall),
              _buildScoreTable(match),
              const SizedBox(height: AppSizes.spacingMedium),
              _buildSetCount(match),
              const SizedBox(height: AppSizes.spacingMedium),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text(AppStrings.matchDetailClose),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlayerName(String name, {required bool showWin}) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(name, style: AppTextStyles.matchCardOpponent),
        if (showWin) ...[
          const SizedBox(height: AppSizes.spacingSmall),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSizes.matchCardStatusHorizontalPadding,
              vertical: AppSizes.matchCardStatusVerticalPadding,
            ),
            decoration: BoxDecoration(
              color: AppColors.matchWinBackground,
              borderRadius: BorderRadius.circular(
                AppSizes.matchCardStatusRadius,
              ),
            ),
            child: Text(
              AppStrings.matchCardWin,
              style: AppTextStyles.matchCardStatus.copyWith(
                color: AppColors.matchWin,
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildScoreTable(MatchHistoryItem match) {
    if (match.setScores.isEmpty) {
      return const Text(
        AppStrings.matchScoreUnknown,
        style: AppTextStyles.opponentPickerEmpty,
      );
    }

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.borderLight),
        borderRadius: BorderRadius.circular(AppSizes.selectionFieldRadius),
      ),
      child: Table(
        columnWidths: const {
          0: FlexColumnWidth(1.4),
          1: FlexColumnWidth(),
          2: FlexColumnWidth()
        },
        children: [
          _buildScoreTableRow(
              AppStrings.scoreSet, match.currentUserName, match.opponentName,
              isHeader: true),
          for (var i = 0; i < match.setScores.length; i++)
            _buildScoreTableRow(
              '${AppStrings.scoreSet}${i + 1}',
              match.setScores[i].myScore.toString(),
              match.setScores[i].opponentScore.toString(),
              tiebreak: match.setScores[i].hasTiebreak
                  ? '${match.setScores[i].myTiebreakScore}-${match.setScores[i].opponentTiebreakScore}'
                  : null,
            ),
        ],
      ),
    );
  }

  TableRow _buildScoreTableRow(
    String label,
    String myScore,
    String opponentScore, {
    bool isHeader = false,
    String? tiebreak,
  }) {
    final style = isHeader
        ? AppTextStyles.selectionFieldTitle
        : AppTextStyles.selectionFieldValue;
    return TableRow(
      children: [
        _tableCell(label, style),
        _tableCell(tiebreak == null ? myScore : '$myScore ($tiebreak)', style),
        _tableCell(opponentScore, style),
      ],
    );
  }

  Widget _tableCell(String text, TextStyle style) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSizes.spacingSmall),
      child: Text(text, textAlign: TextAlign.center, style: style),
    );
  }

  Widget _buildSetCount(MatchHistoryItem match) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSizes.matchCardPadding),
      decoration: BoxDecoration(
        color: AppColors.matchUnknownBackground,
        borderRadius: BorderRadius.circular(AppSizes.selectionFieldRadius),
      ),
      child: Column(
        children: [
          const Text(AppStrings.matchDetailSetCount,
              style: AppTextStyles.selectionFieldTitle),
          const SizedBox(height: AppSizes.spacingSmall),
          Text('${match.myWonSetCount} - ${match.opponentWonSetCount}',
              style: AppTextStyles.matchConfirmResultScore),
        ],
      ),
    );
  }
}
