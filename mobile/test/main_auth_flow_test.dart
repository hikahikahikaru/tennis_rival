import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/main.dart';
import 'package:mobile/repositories/auth_repository.dart';
import 'package:mobile/screens/login_screen.dart';
import 'package:mobile/services/auth_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  testWidgets('未ログイン時はログイン画面を表示しプリロードしない', (tester) async {
    var preloadCallCount = 0;

    await tester.pumpWidget(
      MyApp(
        authService: AuthService(repository: _FakeAuthRepository()),
        onAuthenticated: (_) => preloadCallCount++,
      ),
    );

    expect(find.byType(LoginScreen), findsOneWidget);
    expect(preloadCallCount, 0);
  });

  testWidgets('既存セッションのユーザーIDがあればホームを初期表示する', (tester) async {
    await tester.pumpWidget(
      MyApp(
        authService: AuthService(repository: _FakeAuthRepository()),
        initialUserId: 'restored-user',
        homeBuilder: (userId, _) => Text('home:$userId'),
      ),
    );

    expect(find.text('home:restored-user'), findsOneWidget);
    expect(find.byType(LoginScreen), findsNothing);
  });

  testWidgets('ログイン成功でホームへ移りログアウト後はログインへ戻る', (tester) async {
    final repository = _FakeAuthRepository(hasActiveSession: true);
    var preloadCallCount = 0;

    await tester.pumpWidget(
      MyApp(
        authService: AuthService(repository: repository),
        onAuthenticated: (_) => preloadCallCount++,
        homeBuilder: (userId, onLogout) => Scaffold(
          body: Column(
            children: [
              Text('home:$userId'),
              ElevatedButton(
                onPressed: onLogout,
                child: const Text('logout'),
              ),
            ],
          ),
        ),
      ),
    );
    await _enterLoginInput(tester);

    await tester.tap(find.text('ログインする'));
    await tester.pumpAndSettle();

    expect(find.text('home:user-1'), findsOneWidget);
    expect(preloadCallCount, 1);
    expect(repository.signInCallCount, 1);
    expect(
        Navigator.of(tester.element(find.text('home:user-1'))).canPop(), false);

    await tester.tap(find.text('logout'));
    await tester.pumpAndSettle();

    expect(find.byType(LoginScreen), findsOneWidget);
    expect(repository.signOutCallCount, 1);
    expect(repository.hasActiveSession, isFalse);
    expect(
        Navigator.of(tester.element(find.byType(LoginScreen))).canPop(), false);
  });

  testWidgets('ログアウト通信が失敗してもセッション消失時はログインへ戻る', (tester) async {
    final repository = _FakeAuthRepository(
      hasActiveSession: true,
      signOutError: AuthRetryableFetchException(message: 'offline'),
      clearSessionBeforeSignOutError: true,
    );

    await tester.pumpWidget(
      MyApp(
        authService: AuthService(repository: repository),
        initialUserId: 'user-1',
        homeBuilder: (userId, onLogout) => Scaffold(
          body:
              ElevatedButton(onPressed: onLogout, child: const Text('logout')),
        ),
      ),
    );

    await tester.tap(find.text('logout'));
    await tester.pumpAndSettle();

    expect(find.byType(LoginScreen), findsOneWidget);
    expect(repository.hasActiveSession, isFalse);
  });

  testWidgets('ログアウト失敗時にセッションが残ればホームでエラーを表示する', (tester) async {
    final repository = _FakeAuthRepository(
      hasActiveSession: true,
      signOutError: AuthRetryableFetchException(message: 'offline'),
    );

    await tester.pumpWidget(
      MyApp(
        authService: AuthService(repository: repository),
        initialUserId: 'user-1',
      ),
    );

    await tester.tap(find.byTooltip('ログアウト'));
    await tester.pumpAndSettle();

    expect(find.byType(LoginScreen), findsNothing);
    expect(find.text('Tennis Rival'), findsWidgets);
    expect(
      find.text('通信に失敗しました。通信環境を確認してもう一度お試しください'),
      findsOneWidget,
    );
    expect(repository.hasActiveSession, isTrue);
  });

  testWidgets('ログアウト成功応答でもセッションが残ればホームを維持する', (tester) async {
    final repository = _FakeAuthRepository(
      hasActiveSession: true,
      preserveSessionOnSuccess: true,
    );

    await tester.pumpWidget(
      MyApp(
        authService: AuthService(repository: repository),
        initialUserId: 'user-1',
      ),
    );

    await tester.tap(find.byTooltip('ログアウト'));
    await tester.pumpAndSettle();

    expect(find.byType(LoginScreen), findsNothing);
    expect(find.text('ログアウトできませんでした。もう一度お試しください'), findsOneWidget);
    expect(repository.hasActiveSession, isTrue);
  });

  testWidgets('認証失敗とメール未確認ではホームへ移らない', (tester) async {
    final repository = _FakeAuthRepository(
      signInError: const AuthException(
        'email is not confirmed',
        code: 'email_not_confirmed',
      ),
    );

    await tester.pumpWidget(
      MyApp(
        authService: AuthService(repository: repository),
        onAuthenticated: (_) {},
        homeBuilder: (_, __) => const Text('home'),
      ),
    );
    await _enterLoginInput(tester);

    await tester.tap(find.text('ログインする'));
    await tester.pumpAndSettle();

    expect(find.byType(LoginScreen), findsOneWidget);
    expect(find.text('home'), findsNothing);
    expect(find.textContaining('メールアドレスの確認が完了していません'), findsOneWidget);
  });
}

Future<void> _enterLoginInput(WidgetTester tester) async {
  await tester.enterText(find.byType(TextField).at(0), 'login@example.com');
  await tester.enterText(find.byType(TextField).at(1), 'password8');
}

class _FakeAuthRepository implements AuthRepository {
  _FakeAuthRepository({
    this.signInError,
    this.signOutError,
    bool hasActiveSession = false,
    this.clearSessionBeforeSignOutError = false,
    this.preserveSessionOnSuccess = false,
  }) : _hasActiveSession = hasActiveSession;

  final Object? signInError;
  final Object? signOutError;
  final bool clearSessionBeforeSignOutError;
  final bool preserveSessionOnSuccess;
  bool _hasActiveSession;
  int signInCallCount = 0;
  int signOutCallCount = 0;

  @override
  bool get hasActiveSession => _hasActiveSession;

  @override
  Future<AuthSignInResponse> signIn({
    required String email,
    required String password,
  }) async {
    signInCallCount++;
    final failure = signInError;
    if (failure != null) throw failure;
    return const AuthSignInResponse(userId: 'user-1', hasSession: true);
  }

  @override
  Future<void> signOut() async {
    signOutCallCount++;
    if (clearSessionBeforeSignOutError) {
      _hasActiveSession = false;
    }
    final failure = signOutError;
    if (failure != null) throw failure;
    if (!preserveSessionOnSuccess) {
      _hasActiveSession = false;
    }
  }

  @override
  Future<AuthSignUpResponse> signUp({
    required String displayName,
    required String email,
    required String password,
  }) {
    throw UnimplementedError();
  }
}
