import 'package:flutter/material.dart';

import '../constants/app_sizes.dart';
import '../constants/app_strings.dart';
import '../widgets/info_box.dart';
import '../widgets/labeled_text_field.dart';
import '../widgets/primary_button.dart';

/// グループ参加画面。DB連携は別issueのため、現在は入力と必須チェックのみ行う。
class GroupJoinScreen extends StatefulWidget {
  const GroupJoinScreen({super.key});

  @override
  State<GroupJoinScreen> createState() => _GroupJoinScreenState();
}

class _GroupJoinScreenState extends State<GroupJoinScreen> {
  final _nameController = TextEditingController();
  final _inviteCodeController = TextEditingController();
  var _showNameError = false;
  var _showInviteCodeError = false;

  @override
  void dispose() {
    _nameController.dispose();
    _inviteCodeController.dispose();
    super.dispose();
  }

  void _handleJoinPressed() {
    final isNameEmpty = _nameController.text.trim().isEmpty;
    final isInviteCodeEmpty = _inviteCodeController.text.trim().isEmpty;
    setState(() {
      _showNameError = isNameEmpty;
      _showInviteCodeError = isInviteCodeEmpty;
    });
    if (isNameEmpty || isInviteCodeEmpty) {
      return;
    }

    // 参加処理は別issueで実装する。
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      const SnackBar(content: Text(AppStrings.groupJoinUnavailable)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.groupJoinTitle),
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
              // 入力欄だけをスクロールさせ、参加ボタンは下に固定する。
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
                        label: AppStrings.groupInviteCodeLabel,
                        hint: AppStrings.groupInviteCodeHint,
                        controller: _inviteCodeController,
                        isRequired: true,
                        errorText: _showInviteCodeError
                            ? AppStrings.groupInviteCodeRequired
                            : null,
                        onChanged: (_) {
                          if (_showInviteCodeError) {
                            setState(() => _showInviteCodeError = false);
                          }
                        },
                      ),
                      const SizedBox(height: AppSizes.spacingLarge),
                      const InfoBox(
                        title: AppStrings.groupInviteCodeInfoTitle,
                        body: AppStrings.groupInviteCodeInfoBody,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSizes.spacingMedium),
              PrimaryButton(
                label: AppStrings.groupJoin,
                onPressed: _handleJoinPressed,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
