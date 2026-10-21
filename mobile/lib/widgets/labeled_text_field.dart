import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import '../constants/app_sizes.dart';
import '../constants/app_strings.dart';
import '../constants/app_text_styles.dart';

/// ラベル付きのテキスト入力欄。入力値の保持は親Widgetが渡す controller に委譲する。
class LabeledTextField extends StatelessWidget {
  final String label;
  final String hint;
  final TextEditingController controller;
  final bool isRequired;
  final bool isMultiline;
  final String? errorText;
  final ValueChanged<String>? onChanged;

  const LabeledTextField({
    super.key,
    required this.label,
    required this.hint,
    required this.controller,
    this.isRequired = false,
    this.isMultiline = false,
    this.errorText,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    const border = OutlineInputBorder(
      borderRadius: BorderRadius.all(
        Radius.circular(AppSizes.selectionFieldRadius),
      ),
      borderSide: BorderSide(color: AppColors.borderLight),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text.rich(
          TextSpan(
            text: label,
            style: AppTextStyles.labeledTextFieldLabel,
            children: [
              if (isRequired)
                const TextSpan(
                  text: ' ${AppStrings.requiredMark}',
                  style: AppTextStyles.labeledTextFieldRequiredMark,
                ),
            ],
          ),
        ),
        const SizedBox(height: AppSizes.scoreHeaderSpacing),
        TextField(
          controller: controller,
          onChanged: onChanged,
          minLines:
              isMultiline ? AppSizes.labeledTextFieldMultilineMinLines : 1,
          maxLines: isMultiline ? AppSizes.labeledTextFieldMultilineMaxLines : 1,
          textInputAction:
              isMultiline ? TextInputAction.newline : TextInputAction.next,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: AppTextStyles.labeledTextFieldHint,
            errorText: errorText,
            filled: true,
            fillColor: AppColors.cardBackground,
            border: border,
            enabledBorder: border,
            contentPadding: const EdgeInsets.all(AppSizes.selectionFieldPadding),
          ),
        ),
      ],
    );
  }
}
