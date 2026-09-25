import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import '../constants/app_sizes.dart';
import '../constants/app_strings.dart';
import '../constants/app_text_styles.dart';

/// 個人メモの入力と保存操作だけを提供し、保存処理は親Widgetへ委譲する。
class MatchMemoField extends StatefulWidget {
  final String initialValue;
  final bool isSaving;
  final String? errorMessage;
  final ValueChanged<String> onSave;

  const MatchMemoField({
    super.key,
    this.initialValue = '',
    this.isSaving = false,
    this.errorMessage,
    required this.onSave,
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
        if (widget.errorMessage != null && widget.errorMessage!.isNotEmpty) ...[
          const SizedBox(height: AppSizes.scoreHeaderSpacing),
          Text(
            widget.errorMessage!,
            style: AppTextStyles.matchMemoError,
          ),
        ],
        const SizedBox(height: AppSizes.scoreSectionSpacing),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed:
                widget.isSaving ? null : () => widget.onSave(_controller.text),
            child: widget.isSaving
                ? const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox.square(
                        dimension: AppSizes.matchMemoProgressSize,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      SizedBox(width: AppSizes.spacingMedium),
                      Text(AppStrings.matchMemoSaving),
                    ],
                  )
                : const Text(AppStrings.matchMemoSave),
          ),
        ),
      ],
    );
  }
}
