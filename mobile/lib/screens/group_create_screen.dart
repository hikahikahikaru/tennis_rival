import 'package:flutter/material.dart';

import '../constants/app_sizes.dart';
import '../constants/app_strings.dart';
import '../constants/app_text_styles.dart';
import '../repositories/group_repository.dart';
import '../services/group_service.dart';
import '../widgets/labeled_text_field.dart';
import '../widgets/primary_button.dart';

/// グループの入力と作成処理の状態を管理する画面。
class GroupCreateScreen extends StatefulWidget {
  final GroupService? groupService;

  const GroupCreateScreen({super.key, this.groupService});

  @override
  State<GroupCreateScreen> createState() => _GroupCreateScreenState();
}

class _GroupCreateScreenState extends State<GroupCreateScreen> {
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  var _showNameError = false;
  var _isSaving = false;
  String? _saveError;

  GroupService get _groupService =>
      widget.groupService ?? GroupService.instance;

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _handleCreatePressed() async {
    if (_isSaving) return;
    final isNameEmpty = _nameController.text.trim().isEmpty;
    setState(() {
      _showNameError = isNameEmpty;
      _saveError = null;
    });
    if (isNameEmpty) {
      return;
    }

    setState(() => _isSaving = true);
    try {
      final description = _descriptionController.text.trim();
      final groupId = await _groupService.createGroup(
        name: _nameController.text.trim(),
        description: description.isEmpty ? null : description,
      );
      if (!mounted) return;
      Navigator.pop(context, groupId);
    } on GroupAuthenticationRequiredException {
      if (!mounted) return;
      setState(() {
        _isSaving = false;
        _saveError = AppStrings.groupAuthenticationRequired;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isSaving = false;
        _saveError = AppStrings.groupCreateFailed;
      });
    }
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
                      if (_saveError != null) ...[
                        const SizedBox(height: AppSizes.spacingMedium),
                        Text(
                          _saveError!,
                          style: AppTextStyles.groupFormError,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSizes.spacingMedium),
              AbsorbPointer(
                absorbing: _isSaving,
                child: PrimaryButton(
                  label: _isSaving
                      ? AppStrings.groupCreating
                      : AppStrings.groupCreateTitle,
                  onPressed: _handleCreatePressed,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
