import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/constants/app_theme.dart';
import 'package:mobile/screens/sign_up_screen.dart';
import 'package:mobile/widgets/labeled_text_field.dart';

void main() {
  testWidgets('shows four account input fields and navigation actions',
      (tester) async {
    await tester.pumpWidget(_subject(onSubmit: _successfulSubmit));

    expect(find.byType(LabeledTextField), findsNWidgets(4));
    expect(find.textContaining('表示名'), findsOneWidget);
    expect(find.textContaining('メールアドレス'), findsOneWidget);
    expect(find.textContaining('パスワード（確認用）'), findsOneWidget);
    expect(find.text('アカウントを作成する'), findsOneWidget);
    expect(find.text('すでにアカウントをお持ちの方はこちら'), findsOneWidget);
  });

  testWidgets('notifies the parent from the login guidance', (tester) async {
    var pressed = false;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: SignUpScreen(
          onSubmit: _successfulSubmit,
          onLoginPressed: () => pressed = true,
        ),
      ),
    );

    await tester.ensureVisible(find.text('すでにアカウントをお持ちの方はこちら'));
    await tester.tap(find.text('すでにアカウントをお持ちの方はこちら'));

    expect(pressed, isTrue);
  });

  testWidgets('shows required errors without calling submit', (tester) async {
    var callCount = 0;
    await tester.pumpWidget(
      _subject(
        onSubmit: ({
          required displayName,
          required email,
          required password,
          required confirmPassword,
        }) async {
          callCount++;
          return const SignUpSubmissionResult(
            SignUpSubmissionStatus.emailConfirmationRequired,
          );
        },
      ),
    );

    await _tapSubmit(tester);

    expect(find.text('表示名を入力してください'), findsOneWidget);
    expect(find.text('メールアドレスを入力してください'), findsOneWidget);
    expect(find.text('パスワードは8文字以上で入力してください'), findsOneWidget);
    expect(find.text('確認用パスワードを入力してください'), findsOneWidget);
    expect(callCount, 0);
  });

  testWidgets('validates email format', (tester) async {
    await tester.pumpWidget(_subject(onSubmit: _successfulSubmit));
    await _enterValidInput(tester, email: 'invalid-email');

    await _tapSubmit(tester);

    expect(find.text('メールアドレスの形式が正しくありません'), findsOneWidget);
  });

  testWidgets('validates minimum password length', (tester) async {
    await tester.pumpWidget(_subject(onSubmit: _successfulSubmit));
    await _enterValidInput(
      tester,
      password: '1234567',
      confirmPassword: '1234567',
    );

    await _tapSubmit(tester);

    expect(find.text('パスワードは8文字以上で入力してください'), findsOneWidget);
  });

  testWidgets('validates confirmation password match', (tester) async {
    await tester.pumpWidget(_subject(onSubmit: _successfulSubmit));
    await _enterValidInput(tester, confirmPassword: 'different8');

    await _tapSubmit(tester);

    expect(find.text('パスワードが一致しません'), findsOneWidget);
  });

  testWidgets('toggles password visibility', (tester) async {
    await tester.pumpWidget(_subject(onSubmit: _successfulSubmit));

    expect(_textField(tester, 2).obscureText, isTrue);
    await tester.tap(find.byTooltip('パスワードを表示').first);
    await tester.pump();

    expect(_textField(tester, 2).obscureText, isFalse);
    expect(find.byTooltip('パスワードを非表示'), findsOneWidget);
  });

  testWidgets('passes normalized input to submit callback', (tester) async {
    String? receivedDisplayName;
    String? receivedEmail;
    String? receivedPassword;
    String? receivedConfirmPassword;
    await tester.pumpWidget(
      _subject(
        onSubmit: ({
          required displayName,
          required email,
          required password,
          required confirmPassword,
        }) async {
          receivedDisplayName = displayName;
          receivedEmail = email;
          receivedPassword = password;
          receivedConfirmPassword = confirmPassword;
          return const SignUpSubmissionResult(
            SignUpSubmissionStatus.emailConfirmationRequired,
          );
        },
      ),
    );
    await _enterValidInput(
      tester,
      displayName: '  たけし  ',
      email: '  takeshi@example.com  ',
    );

    await _tapSubmit(tester);
    await tester.pumpAndSettle();

    expect(receivedDisplayName, 'たけし');
    expect(receivedEmail, 'takeshi@example.com');
    expect(receivedPassword, 'password8');
    expect(receivedConfirmPassword, 'password8');
  });

  testWidgets('prevents duplicate submissions while registering',
      (tester) async {
    final response = Completer<SignUpSubmissionResult>();
    var callCount = 0;
    await tester.pumpWidget(
      _subject(
        onSubmit: ({
          required displayName,
          required email,
          required password,
          required confirmPassword,
        }) {
          callCount++;
          return response.future;
        },
      ),
    );
    await _enterValidInput(tester);

    await _tapSubmit(tester);
    expect(find.text('登録中...'), findsOneWidget);
    await tester.tap(find.byType(ElevatedButton), warnIfMissed: false);
    await tester.pump();

    expect(callCount, 1);
    response.complete(
      const SignUpSubmissionResult(
        SignUpSubmissionStatus.emailConfirmationRequired,
      ),
    );
    await tester.pumpAndSettle();
  });

  testWidgets('shows privacy-safe email confirmation guidance', (tester) async {
    await tester.pumpWidget(_subject(onSubmit: _successfulSubmit));
    await _enterValidInput(tester);

    await _tapSubmit(tester);
    await tester.pumpAndSettle();

    expect(
      find.text(
        '登録手続きを受け付けました。確認メールが届いた場合は、メール内のリンクから登録を完了してください。',
      ),
      findsOneWidget,
    );
    expect(find.text('確認メールをご確認ください'), findsOneWidget);
  });

  testWidgets('does not submit again after email confirmation is pending',
      (tester) async {
    var callCount = 0;
    await tester.pumpWidget(
      _subject(
        onSubmit: ({
          required displayName,
          required email,
          required password,
          required confirmPassword,
        }) async {
          callCount++;
          return const SignUpSubmissionResult(
            SignUpSubmissionStatus.emailConfirmationRequired,
          );
        },
      ),
    );
    await _enterValidInput(tester);

    await _tapSubmit(tester);
    await tester.pumpAndSettle();
    final button = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
    expect(button.onPressed, isNull);
    await tester.tap(find.byType(ElevatedButton), warnIfMissed: false);
    await tester.pump();

    expect(callCount, 1);
    expect(find.text('確認メールをご確認ください'), findsOneWidget);
  });

  testWidgets('shows registration failure and network error guidance',
      (tester) async {
    var status = SignUpSubmissionStatus.failed;
    await tester.pumpWidget(
      _subject(
        onSubmit: ({
          required displayName,
          required email,
          required password,
          required confirmPassword,
        }) async =>
            SignUpSubmissionResult(status),
      ),
    );
    await _enterValidInput(tester);

    await _tapSubmit(tester);
    await tester.pumpAndSettle();
    expect(
      find.text('アカウントを登録できませんでした。もう一度お試しください'),
      findsOneWidget,
    );

    status = SignUpSubmissionStatus.networkError;
    await _tapSubmit(tester);
    await tester.pumpAndSettle();
    expect(
      find.text('通信に失敗しました。通信環境を確認してもう一度お試しください'),
      findsOneWidget,
    );
  });

  testWidgets('can retry after a failed submission', (tester) async {
    var callCount = 0;
    await tester.pumpWidget(
      _subject(
        onSubmit: ({
          required displayName,
          required email,
          required password,
          required confirmPassword,
        }) async {
          callCount++;
          return SignUpSubmissionResult(
            callCount == 1
                ? SignUpSubmissionStatus.failed
                : SignUpSubmissionStatus.emailConfirmationRequired,
          );
        },
      ),
    );
    await _enterValidInput(tester);

    await _tapSubmit(tester);
    await tester.pumpAndSettle();
    await _tapSubmit(tester);
    await tester.pumpAndSettle();

    expect(callCount, 2);
    expect(find.textContaining('登録手続きを受け付けました'), findsOneWidget);
  });

  testWidgets('scrolls without overflow on a small screen with keyboard',
      (tester) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    tester.view.viewInsets = const FakeViewPadding(bottom: 240);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetViewInsets);
    await tester.pumpWidget(_subject(onSubmit: _successfulSubmit));

    await tester.showKeyboard(find.byType(TextField).first);
    await tester.drag(
        find.byType(SingleChildScrollView), const Offset(0, -600));
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(find.text('アカウントを作成する'), findsOneWidget);
  });
}

Widget _subject({required SignUpSubmitCallback onSubmit}) {
  return MaterialApp(
    theme: AppTheme.lightTheme,
    home: SignUpScreen(onSubmit: onSubmit),
  );
}

Future<SignUpSubmissionResult> _successfulSubmit({
  required String displayName,
  required String email,
  required String password,
  required String confirmPassword,
}) async {
  return const SignUpSubmissionResult(
    SignUpSubmissionStatus.emailConfirmationRequired,
  );
}

Future<void> _enterValidInput(
  WidgetTester tester, {
  String displayName = 'たけし',
  String email = 'takeshi@example.com',
  String password = 'password8',
  String confirmPassword = 'password8',
}) async {
  final fields = find.byType(TextField);
  await tester.enterText(fields.at(0), displayName);
  await tester.enterText(fields.at(1), email);
  await tester.enterText(fields.at(2), password);
  await tester.enterText(fields.at(3), confirmPassword);
}

Future<void> _tapSubmit(WidgetTester tester) async {
  await tester.ensureVisible(find.text('アカウントを作成する'));
  await tester.tap(find.text('アカウントを作成する'));
  await tester.pump();
}

TextField _textField(WidgetTester tester, int index) {
  return tester.widget<TextField>(find.byType(TextField).at(index));
}
