import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import '../constants/app_sizes.dart';
import '../constants/app_strings.dart';
import '../constants/app_text_styles.dart';
import '../widgets/labeled_text_field.dart';
import '../widgets/primary_button.dart';

enum SignUpSubmissionStatus {
  emailConfirmationRequired,
  completed,
  failed,
  networkError,
}

/// UIがAuth実装の具体型に依存せず、登録結果を表示するための値。
class SignUpSubmissionResult {
  final SignUpSubmissionStatus status;

  const SignUpSubmissionResult(this.status);
}

typedef SignUpSubmitCallback = Future<SignUpSubmissionResult> Function({
  required String displayName,
  required String email,
  required String password,
  required String confirmPassword,
});

/// アカウント登録の入力・検証・表示状態だけを担当する画面。
class SignUpScreen extends StatefulWidget {
  final SignUpSubmitCallback onSubmit;
  final VoidCallback? onLoginPressed;

  const SignUpScreen({
    super.key,
    required this.onSubmit,
    this.onLoginPressed,
  });

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

enum _SignUpField { displayName, email, password, confirmPassword }

class _SignUpScreenState extends State<SignUpScreen> {
  static final RegExp _emailPattern = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');

  final _displayNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  Map<_SignUpField, String> _fieldErrors = const {};
  SignUpSubmissionStatus? _submissionStatus;
  var _isSubmitting = false;
  var _obscurePassword = true;
  var _obscureConfirmPassword = true;

  @override
  void dispose() {
    _displayNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_isSubmitting) return;

    final displayName = _displayNameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final confirmPassword = _confirmPasswordController.text;
    final errors = _validate(
      displayName: displayName,
      email: email,
      password: password,
      confirmPassword: confirmPassword,
    );
    setState(() {
      _fieldErrors = errors;
      _submissionStatus = null;
    });
    if (errors.isNotEmpty) return;

    setState(() => _isSubmitting = true);
    try {
      final result = await widget.onSubmit(
        displayName: displayName,
        email: email,
        password: password,
        confirmPassword: confirmPassword,
      );
      if (!mounted) return;
      setState(() {
        _isSubmitting = false;
        _submissionStatus = result.status;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isSubmitting = false;
        _submissionStatus = SignUpSubmissionStatus.failed;
      });
    }
  }

  Map<_SignUpField, String> _validate({
    required String displayName,
    required String email,
    required String password,
    required String confirmPassword,
  }) {
    final errors = <_SignUpField, String>{};
    if (displayName.isEmpty) {
      errors[_SignUpField.displayName] = AppStrings.signUpDisplayNameRequired;
    }
    if (email.isEmpty) {
      errors[_SignUpField.email] = AppStrings.signUpEmailRequired;
    } else if (!_emailPattern.hasMatch(email)) {
      errors[_SignUpField.email] = AppStrings.signUpEmailInvalid;
    }
    if (password.length < 8) {
      errors[_SignUpField.password] = AppStrings.signUpPasswordTooShort;
    }
    if (confirmPassword.isEmpty) {
      errors[_SignUpField.confirmPassword] =
          AppStrings.signUpConfirmPasswordRequired;
    } else if (password != confirmPassword) {
      errors[_SignUpField.confirmPassword] = AppStrings.signUpPasswordMismatch;
    }
    return errors;
  }

  void _clearError(_SignUpField field) {
    if (!_fieldErrors.containsKey(field) && _submissionStatus == null) return;
    setState(() {
      _fieldErrors = Map.of(_fieldErrors)..remove(field);
      _submissionStatus = null;
    });
  }

  Widget _passwordVisibilityButton({
    required bool obscureText,
    required VoidCallback onPressed,
  }) {
    return IconButton(
      tooltip: obscureText
          ? AppStrings.signUpPasswordShow
          : AppStrings.signUpPasswordHide,
      onPressed: onPressed,
      icon: Icon(obscureText ? Icons.visibility : Icons.visibility_off),
    );
  }

  String? get _feedbackMessage {
    switch (_submissionStatus) {
      case SignUpSubmissionStatus.emailConfirmationRequired:
        return AppStrings.signUpConfirmationPending;
      case SignUpSubmissionStatus.completed:
        return AppStrings.signUpCompleted;
      case SignUpSubmissionStatus.failed:
        return AppStrings.signUpFailed;
      case SignUpSubmissionStatus.networkError:
        return AppStrings.signUpNetworkError;
      case null:
        return null;
    }
  }

  bool get _isSuccessful =>
      _submissionStatus == SignUpSubmissionStatus.emailConfirmationRequired ||
      _submissionStatus == SignUpSubmissionStatus.completed;

  String get _submitButtonLabel {
    if (_isSubmitting) return AppStrings.signUpSubmitting;
    switch (_submissionStatus) {
      case SignUpSubmissionStatus.emailConfirmationRequired:
        return AppStrings.signUpCheckEmail;
      case SignUpSubmissionStatus.completed:
        return AppStrings.signUpCompletedButton;
      case SignUpSubmissionStatus.failed:
      case SignUpSubmissionStatus.networkError:
      case null:
        return AppStrings.signUpSubmit;
    }
  }

  @override
  Widget build(BuildContext context) {
    final feedbackMessage = _feedbackMessage;

    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.appName)),
      body: SafeArea(
        // キーボード表示時も入力欄と操作をたどれるよう画面全体をスクロールさせる。
        child: SingleChildScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: EdgeInsets.fromLTRB(
            AppSizes.screenPadding,
            AppSizes.screenPadding,
            AppSizes.screenPadding,
            AppSizes.screenPadding + MediaQuery.viewInsetsOf(context).bottom,
          ),
          child: AutofillGroup(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  AppStrings.signUpTitle,
                  style: AppTextStyles.signUpTitle,
                ),
                const SizedBox(height: AppSizes.spacingSmall),
                const Text(
                  AppStrings.signUpDescription,
                  style: AppTextStyles.signUpDescription,
                ),
                const SizedBox(height: AppSizes.spacingLarge),
                LabeledTextField(
                  label: AppStrings.signUpDisplayNameLabel,
                  hint: AppStrings.signUpDisplayNameHint,
                  controller: _displayNameController,
                  isRequired: true,
                  errorText: _fieldErrors[_SignUpField.displayName],
                  autofillHints: const [AutofillHints.name],
                  enabled: !_isSubmitting && !_isSuccessful,
                  onChanged: (_) => _clearError(_SignUpField.displayName),
                ),
                const SizedBox(height: AppSizes.scoreSectionSpacing),
                LabeledTextField(
                  label: AppStrings.signUpEmailLabel,
                  hint: AppStrings.signUpEmailHint,
                  controller: _emailController,
                  isRequired: true,
                  errorText: _fieldErrors[_SignUpField.email],
                  keyboardType: TextInputType.emailAddress,
                  autofillHints: const [AutofillHints.email],
                  enabled: !_isSubmitting && !_isSuccessful,
                  onChanged: (_) => _clearError(_SignUpField.email),
                ),
                const SizedBox(height: AppSizes.scoreSectionSpacing),
                LabeledTextField(
                  label: AppStrings.signUpPasswordLabel,
                  hint: AppStrings.signUpPasswordHint,
                  controller: _passwordController,
                  isRequired: true,
                  errorText: _fieldErrors[_SignUpField.password],
                  obscureText: _obscurePassword,
                  autofillHints: const [AutofillHints.newPassword],
                  enabled: !_isSubmitting && !_isSuccessful,
                  suffixIcon: _passwordVisibilityButton(
                    obscureText: _obscurePassword,
                    onPressed: () => setState(
                      () => _obscurePassword = !_obscurePassword,
                    ),
                  ),
                  onChanged: (_) => _clearError(_SignUpField.password),
                ),
                const SizedBox(height: AppSizes.scoreSectionSpacing),
                LabeledTextField(
                  label: AppStrings.signUpConfirmPasswordLabel,
                  hint: AppStrings.signUpConfirmPasswordHint,
                  controller: _confirmPasswordController,
                  isRequired: true,
                  errorText: _fieldErrors[_SignUpField.confirmPassword],
                  obscureText: _obscureConfirmPassword,
                  autofillHints: const [AutofillHints.newPassword],
                  enabled: !_isSubmitting && !_isSuccessful,
                  textInputAction: TextInputAction.done,
                  suffixIcon: _passwordVisibilityButton(
                    obscureText: _obscureConfirmPassword,
                    onPressed: () => setState(
                      () => _obscureConfirmPassword = !_obscureConfirmPassword,
                    ),
                  ),
                  onChanged: (_) => _clearError(_SignUpField.confirmPassword),
                ),
                if (feedbackMessage != null) ...[
                  const SizedBox(height: AppSizes.spacingMedium),
                  Semantics(
                    liveRegion: true,
                    child: Text(
                      feedbackMessage,
                      style: AppTextStyles.signUpFeedback.copyWith(
                        color: _isSuccessful
                            ? AppColors.primary
                            : AppColors.requiredMark,
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: AppSizes.spacingLarge),
                PrimaryButton(
                  label: _submitButtonLabel,
                  onPressed: _isSubmitting || _isSuccessful ? null : _submit,
                ),
                const SizedBox(height: AppSizes.spacingMedium),
                TextButton(
                  onPressed: _isSubmitting ? null : widget.onLoginPressed,
                  child: const Text(AppStrings.signUpLoginPrompt),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
