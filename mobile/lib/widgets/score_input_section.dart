import 'package:flutter/material.dart';

import '../constants/app_sizes.dart';
import '../constants/app_strings.dart';
import '../constants/app_text_styles.dart';
import '../models/match_format.dart';
import '../models/match_score.dart';
import '../models/match_set_score.dart';
import 'score_input_row.dart';

/// Controllerを内部管理し、試合として成立したスコアだけ親へ通知する。
class ScoreInputSection extends StatefulWidget {
  final MatchFormat matchFormat;
  final ValueChanged<List<MatchSetScore>?> onScoresChanged;

  const ScoreInputSection({
    super.key,
    required this.matchFormat,
    required this.onScoresChanged,
  });

  @override
  State<ScoreInputSection> createState() => _ScoreInputSectionState();
}

class _ScoreInputSectionState extends State<ScoreInputSection> {
  final List<TextEditingController> _myScoreControllers = [];
  final List<TextEditingController> _opponentScoreControllers = [];
  final List<TextEditingController> _myTiebreakerControllers = [];
  final List<TextEditingController> _opponentTiebreakerControllers = [];

  @override
  void initState() {
    super.initState();
    _ensureControllerCount(widget.matchFormat.setCount);
  }

  @override
  void didUpdateWidget(covariant ScoreInputSection oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.matchFormat != widget.matchFormat) {
      _ensureControllerCount(widget.matchFormat.setCount);
      // 親のbuild中に通知しないよう、形式変更後の再計算は次フレームに送る。
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) {
          return;
        }

        _notifyScoresChanged();
      });
    }
  }

  @override
  void dispose() {
    _disposeControllers(_myScoreControllers);
    _disposeControllers(_opponentScoreControllers);
    _disposeControllers(_myTiebreakerControllers);
    _disposeControllers(_opponentTiebreakerControllers);
    super.dispose();
  }

  TextEditingController _createScoreController() {
    return TextEditingController()..addListener(_notifyScoresChanged);
  }

  void _disposeControllers(List<TextEditingController> controllers) {
    for (final controller in controllers) {
      controller.removeListener(_notifyScoresChanged);
      controller.dispose();
    }
  }

  // matchFormat.setCountが減ってもControllerは破棄せず、形式を戻した際の入力値を保持する。
  void _ensureControllerCount(int count) {
    while (_myScoreControllers.length < count) {
      _myScoreControllers.add(_createScoreController());
      _opponentScoreControllers.add(_createScoreController());
      _myTiebreakerControllers.add(_createScoreController());
      _opponentTiebreakerControllers.add(_createScoreController());
    }
  }

  int? _parseOptionalScore(TextEditingController controller) {
    final value = controller.text.trim();
    if (value.isEmpty) {
      return null;
    }

    return int.tryParse(value);
  }

  MatchSetScore? _buildInputSetScore(int index) {
    final myScore = int.tryParse(_myScoreControllers[index].text.trim());
    final opponentScore =
        int.tryParse(_opponentScoreControllers[index].text.trim());

    if (myScore == null || opponentScore == null) {
      return null;
    }

    return MatchSetScore(
      myScore: myScore,
      opponentScore: opponentScore,
      myTiebreakScore: _parseOptionalScore(_myTiebreakerControllers[index]),
      opponentTiebreakScore:
          _parseOptionalScore(_opponentTiebreakerControllers[index]),
    );
  }

  List<MatchSetScore>? _buildConfirmSetScores() {
    final setScores = <MatchSetScore>[];

    for (var i = 0; i < widget.matchFormat.setCount; i++) {
      final setScore = _buildInputSetScore(i);
      if (setScore == null) {
        break;
      }

      setScores.add(setScore);
    }

    return MatchScore(
      matchFormat: widget.matchFormat,
      setScores: setScores,
    ).confirmedSetScores;
  }

  void _notifyScoresChanged() {
    widget.onScoresChanged(_buildConfirmSetScores());
  }

  Widget _buildScoreHeader() {
    return const Row(
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
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          AppStrings.scoreSectionTitle,
          style: AppTextStyles.scoreSectionTitle,
        ),
        const SizedBox(height: AppSizes.scoreHeaderSpacing),
        _buildScoreHeader(),
        const SizedBox(height: AppSizes.scoreHeaderSpacing),
        ...List.generate(
          widget.matchFormat.setCount,
          (i) => ScoreInputRow(
            setNumber: i + 1,
            myScoreController: _myScoreControllers[i],
            opponentScoreController: _opponentScoreControllers[i],
            myTiebreakerController: _myTiebreakerControllers[i],
            opponentTiebreakerController: _opponentTiebreakerControllers[i],
          ),
        ),
      ],
    );
  }
}
