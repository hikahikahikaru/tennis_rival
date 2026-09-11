import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../constants/app_colors.dart';
import '../constants/app_sizes.dart';
import '../constants/app_strings.dart';
import '../constants/app_text_styles.dart';
import '../models/match_format.dart';
import '../models/match_score.dart';
import '../models/match_set_score.dart';
import '../widgets/primary_button.dart';

class MatchConfirmScreen extends StatelessWidget {
  final DateTime matchDate;
  final String opponentName;
  final MatchFormat matchFormat;
  final List<MatchSetScore> setScores;
  final String? memo;
  final VoidCallback onEdit;
  final VoidCallback onRequestConfirmation;

  const MatchConfirmScreen({
    super.key,
    required this.matchDate,
    required this.opponentName,
    required this.matchFormat,
    required this.setScores,
    this.memo,
    required this.onEdit,
    required this.onRequestConfirmation,
  });

  String get _formattedDate => DateFormat('yyyy年M月d日').format(matchDate);

  MatchScore get _matchScore => MatchScore(
        matchFormat: matchFormat,
        setScores: setScores,
      );

  List<MatchSetScore> get _targetSetScores =>
      _matchScore.confirmedSetScores ??
      setScores.take(matchFormat.setCount).toList();

  int get _myWonSetCount => _matchScore.myWonSetCount;

  int get _opponentWonSetCount => _matchScore.opponentWonSetCount;

  bool get _isMyMatchWin => _matchScore.isMyMatchWin;

  bool get _isOpponentMatchWin => _matchScore.isOpponentMatchWin;

  String get _resultLabel {
    if (_isMyMatchWin) {
      return AppStrings.matchConfirmWin;
    }

    if (_isOpponentMatchWin) {
      return AppStrings.matchConfirmLose;
    }

    return AppStrings.matchConfirmUndecided;
  }

  Color get _resultColor {
    if (_isMyMatchWin) {
      return AppColors.primary;
    }

    if (_isOpponentMatchWin) {
      return AppColors.matchLose;
    }

    return AppColors.textSecondary;
  }

  String get _memoText {
    final value = memo?.trim();
    if (value == null || value.isEmpty) {
      return AppStrings.matchConfirmMemoEmpty;
    }

    return value;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.matchConfirmTitle),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSizes.matchCardPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionTitle(AppStrings.matchInfo),
              const SizedBox(height: AppSizes.scoreHeaderSpacing),
              _buildMatchInfoCard(),
              const SizedBox(height: AppSizes.scoreSectionSpacing),
              _buildSectionTitle(AppStrings.scoreSectionTitle),
              const SizedBox(height: AppSizes.scoreHeaderSpacing),
              _buildScoreCard(),
              const SizedBox(height: AppSizes.scoreSectionSpacing),
              _buildSectionTitle(AppStrings.matchConfirmResult),
              const SizedBox(height: AppSizes.scoreHeaderSpacing),
              _buildResultCard(),
              const SizedBox(height: AppSizes.scoreSectionSpacing),
              _buildMemoHeader(),
              const SizedBox(height: AppSizes.scoreHeaderSpacing),
              _buildMemoCard(),
              const SizedBox(height: AppSizes.scoreSectionSpacing),
              _buildNotice(),
              const SizedBox(height: AppSizes.scoreSectionSpacing),
              _buildActions(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: AppTextStyles.scoreSectionTitle,
    );
  }

  Widget _buildMatchInfoCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.matchCardPadding),
        child: Column(
          children: [
            _buildInfoRow(AppStrings.matchDate, _formattedDate),
            const SizedBox(height: AppSizes.scoreInputSpacing),
            _buildInfoRow(AppStrings.opponent, opponentName),
            const SizedBox(height: AppSizes.scoreInputSpacing),
            _buildInfoRow(AppStrings.matchFormat, matchFormat.label),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(
            label,
            style: AppTextStyles.selectionFieldTitle,
          ),
        ),
        const SizedBox(width: AppSizes.scoreInputSpacing),
        Expanded(
          flex: 2,
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: AppTextStyles.selectionFieldValue,
          ),
        ),
      ],
    );
  }

  Widget _buildScoreCard() {
    final targetSetScores = _targetSetScores.toList();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.matchCardPadding),
        child: Column(
          children: [
            for (var i = 0; i < targetSetScores.length; i++) ...[
              _buildScoreRow(i + 1, targetSetScores[i]),
              if (i != targetSetScores.length - 1)
                const Divider(height: AppSizes.scoreSectionSpacing),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildScoreRow(int setNumber, MatchSetScore setScore) {
    return Row(
      children: [
        Text(
          '${AppStrings.scoreSet}$setNumber',
          style: AppTextStyles.scoreSetLabel,
        ),
        const Spacer(),
        Text(
          setScore.displayScore,
          style: AppTextStyles.scoreInputValue,
        ),
      ],
    );
  }

  Widget _buildResultCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.matchCardPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '$_myWonSetCount - $_opponentWonSetCount',
              style: AppTextStyles.matchConfirmResultScore,
            ),
            const SizedBox(height: AppSizes.spacingSmall),
            Text(
              _resultLabel,
              style: AppTextStyles.matchCardStatus.copyWith(
                color: _resultColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMemoHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle(AppStrings.matchConfirmMemo),
        const SizedBox(height: AppSizes.spacingSmall),
        const Text(
          AppStrings.matchConfirmMemoNote,
          style: AppTextStyles.selectionFieldTitle,
        ),
      ],
    );
  }

  Widget _buildMemoCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.matchCardPadding),
        child: Align(
          alignment: Alignment.centerLeft,
          child: Text(
            _memoText,
            style: AppTextStyles.selectionFieldValue,
          ),
        ),
      ),
    );
  }

  Widget _buildNotice() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSizes.matchCardPadding),
      decoration: const BoxDecoration(
        color: AppColors.matchWinBackground,
        borderRadius: BorderRadius.all(
          Radius.circular(AppSizes.selectionFieldRadius),
        ),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.info_outline,
            size: AppSizes.matchCardIconSize,
            color: AppColors.primary,
          ),
          SizedBox(width: AppSizes.scoreHeaderSpacing),
          Expanded(
            child: Text(
              AppStrings.matchConfirmNotice,
              style: AppTextStyles.matchConfirmNotice,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActions() {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: onEdit,
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primary,
              minimumSize: const Size.fromHeight(AppSizes.primaryButtonHeight),
              side: const BorderSide(color: AppColors.primary),
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.all(
                  Radius.circular(AppSizes.primaryButtonRadius),
                ),
              ),
            ),
            icon: const Icon(Icons.edit_outlined),
            label: const Text(AppStrings.matchConfirmEdit),
          ),
        ),
        const SizedBox(height: AppSizes.scoreInputSpacing),
        PrimaryButton(
          label: AppStrings.matchConfirmRequest,
          icon: Icons.send_outlined,
          onPressed: onRequestConfirmation,
        ),
      ],
    );
  }
}
