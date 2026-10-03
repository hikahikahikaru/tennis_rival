import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import '../constants/app_sizes.dart';
import '../constants/app_strings.dart';
import '../constants/app_text_styles.dart';
import '../models/match_history_item.dart';
import 'match_memo_field.dart';

/// 試合履歴の詳細を表示する再利用可能なBottomSheet。
class MatchDetailSheet extends StatefulWidget {
  final MatchHistoryItem match;
  final Future<String?> Function(String memo) onSaveMemo;

  const MatchDetailSheet({
    super.key,
    required this.match,
    required this.onSaveMemo,
  });

  static Future<void> show(
    BuildContext context, {
    required MatchHistoryItem match,
    required Future<String?> Function(String memo) onSaveMemo,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      enableDrag: false,
      backgroundColor: Colors.transparent,
      builder: (_) => MatchDetailSheet(
        match: match,
        onSaveMemo: onSaveMemo,
      ),
    );
  }

  @override
  State<MatchDetailSheet> createState() => _MatchDetailSheetState();
}

class _MatchDetailSheetState extends State<MatchDetailSheet> {
  late String? _savedMemo;
  late String _draftMemo;
  var _isEditingMemo = false;
  var _isSavingMemo = false;
  String? _memoSaveError;

  @override
  void initState() {
    super.initState();
    _savedMemo = widget.match.personalMemo;
    _draftMemo = _savedMemo ?? '';
  }

  @override
  void didUpdateWidget(covariant MatchDetailSheet oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.match.personalMemo != widget.match.personalMemo &&
        !_isEditingMemo) {
      _savedMemo = widget.match.personalMemo;
      _draftMemo = _savedMemo ?? '';
    }
  }

  void _startMemoEditing() {
    setState(() {
      _draftMemo = _savedMemo ?? '';
      _memoSaveError = null;
      _isEditingMemo = true;
    });
  }

  void _cancelMemoEditing() {
    if (_isSavingMemo) {
      return;
    }
    setState(() {
      _draftMemo = _savedMemo ?? '';
      _memoSaveError = null;
      _isEditingMemo = false;
    });
  }

  Future<void> _saveMemo() async {
    if (_isSavingMemo) {
      return;
    }

    setState(() {
      _isSavingMemo = true;
      _memoSaveError = null;
    });

    try {
      await widget.onSaveMemo(_draftMemo);
      if (!mounted) {
        return;
      }
      // 親側のModelとキャッシュ更新が完了してからpopを許可し、このSheetだけを閉じる。
      setState(() {
        _isSavingMemo = false;
      });
      Navigator.of(context).pop();
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _isSavingMemo = false;
        _memoSaveError = AppStrings.matchDetailMemoSaveFailed;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final match = widget.match;
    return PopScope(
      canPop: !_isSavingMemo,
      child: SafeArea(
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
                      onPressed:
                          _isSavingMemo ? null : () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
                Text(match.detailDate,
                    style: AppTextStyles.selectionFieldTitle),
                const SizedBox(height: AppSizes.spacingSmall),
                Row(
                  children: [
                    Expanded(
                      child: _buildPlayerName(
                        match.currentUserName,
                        showWin: match.isWin == true,
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(
                          horizontal: AppSizes.spacingLarge),
                      child: Text(AppStrings.matchCardVs),
                    ),
                    Expanded(
                      child: _buildPlayerName(
                        match.opponentName,
                        showWin: match.isWin == false,
                      ),
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
                _buildPersonalMemo(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPlayerName(String name, {required bool showWin}) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          name,
          textAlign: TextAlign.center,
          softWrap: true,
          style: AppTextStyles.matchCardOpponent,
        ),
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
    if (match.setScores.isEmpty) {
      return const Text(
        AppStrings.matchScoreUnknown,
        style: AppTextStyles.opponentPickerEmpty,
      );
    }

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

  Widget _buildPersonalMemo() {
    if (_isEditingMemo) {
      return _buildMemoEditor();
    }

    final memo = _savedMemo;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                AppStrings.matchConfirmMemo,
                style: AppTextStyles.scoreSectionTitle,
              ),
            ),
            IconButton(
              tooltip: AppStrings.matchDetailMemoEditTooltip,
              onPressed: _startMemoEditing,
              icon: const Icon(Icons.edit_outlined),
            ),
          ],
        ),
        Material(
          color: AppColors.matchUnknownBackground,
          borderRadius: BorderRadius.circular(AppSizes.selectionFieldRadius),
          child: InkWell(
            onTap: _startMemoEditing,
            borderRadius: BorderRadius.circular(
              AppSizes.selectionFieldRadius,
            ),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSizes.matchCardPadding),
              child: Text(
                memo ?? AppStrings.matchDetailMemoEmpty,
                style: memo == null
                    ? AppTextStyles.opponentPickerEmpty
                    : AppTextStyles.matchDetailMemo,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMemoEditor() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        MatchMemoField(
          initialValue: _savedMemo ?? '',
          onChanged: (memo) => _draftMemo = memo,
        ),
        if (_memoSaveError != null) ...[
          const SizedBox(height: AppSizes.scoreHeaderSpacing),
          Text(
            _memoSaveError!,
            style: AppTextStyles.opponentPickerError,
          ),
        ],
        const SizedBox(height: AppSizes.scoreSectionSpacing),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: _isSavingMemo ? null : _cancelMemoEditing,
                child: const Text(AppStrings.matchDetailMemoCancel),
              ),
            ),
            const SizedBox(width: AppSizes.spacingMedium),
            Expanded(
              child: FilledButton(
                onPressed: _isSavingMemo ? null : _saveMemo,
                child: _isSavingMemo
                    ? const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox.square(
                            dimension: AppSizes.matchMemoProgressSize,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                          SizedBox(width: AppSizes.spacingMedium),
                          Text(AppStrings.matchDetailMemoSaving),
                        ],
                      )
                    : const Text(AppStrings.matchDetailMemoSave),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
