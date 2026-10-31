import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import '../constants/app_sizes.dart';
import '../constants/app_strings.dart';
import '../constants/app_text_styles.dart';
import '../widgets/labeled_text_field.dart';
import '../widgets/primary_button.dart';

enum LoginSubmissionStatus { completed, failed, networkError, unexpectedError }

/// UIが将来のAuthServiceの具体型に依存せず、ログイン結果を表示するための値。
class LoginSubmissionResult {
  final LoginSubmissionStatus status;

  const LoginSubmissionResult(this.status);
}

typedef LoginSubmitCallback = Future<LoginSubmissionResult> Function({
  required String email,
  required String password,
});

/// ログインの入力・検証・表示状態だけを担当し、認証通信は親へ委譲する画面。
class LoginScreen extends StatefulWidget {
  final LoginSubmitCallback onSubmit;
  final VoidCallback? onLoginSucceeded;
  final VoidCallback? onSignUpPressed;

  const LoginScreen({
    super.key,
    required this.onSubmit,
    this.onLoginSucceeded,
    this.onSignUpPressed,
  });

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

enum _LoginField { email, password }

class _LoginScreenState extends State<LoginScreen> {
  static final RegExp _emailPattern = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  Map<_LoginField, String> _fieldErrors = const {};
  LoginSubmissionStatus? _submissionStatus;
  var _isSubmitting = false;
  var _obscurePassword = true;
  var _didNotifyLoginSuccess = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    // 通信中と成功後は、同じ認証要求の二重送信を防ぐ。
    if (_isSubmitting || _isSuccessful) return;

    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final errors = _validate(email: email, password: password);
    setState(() {
      _fieldErrors = errors;
      _submissionStatus = null;
    });
    if (errors.isNotEmpty) return;

    setState(() => _isSubmitting = true);
    late final LoginSubmissionResult result;
    try {
      result = await widget.onSubmit(email: email, password: password);
    } catch (_) {
      if (!mounted) return;
      // 例外の詳細や認証情報を露出せず、認証失敗とは別の案内を表示する。
      setState(() {
        _isSubmitting = false;
        _submissionStatus = LoginSubmissionStatus.unexpectedError;
      });
      return;
    }

    // 非同期処理中に画面を離れた場合、破棄済みWidgetを更新・通知しない。
    if (!mounted) return;
    setState(() {
      _isSubmitting = false;
      _submissionStatus = result.status;
    });
    if (result.status == LoginSubmissionStatus.completed &&
        !_didNotifyLoginSuccess) {
      // 成功後の遷移は親の責務とし、同じ結果から重複通知しない。
      _didNotifyLoginSuccess = true;
      widget.onLoginSucceeded?.call();
    }
  }

  Map<_LoginField, String> _validate({
    required String email,
    required String password,
  }) {
    final errors = <_LoginField, String>{};
    if (email.isEmpty) {
      errors[_LoginField.email] = AppStrings.loginEmailRequired;
    } else if (!_emailPattern.hasMatch(email)) {
      errors[_LoginField.email] = AppStrings.loginEmailInvalid;
    }
    if (password.isEmpty) {
      errors[_LoginField.password] = AppStrings.loginPasswordRequired;
    }
    return errors;
  }

  void _clearError(_LoginField field) {
    if (!_fieldErrors.containsKey(field) && _submissionStatus == null) return;
    setState(() {
      _fieldErrors = Map.of(_fieldErrors)..remove(field);
      // 入力を修正した時点で古い失敗表示を消し、次の試行結果と混同させない。
      _submissionStatus = null;
    });
  }

  bool get _isSuccessful =>
      _submissionStatus == LoginSubmissionStatus.completed;

  String? get _feedbackMessage {
    switch (_submissionStatus) {
      case LoginSubmissionStatus.completed:
        return AppStrings.loginCompleted;
      case LoginSubmissionStatus.failed:
        return AppStrings.loginFailed;
      case LoginSubmissionStatus.networkError:
        return AppStrings.loginNetworkError;
      case LoginSubmissionStatus.unexpectedError:
        return AppStrings.loginUnexpectedError;
      case null:
        return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final feedbackMessage = _feedbackMessage;
    final fieldsEnabled = !_isSubmitting && !_isSuccessful;

    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.appName)),
      body: SafeArea(
        // 小さい画面やキーボード表示時にも、入力欄と操作をスクロールで確認できる。
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
                  AppStrings.loginTitle,
                  style: AppTextStyles.signUpTitle,
                ),
                const SizedBox(height: AppSizes.spacingSmall),
                const Text(
                  AppStrings.loginDescription,
                  style: AppTextStyles.signUpDescription,
                ),
                const SizedBox(height: AppSizes.spacingLarge),
                LabeledTextField(
                  label: AppStrings.loginEmailLabel,
                  hint: AppStrings.loginEmailHint,
                  controller: _emailController,
                  isRequired: true,
                  errorText: _fieldErrors[_LoginField.email],
                  keyboardType: TextInputType.emailAddress,
                  autofillHints: const [AutofillHints.email],
                  enabled: fieldsEnabled,
                  onChanged: (_) => _clearError(_LoginField.email),
                ),
                const SizedBox(height: AppSizes.scoreSectionSpacing),
                LabeledTextField(
                  label: AppStrings.loginPasswordLabel,
                  hint: AppStrings.loginPasswordHint,
                  controller: _passwordController,
                  isRequired: true,
                  errorText: _fieldErrors[_LoginField.password],
                  obscureText: _obscurePassword,
                  autofillHints: const [AutofillHints.password],
                  enabled: fieldsEnabled,
                  textInputAction: TextInputAction.done,
                  suffixIcon: IconButton(
                    tooltip: _obscurePassword
                        ? AppStrings.loginPasswordShow
                        : AppStrings.loginPasswordHide,
                    onPressed: fieldsEnabled
                        ? () => setState(
                              () => _obscurePassword = !_obscurePassword,
                            )
                        : null,
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility
                          : Icons.visibility_off,
                    ),
                  ),
                  onChanged: (_) => _clearError(_LoginField.password),
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
                  label: _isSubmitting
                      ? AppStrings.loginSubmitting
                      : AppStrings.loginSubmit,
                  onPressed: fieldsEnabled ? _submit : null,
                ),
                const SizedBox(height: AppSizes.spacingMedium),
                TextButton(
                  // 認証結果が確定した後に別の登録フローへ移らないよう、入力欄と同じ条件で制御する。
                  onPressed: fieldsEnabled ? widget.onSignUpPressed : null,
                  child: const Text(AppStrings.loginSignUpPrompt),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
