import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../constants/app_colors.dart';
import '../constants/app_sizes.dart';
import '../constants/app_strings.dart';
import '../constants/app_text_styles.dart';
import '../models/match_format.dart';
import '../models/match_set_score.dart';
import '../models/user_model.dart';
import '../widgets/match_date_picker.dart';
import '../widgets/opponent_picker_sheet.dart';
import '../widgets/primary_button.dart';
import '../widgets/score_input_section.dart';
import '../widgets/selection_field.dart';
import 'match_confirm_screen.dart';
import 'request_sent_screen.dart';

class MatchEntryScreen extends StatefulWidget {
  const MatchEntryScreen({super.key});

  @override
  State<MatchEntryScreen> createState() => _MatchEntryScreenState();
}

class _MatchEntryScreenState extends State<MatchEntryScreen> {
  DateTime _selectedDate = DateTime.now();
  UserModel? _selectedOpponentUser;
  MatchFormat _selectedFormat = MatchFormat.threeSets;

  /// 選択中の対戦相手の表示名（未選択時は「未選択」）
  String get _selectedOpponent =>
      _selectedOpponentUser?.name ?? AppStrings.unselected;

  // ControllerはScoreInputSection内に閉じ込め、確認画面へ渡すのは入力値のスナップショットだけにする。
  List<MatchSetScore>? _confirmSetScores;

  // カレンダー部品を呼び出す処理
  Future<void> _handleDateSelection() async {
    final picked = await MatchDatePicker.show(context, _selectedDate);
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  // 対戦相手選択シートを呼び出し、選択結果を画面状態に反映する処理
  Future<void> _handleOpponentSelection() async {
    final picked = await OpponentPickerSheet.show(context);
    if (picked != null) {
      setState(() {
        _selectedOpponentUser = picked;
      });
    }
  }

  void _showScoreRequiredMessage() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(AppStrings.matchEntryScoreRequired),
      ),
    );
  }

  void _handleScoresChanged(List<MatchSetScore>? setScores) {
    _confirmSetScores = setScores;
  }

  // 入力済みスコアを確認画面へ渡し、確認画面側のcallbackで以降の遷移を制御する。
  void _handleConfirmPressed() {
    final setScores = _confirmSetScores;
    if (setScores == null) {
      _showScoreRequiredMessage();
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (confirmContext) => MatchConfirmScreen(
          matchDate: _selectedDate,
          opponentName: _selectedOpponent,
          matchFormat: _selectedFormat,
          setScores: setScores,
          onEdit: () => Navigator.pop(confirmContext),
          onRequestConfirmation: () {
            Navigator.push(
              confirmContext,
              MaterialPageRoute(
                builder: (requestSentContext) => RequestSentScreen(
                  opponentName: _selectedOpponent,
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final String formattedDate = DateFormat('yyyy年M月d日').format(_selectedDate);

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.recordMatch),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSizes.screenPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              AppStrings.matchInfo,
              style: AppTextStyles.matchInfoTitle,
            ),
            const SizedBox(height: AppSizes.scoreSectionSpacing),
            SelectionField(
              title: AppStrings.matchDate,
              value: formattedDate,
              icon: Icons.calendar_today,
              onTap: _handleDateSelection, // 切り出した処理を呼ぶだけ
            ),
            const SizedBox(height: AppSizes.scoreSectionSpacing),
            SelectionField(
              title: AppStrings.opponent,
              value: _selectedOpponent,
              icon: Icons.person_search,
              // 切り出した対戦相手選択処理を呼び出す
              onTap: _handleOpponentSelection,
            ),
            const SizedBox(height: AppSizes.scoreSectionSpacing),
            const Text(
              AppStrings.matchFormat,
              style: AppTextStyles.selectionFieldTitle,
            ),
            const SizedBox(height: AppSizes.scoreHeaderSpacing),
            SizedBox(
              width: double.infinity,
              child: SegmentedButton<MatchFormat>(
                segments: [
                  ButtonSegment(
                    value: MatchFormat.oneSet,
                    label: Text(MatchFormat.oneSet.label),
                  ),
                  ButtonSegment(
                    value: MatchFormat.threeSets,
                    label: Text(MatchFormat.threeSets.label),
                  ),
                ],
                selected: {_selectedFormat},
                onSelectionChanged: (Set<MatchFormat> newSelection) {
                  setState(() {
                    _selectedFormat = newSelection.first;
                    _confirmSetScores = null;
                  });
                },
                style: SegmentedButton.styleFrom(
                  selectedBackgroundColor: AppColors.primary,
                  selectedForegroundColor: AppColors.primaryText,
                ),
                showSelectedIcon: false,
              ),
            ),
            const SizedBox(height: AppSizes.scoreSectionSpacing),
            ScoreInputSection(
              matchFormat: _selectedFormat,
              onScoresChanged: _handleScoresChanged,
            ),
            const SizedBox(height: AppSizes.spacingLarge),
            PrimaryButton(
              label: AppStrings.matchConfirmTitle,
              onPressed: _handleConfirmPressed,
            ),
          ],
        ),
      ),
    );
  }
}
