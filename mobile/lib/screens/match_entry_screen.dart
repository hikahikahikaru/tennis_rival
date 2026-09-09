import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../constants/app_colors.dart';
import '../constants/app_sizes.dart';
import '../constants/app_strings.dart';
import '../constants/app_text_styles.dart';

import '../models/match_format.dart';
import '../models/match_set_score.dart';

import '../widgets/primary_button.dart';
import '../widgets/match_date_picker.dart';
import '../widgets/opponent_picker_sheet.dart';
import '../widgets/score_input_row.dart';
import '../widgets/selection_field.dart';
import 'match_confirm_screen.dart';
import 'request_sent_screen.dart';

class MatchEntryScreen extends StatefulWidget {
  const MatchEntryScreen({super.key});

  @override
  State<MatchEntryScreen> createState() => _MatchEntryScreenState();
}

//TODO リファクタリング必要
class _MatchEntryScreenState extends State<MatchEntryScreen> {
  DateTime _selectedDate = DateTime.now();
  String _selectedOpponent = '未選択';
  MatchFormat _selectedFormat = MatchFormat.threeSets;

  // 親が管理するコントローラ群（モデルの setCount を参照して用意）
  late final List<TextEditingController> _myScoreControllers;
  late final List<TextEditingController> _opponentScoreControllers;
  late final List<TextEditingController> _myTiebreakerControllers;
  late final List<TextEditingController> _opponentTiebreakerControllers;

  @override
  void initState() {
    super.initState();
    final maxSets = MatchFormat.threeSets.setCount;
    _myScoreControllers =
        List.generate(maxSets, (_) => TextEditingController());
    _opponentScoreControllers =
        List.generate(maxSets, (_) => TextEditingController());
    _myTiebreakerControllers =
        List.generate(maxSets, (_) => TextEditingController());
    _opponentTiebreakerControllers =
        List.generate(maxSets, (_) => TextEditingController());
  }

  @override
  void dispose() {
    for (final controller in _myScoreControllers) {
      controller.dispose();
    }
    for (final controller in _opponentScoreControllers) {
      controller.dispose();
    }
    for (final controller in _myTiebreakerControllers) {
      controller.dispose();
    }
    for (final controller in _opponentTiebreakerControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  // カレンダー部品を呼び出す処理
  Future<void> _handleDateSelection() async {
    final picked = await MatchDatePicker.show(context, _selectedDate);
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  int? _parseOptionalScore(TextEditingController controller) {
    final value = controller.text.trim();
    if (value.isEmpty) {
      return null;
    }

    return int.tryParse(value);
  }

  List<MatchSetScore>? _buildConfirmSetScores() {
    final setScores = <MatchSetScore>[];
    final setsRequiredToWin = (_selectedFormat.setCount ~/ 2) + 1;
    var myWonSetCount = 0;
    var opponentWonSetCount = 0;

    for (var i = 0; i < _selectedFormat.setCount; i++) {
      final myScore = int.tryParse(_myScoreControllers[i].text.trim());
      final opponentScore =
          int.tryParse(_opponentScoreControllers[i].text.trim());

      if (myScore == null || opponentScore == null) {
        return null;
      }

      final setScore = MatchSetScore(
        myScore: myScore,
        opponentScore: opponentScore,
        myTiebreakScore: _parseOptionalScore(_myTiebreakerControllers[i]),
        opponentTiebreakScore:
            _parseOptionalScore(_opponentTiebreakerControllers[i]),
      );
      setScores.add(setScore);

      if (myScore == opponentScore) {
        continue;
      }

      if (setScore.isMyWin) {
        myWonSetCount++;
      } else {
        opponentWonSetCount++;
      }

      if (myWonSetCount >= setsRequiredToWin ||
          opponentWonSetCount >= setsRequiredToWin) {
        return setScores;
      }
    }

    return null;
  }

  void _showScoreRequiredMessage() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(AppStrings.matchEntryScoreRequired),
      ),
    );
  }

  void _handleConfirmPressed() {
    final setScores = _buildConfirmSetScores();
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
        title: const Text('試合結果を記録'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              AppStrings.matchInfo,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            SelectionField(
              title: AppStrings.matchDate,
              value: formattedDate,
              icon: Icons.calendar_today,
              onTap: _handleDateSelection, // 切り出した処理を呼ぶだけ
            ),
            const SizedBox(height: 16),
            SelectionField(
              title: AppStrings.opponent,
              value: _selectedOpponent,
              icon: Icons.person_search,
              // シートを呼び出すだけ（setStateは将来、相手を選んでから実装）
              onTap: () => OpponentPickerSheet.show(context),
            ),
            const SizedBox(height: 16),
            const Text(
              AppStrings.matchFormat,
              style: TextStyle(fontSize: 12, color: Colors.black54),
            ),
            const SizedBox(height: 8),
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
                  });
                },
                style: SegmentedButton.styleFrom(
                  selectedBackgroundColor: AppColors.primary,
                  selectedForegroundColor: Colors.white,
                ),
                showSelectedIcon: false,
              ),
            ),
            const SizedBox(height: AppSizes.scoreSectionSpacing),
            const Text(
              AppStrings.scoreSectionTitle,
              style: AppTextStyles.scoreSectionTitle,
            ),
            const SizedBox(height: AppSizes.scoreHeaderSpacing),
            // ヘッダー（自分 / 相手）を一度だけ表示
            const Row(
              children: [
                SizedBox(width: AppSizes.scoreSetLabelWidth),
                SizedBox(width: AppSizes.scoreInputSpacing),
                Expanded(
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          AppStrings.scoreMy,
                          style: AppTextStyles.scoreInputHeader,
                          textAlign: TextAlign.center,
                        ),
                      ),
                      SizedBox(width: AppSizes.scoreInputSpacing),
                      Expanded(
                        child: Text(
                          AppStrings.scoreOpponent,
                          style: AppTextStyles.scoreInputHeader,
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSizes.scoreHeaderSpacing),
            // スコア行の数を切り替え（モデルの setCount を参照）
            ...List.generate(
              _selectedFormat.setCount,
              (i) => ScoreInputRow(
                setNumber: i + 1,
                myScoreController: _myScoreControllers[i],
                opponentScoreController: _opponentScoreControllers[i],
                myTiebreakerController: _myTiebreakerControllers[i],
                opponentTiebreakerController: _opponentTiebreakerControllers[i],
              ),
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
