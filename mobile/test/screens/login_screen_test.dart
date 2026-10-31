import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/constants/app_theme.dart';
import 'package:mobile/screens/login_screen.dart';
import 'package:mobile/widgets/labeled_text_field.dart';

void main() {
  testWidgets('メールアドレスとパスワード、画面操作を表示する', (tester) async {
    await tester.pumpWidget(_subject(onSubmit: _successfulSubmit));

    expect(find.byType(LabeledTextField), findsNWidgets(2));
    final fields = tester
        .widgetList<LabeledTextField>(find.byType(LabeledTextField))
        .toList();
    expect(fields.map((field) => field.label), ['メールアドレス', 'パスワード']);
    expect(find.text('ログインする'), findsOneWidget);
    expect(find.text('新規アカウント登録はこちら'), findsOneWidget);
  });

  testWidgets('新規登録の導線から親Widgetへ通知する', (tester) async {
    var pressed = false;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: LoginScreen(
          onSubmit: _successfulSubmit,
          onSignUpPressed: () => pressed = true,
        ),
      ),
    );

    await tester.tap(find.text('新規アカウント登録はこちら'));

    expect(pressed, isTrue);
  });

  testWidgets('未入力では必須エラーを表示してログイン処理を呼ばない', (tester) async {
    var callCount = 0;
    await tester.pumpWidget(
      _subject(
        onSubmit: ({required email, required password}) async {
          callCount++;
          return const LoginSubmissionResult(LoginSubmissionStatus.completed);
        },
      ),
    );

    await _tapSubmit(tester);

    expect(find.text('メールアドレスを入力してください'), findsOneWidget);
    expect(find.text('パスワードを入力してください'), findsOneWidget);
    expect(callCount, 0);
  });

  testWidgets('不正なメールアドレス形式を拒否する', (tester) async {
    await tester.pumpWidget(_subject(onSubmit: _successfulSubmit));
    await _enterInput(tester, email: 'invalid-email');

    await _tapSubmit(tester);

    expect(find.text('メールアドレスの形式が正しくありません'), findsOneWidget);
  });

  testWidgets('パスワードの表示と非表示を切り替える', (tester) async {
    await tester.pumpWidget(_subject(onSubmit: _successfulSubmit));

    expect(_textField(tester, 1).obscureText, isTrue);
    await tester.tap(find.byTooltip('パスワードを表示'));
    await tester.pump();

    expect(_textField(tester, 1).obscureText, isFalse);
    expect(find.byTooltip('パスワードを非表示'), findsOneWidget);
  });

  testWidgets('前後空白を除いたメールアドレスとパスワードを親へ渡す', (tester) async {
    String? receivedEmail;
    String? receivedPassword;
    await tester.pumpWidget(
      _subject(
        onSubmit: ({required email, required password}) async {
          receivedEmail = email;
          receivedPassword = password;
          return const LoginSubmissionResult(LoginSubmissionStatus.completed);
        },
      ),
    );
    await _enterInput(tester, email: '  user@example.com  ');

    await _tapSubmit(tester);
    await tester.pumpAndSettle();

    expect(receivedEmail, 'user@example.com');
    expect(receivedPassword, 'password8');
  });

  testWidgets('ログイン処理中はLoadingを表示して二重送信を防ぐ', (tester) async {
    final response = Completer<LoginSubmissionResult>();
    var callCount = 0;
    await tester.pumpWidget(
      _subject(
        onSubmit: ({required email, required password}) {
          callCount++;
          return response.future;
        },
      ),
    );
    await _enterInput(tester);

    await _tapSubmit(tester);
    expect(find.text('ログイン中...'), findsOneWidget);
    final button = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
    expect(button.onPressed, isNull);
    final signUpButton = tester.widget<TextButton>(find.byType(TextButton));
    expect(signUpButton.onPressed, isNull);
    await tester.tap(find.byType(ElevatedButton), warnIfMissed: false);
    await tester.pump();

    expect(callCount, 1);
    response.complete(
      const LoginSubmissionResult(LoginSubmissionStatus.completed),
    );
    await tester.pumpAndSettle();
  });

  testWidgets('ログイン成功後は新規登録の導線を無効化する', (tester) async {
    var signUpCallCount = 0;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: LoginScreen(
          onSubmit: _successfulSubmit,
          onSignUpPressed: () => signUpCallCount++,
        ),
      ),
    );
    await _enterInput(tester);

    await _tapSubmit(tester);
    await tester.pumpAndSettle();
    final signUpButton = tester.widget<TextButton>(find.byType(TextButton));
    expect(signUpButton.onPressed, isNull);
    await tester.tap(find.byType(TextButton), warnIfMissed: false);
    await tester.pump();

    expect(signUpCallCount, 0);
    expect(find.text('ログインしました'), findsOneWidget);
  });

  testWidgets('ログイン成功時だけ親Widgetへ一度通知する', (tester) async {
    var submitCallCount = 0;
    var successCallCount = 0;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: LoginScreen(
          onSubmit: ({required email, required password}) async {
            submitCallCount++;
            return const LoginSubmissionResult(
              LoginSubmissionStatus.completed,
            );
          },
          onLoginSucceeded: () => successCallCount++,
        ),
      ),
    );
    await _enterInput(tester);

    await _tapSubmit(tester);
    await tester.pumpAndSettle();
    final loginButton =
        tester.widget<ElevatedButton>(find.byType(ElevatedButton));

    expect(successCallCount, 1);
    expect(loginButton.onPressed, isNull);
    expect(submitCallCount, 1);
  });

  testWidgets('ログイン失敗と通信エラーでは成功を通知しない', (tester) async {
    var status = LoginSubmissionStatus.failed;
    var successCallCount = 0;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: LoginScreen(
          onSubmit: ({required email, required password}) async =>
              LoginSubmissionResult(status),
          onLoginSucceeded: () => successCallCount++,
        ),
      ),
    );
    await _enterInput(tester);

    await _tapSubmit(tester);
    await tester.pumpAndSettle();
    status = LoginSubmissionStatus.networkError;
    await _tapSubmit(tester);
    await tester.pumpAndSettle();

    expect(successCallCount, 0);
  });

  testWidgets('ログイン失敗と通信エラーを区別して表示する', (tester) async {
    var status = LoginSubmissionStatus.failed;
    await tester.pumpWidget(
      _subject(
        onSubmit: ({required email, required password}) async =>
            LoginSubmissionResult(status),
      ),
    );
    await _enterInput(tester);

    await _tapSubmit(tester);
    await tester.pumpAndSettle();
    expect(
      find.text('メールアドレスまたはパスワードを確認してください'),
      findsOneWidget,
    );

    status = LoginSubmissionStatus.networkError;
    await _tapSubmit(tester);
    await tester.pumpAndSettle();
    expect(
      find.text('通信に失敗しました。通信環境を確認してもう一度お試しください'),
      findsOneWidget,
    );
  });

  testWidgets('失敗後に入力内容を維持したまま再試行できる', (tester) async {
    var callCount = 0;
    await tester.pumpWidget(
      _subject(
        onSubmit: ({required email, required password}) async {
          callCount++;
          return LoginSubmissionResult(
            callCount == 1
                ? LoginSubmissionStatus.failed
                : LoginSubmissionStatus.completed,
          );
        },
      ),
    );
    await _enterInput(tester);

    await _tapSubmit(tester);
    await tester.pumpAndSettle();
    await _tapSubmit(tester);
    await tester.pumpAndSettle();

    expect(callCount, 2);
    expect(find.text('ログインしました'), findsOneWidget);
  });

  testWidgets('予期しない例外では専用案内を表示し再試行できる', (tester) async {
    var callCount = 0;
    await tester.pumpWidget(
      _subject(
        onSubmit: ({required email, required password}) async {
          callCount++;
          if (callCount == 1) {
            throw Exception('secret server detail');
          }
          return const LoginSubmissionResult(LoginSubmissionStatus.completed);
        },
      ),
    );
    await _enterInput(tester);

    await _tapSubmit(tester);
    await tester.pumpAndSettle();

    expect(
      find.text('予期しないエラーが発生しました。もう一度お試しください'),
      findsOneWidget,
    );
    expect(find.textContaining('secret server detail'), findsNothing);

    await _tapSubmit(tester);
    await tester.pumpAndSettle();

    expect(callCount, 2);
    expect(find.text('ログインしました'), findsOneWidget);
  });

  testWidgets('小さい画面とキーボード表示でもoverflowしない', (tester) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    tester.view.viewInsets = const FakeViewPadding(bottom: 240);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetViewInsets);
    await tester.pumpWidget(_subject(onSubmit: _successfulSubmit));

    await tester.showKeyboard(find.byType(TextField).first);
    await tester.drag(
      find.byType(SingleChildScrollView),
      const Offset(0, -400),
    );
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(find.text('ログインする'), findsOneWidget);
  });
}

Widget _subject({required LoginSubmitCallback onSubmit}) {
  return MaterialApp(
    theme: AppTheme.lightTheme,
    home: LoginScreen(onSubmit: onSubmit),
  );
}

Future<LoginSubmissionResult> _successfulSubmit({
  required String email,
  required String password,
}) async {
  return const LoginSubmissionResult(LoginSubmissionStatus.completed);
}

Future<void> _enterInput(
  WidgetTester tester, {
  String email = 'user@example.com',
  String password = 'password8',
}) async {
  await tester.enterText(find.byType(TextField).at(0), email);
  await tester.enterText(find.byType(TextField).at(1), password);
}

Future<void> _tapSubmit(WidgetTester tester) async {
  await tester.ensureVisible(find.byType(ElevatedButton));
  await tester.tap(find.byType(ElevatedButton));
  await tester.pump();
}

TextField _textField(WidgetTester tester, int index) {
  return tester.widget<TextField>(find.byType(TextField).at(index));
}
