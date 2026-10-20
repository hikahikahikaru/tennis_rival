import 'package:flutter/material.dart';

import '../constants/app_sizes.dart';
import '../constants/app_strings.dart';
import '../constants/app_text_styles.dart';
import '../widgets/labeled_text_field.dart';
import '../widgets/primary_button.dart';

/// グループ作成画面。DB連携は別issueのため、現在は入力と必須チェックのみ行う。
class GroupCreateScreen extends StatefulWidget {
  const GroupCreateScreen({super.key});

  @override
  State<GroupCreateScreen> createState() => _GroupCreateScreenState();
}

class _GroupCreateScreenState extends State<GroupCreateScreen> {
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  var _showNameError = false;

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _handleCreatePressed() {
    final isNameEmpty = _nameController.text.trim().isEmpty;
    setState(() => _showNameError = isNameEmpty);
    if (isNameEmpty) {
      return;
    }

    // 作成処理は別issueで実装する。
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      const SnackBar(content: Text(AppStrings.groupCreateUnavailable)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.groupCreateTitle),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSizes.screenPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 入力欄だけをスクロールさせ、作成ボタンは下に固定する。
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      LabeledTextField(
                        label: AppStrings.groupNameLabel,
                        hint: AppStrings.groupNameHint,
                        controller: _nameController,
                        isRequired: true,
                        errorText: _showNameError
                            ? AppStrings.groupNameRequired
                            : null,
                        onChanged: (_) {
                          if (_showNameError) {
                            setState(() => _showNameError = false);
                          }
                        },
                      ),
                      const SizedBox(height: AppSizes.scoreSectionSpacing),
                      LabeledTextField(
                        label: AppStrings.groupDescriptionLabel,
                        hint: AppStrings.groupDescriptionHint,
                        controller: _descriptionController,
                        isMultiline: true,
                      ),
                      const SizedBox(height: AppSizes.spacingMedium),
                      const Text(
                        AppStrings.groupCreateNote,
                        style: AppTextStyles.groupCreateNote,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSizes.spacingMedium),
              PrimaryButton(
                label: AppStrings.groupCreateTitle,
                onPressed: _handleCreatePressed,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
