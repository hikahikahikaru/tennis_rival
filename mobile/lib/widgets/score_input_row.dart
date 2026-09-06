import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../constants/app_colors.dart';
import '../constants/app_sizes.dart';
import '../constants/app_strings.dart';
import '../constants/app_text_styles.dart';

/// 単一セット分のスコア入力行。選択式UI（ボトムシート + ダイアログ）により、
/// 親が所有する TextEditingController に値を設定する。
class ScoreInputRow extends StatefulWidget {
  final int setNumber;
  final TextEditingController myScoreController;
  final TextEditingController opponentScoreController;
  final TextEditingController myTiebreakerController;
  final TextEditingController opponentTiebreakerController;

  const ScoreInputRow({
    super.key,
    required this.setNumber,
    required this.myScoreController,
    required this.opponentScoreController,
    required this.myTiebreakerController,
    required this.opponentTiebreakerController,
  });

  @override
  State<ScoreInputRow> createState() => _ScoreInputRowState();
}

class _ScoreInputRowState extends State<ScoreInputRow> {
  // 親の Controller を参照しながら、タイブレーク表示判定用に本ウィジェットで追跡
  bool _showTiebreaker = false;
  bool _isUpdatingScoreController = false;

  @override
  void initState() {
    super.initState();
    // 初期状態でタイブレーク表示判定
    _syncTiebreakerVisibility();
    // リスナー登録（値変更時に再判定）
    widget.myScoreController.addListener(_updateTiebreakerVisibility);
    widget.opponentScoreController.addListener(_updateTiebreakerVisibility);
  }

  @override
  void dispose() {
    widget.myScoreController.removeListener(_updateTiebreakerVisibility);
    widget.opponentScoreController.removeListener(_updateTiebreakerVisibility);
    super.dispose();
  }

  void _updateTiebreakerVisibility() {
    if (!mounted || _isUpdatingScoreController) {
      return;
    }

    setState(_syncTiebreakerVisibility);
  }

  void _syncTiebreakerVisibility() {
    final myScore = int.tryParse(widget.myScoreController.text) ?? 0;
    final opponentScore =
        int.tryParse(widget.opponentScoreController.text) ?? 0;
    final shouldShow = (myScore == 7 && opponentScore == 6) ||
        (myScore == 6 && opponentScore == 7);

    _showTiebreaker = shouldShow;

    // スコアが 7-6 または 6-7 ではなくなった場合、タイブレーク値をクリア
    if (!shouldShow) {
      widget.myTiebreakerController.clear();
      widget.opponentTiebreakerController.clear();
    }
  }

  void _setScoreControllerText(
    TextEditingController controller,
    String value, {
    required bool isTiebreaker,
  }) {
    if (!mounted) {
      return;
    }

    _isUpdatingScoreController = true;
    try {
      setState(() {
        controller.text = value;
        if (!isTiebreaker) {
          _syncTiebreakerVisibility();
        }
      });
    } finally {
      _isUpdatingScoreController = false;
    }
  }

  void _clearScoreController(
    TextEditingController controller, {
    required bool isTiebreaker,
  }) {
    if (!mounted) {
      return;
    }

    _isUpdatingScoreController = true;
    try {
      setState(() {
        controller.clear();
        if (!isTiebreaker) {
          _syncTiebreakerVisibility();
        }
      });
    } finally {
      _isUpdatingScoreController = false;
    }
  }

  Future<void> _showScoreBottomSheet(
    TextEditingController controller, {
    required bool isTiebreaker,
  }) async {
    await showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppSizes.bottomSheetRadius),
        ),
      ),
      builder: (BuildContext bottomSheetContext) {
        return SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSizes.scoreBottomSheetPadding),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: AppSizes.scoreNumberWrapSpacing,
                  runSpacing: AppSizes.scoreNumberWrapRunSpacing,
                  children: List.generate(
                    11,
                    (index) => _buildScoreNumberButton(
                      label: '$index',
                      onTap: () {
                        _setScoreControllerText(
                          controller,
                          '$index',
                          isTiebreaker: isTiebreaker,
                        );
                        Navigator.pop(bottomSheetContext);
                      },
                    ),
                  ),
                ),
                const SizedBox(height: AppSizes.scoreInputSpacing),
                Row(
                  children: [
                    Expanded(
                      child: _buildBottomSheetOption(
                        label: AppStrings.scoreClear,
                        onTap: () {
                          _clearScoreController(
                            controller,
                            isTiebreaker: isTiebreaker,
                          );
                          Navigator.pop(bottomSheetContext);
                        },
                      ),
                    ),
                    const SizedBox(width: AppSizes.scoreInputSpacing),
                    Expanded(
                      child: _buildBottomSheetOption(
                        label: AppStrings.scoreOther,
                        onTap: () {
                          Navigator.pop(bottomSheetContext);
                          _showScoreInputDialog(
                            controller,
                            isTiebreaker: isTiebreaker,
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _showScoreInputDialog(
    TextEditingController controller, {
    required bool isTiebreaker,
  }) async {
    final textController = TextEditingController(text: controller.text);

    try {
      await showDialog<void>(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('スコアを入力'),
            content: TextField(
              controller: textController,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'スコア',
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: const Text('キャンセル'),
              ),
              TextButton(
                onPressed: () {
                  if (textController.text.isNotEmpty) {
                    _setScoreControllerText(
                      controller,
                      textController.text,
                      isTiebreaker: isTiebreaker,
                    );
                  }
                  Navigator.pop(context);
                },
                child: const Text('OK'),
              ),
            ],
          );
        },
      );
    } finally {
      textController.dispose();
    }
  }

  Widget _buildBottomSheetOption({
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: AppSizes.scoreBottomSheetOptionHeight,
        alignment: Alignment.center,
        child: Text(
          label,
          style: AppTextStyles.scoreBottomSheetOption,
        ),
      ),
    );
  }

  Widget _buildScoreNumberButton({
    required String label,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      width: AppSizes.scoreNumberButtonWidth,
      height: AppSizes.scoreNumberButtonHeight,
      child: OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.matchOpponentText,
          padding: EdgeInsets.zero,
          side: const BorderSide(color: AppColors.borderLight),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSizes.selectionFieldRadius),
          ),
          textStyle: AppTextStyles.scoreBottomSheetOption,
        ),
        child: Text(label),
      ),
    );
  }

  Widget _buildScoreField(
    TextEditingController controller, {
    bool isTiebreaker = false,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: () => _showScoreBottomSheet(
          controller,
          isTiebreaker: isTiebreaker,
        ),
        child: Container(
          padding: const EdgeInsets.symmetric(
            vertical: AppSizes.scoreInputVerticalPadding,
            horizontal: AppSizes.scoreInputHorizontalPadding,
          ),
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.borderLight),
            borderRadius: BorderRadius.circular(AppSizes.selectionFieldRadius),
          ),
          child: Text(
            controller.text.isEmpty ? '-' : controller.text,
            textAlign: TextAlign.center,
            style: AppTextStyles.scoreInputValue,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 通常スコア行
        Padding(
          padding: const EdgeInsets.symmetric(
            vertical: AppSizes.scoreRowVerticalPadding,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(
                width: AppSizes.scoreSetLabelWidth,
                child: Text(
                  '${AppStrings.scoreSet}${widget.setNumber}',
                  style: AppTextStyles.scoreSetLabel,
                ),
              ),
              const SizedBox(width: AppSizes.scoreInputSpacing),
              Expanded(
                child: Row(
                  children: [
                    _buildScoreField(widget.myScoreController),
                    const SizedBox(width: AppSizes.scoreInputSpacing),
                    _buildScoreField(widget.opponentScoreController),
                  ],
                ),
              ),
            ],
          ),
        ),
        // タイブレーク行（7-6 または 6-7 の場合のみ表示）
        if (_showTiebreaker) ...[
          const SizedBox(height: AppSizes.scoreTiebreakerSpacing),
          Padding(
            padding: const EdgeInsets.symmetric(
              vertical: AppSizes.scoreRowVerticalPadding,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  AppStrings.scoreTiebreakerLabel,
                  style: AppTextStyles.scoreTiebreakerLabel,
                ),
                const SizedBox(height: 4),
                const Text(
                  AppStrings.scoreTiebreakerFormat,
                  style: AppTextStyles.scoreTiebreakerLabel,
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const SizedBox(width: AppSizes.scoreSetLabelWidth),
                    const SizedBox(width: AppSizes.scoreInputSpacing),
                    Expanded(
                      child: Row(
                        children: [
                          _buildScoreField(
                            widget.myTiebreakerController,
                            isTiebreaker: true,
                          ),
                          const SizedBox(width: AppSizes.scoreInputSpacing),
                          _buildScoreField(
                            widget.opponentTiebreakerController,
                            isTiebreaker: true,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}
