import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import '../constants/app_sizes.dart';
import '../constants/app_strings.dart';
import '../constants/app_text_styles.dart';

/// 個人メモの入力UIを提供し、入力値の保持や保存処理は親Widgetへ委譲する。
class MatchMemoField extends StatefulWidget {
  final String initialValue;
  final ValueChanged<String> onChanged;

  const MatchMemoField({
    super.key,
    this.initialValue = '',
    required this.onChanged,
  });

  @override
  State<MatchMemoField> createState() => _MatchMemoFieldState();
}

class _MatchMemoFieldState extends State<MatchMemoField> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
  }

  @override
  void didUpdateWidget(covariant MatchMemoField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialValue != oldWidget.initialValue &&
        widget.initialValue != _controller.text) {
      _controller.value = TextEditingValue(
        text: widget.initialValue,
        selection: TextSelection.collapsed(offset: widget.initialValue.length),
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          AppStrings.matchConfirmMemo,
          style: AppTextStyles.scoreSectionTitle,
        ),
        const SizedBox(height: AppSizes.scoreHeaderSpacing),
        TextField(
          controller: _controller,
          onChanged: widget.onChanged,
          minLines: AppSizes.matchMemoMinLines,
          maxLines: AppSizes.matchMemoMaxLines,
          textInputAction: TextInputAction.newline,
          decoration: const InputDecoration(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.all(
                Radius.circular(AppSizes.selectionFieldRadius),
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.all(
                Radius.circular(AppSizes.selectionFieldRadius),
              ),
              borderSide: BorderSide(color: AppColors.borderLight),
            ),
            contentPadding: EdgeInsets.symmetric(
              horizontal: AppSizes.selectionFieldPadding,
              vertical: AppSizes.selectionFieldPadding,
            ),
          ),
        ),
      ],
    );
  }
}
