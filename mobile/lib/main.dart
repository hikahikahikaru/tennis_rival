import 'dart:async';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'constants/app_strings.dart';
import 'constants/app_theme.dart';
import 'constants/supabase_constants.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
import 'services/auth_service.dart';
import 'services/match_history_service.dart';
import 'services/opponent_service.dart';

Future<void> main() async {
  // Flutterの初期化処理を確実に行う
  WidgetsFlutterBinding.ensureInitialized();

  // Supabaseクライアントの初期化
  await Supabase.initialize(
    url: SupabaseConstants.apiUrl,
    anonKey: SupabaseConstants.anonKey,
  );

  final currentSession = Supabase.instance.client.auth.currentSession;
  final isEmailConfirmed = currentSession?.user.emailConfirmedAt != null;
  final currentUserId = isEmailConfirmed ? currentSession!.user.id : null;
  if (currentSession != null && !isEmailConfirmed) {
    try {
      // 復元された未確認セッションを破棄し、起動時もログイン画面から開始する。
      await Supabase.instance.client.auth.signOut(scope: SignOutScope.local);
    } catch (_) {
      // 破棄通信に失敗してもホームへは進めず、安全側の未ログイン表示を維持する。
    }
  }
  if (currentUserId != null) {
    // 未認証時にはRLSで失敗するユーザー依存通信を開始しない。
    _preloadAuthenticatedData(currentUserId);
  }

  runApp(MyApp(initialUserId: currentUserId));
}

void _preloadAuthenticatedData(String currentUserId) {
  // 画面描画を待たせず、同じServiceキャッシュをホーム画面から再利用する。
  unawaited(_preloadOpponents(currentUserId));
  unawaited(_preloadMatchHistory(currentUserId));
  unawaited(_preloadCurrentMonthMatches(currentUserId));
}

// HomeScreenと同じServiceを使い、画面描画を待たず最近の試合をキャッシュする。
Future<void> _preloadMatchHistory(String currentUserId) async {
  try {
    await MatchHistoryService.instance.loadRecentMatches(
      currentUserId: currentUserId,
    );
  } catch (e) {
    debugPrint(AppStrings.errorMatchHistoryFetch(e));
  }
}

// 起動月の試合一覧をキャッシュし、戦績画面の初回表示で再利用する。
Future<void> _preloadCurrentMonthMatches(String currentUserId) async {
  final now = DateTime.now();
  try {
    await MatchHistoryService.instance.loadMatchesByMonth(
      currentUserId: currentUserId,
      year: now.year,
      month: now.month,
    );
  } catch (e) {
    debugPrint(AppStrings.errorMatchHistoryFetch(e));
  }
}

// 先読み専用のエラー握りつぶし。失敗時の再試行導線はOpponentPickerSheet側に委ねる。
Future<void> _preloadOpponents(String currentUserId) async {
  try {
    await OpponentService.instance.loadOpponents(
      currentUserId: currentUserId,
    );
  } catch (e) {
    debugPrint(AppStrings.errorOpponentFetch(e));
  }
}

class MyApp extends StatefulWidget {
  final AuthService? authService;
  final String? initialUserId;
  final void Function(String userId)? onAuthenticated;
  final Widget Function(
    String userId,
    HomeLogoutCallback onLogout,
  )? homeBuilder;

  const MyApp({
    super.key,
    this.authService,
    this.initialUserId,
    this.onAuthenticated,
    this.homeBuilder,
  });

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late final AuthService _authService;
  String? _currentUserId;
  String? _authenticatedUserId;

  @override
  void initState() {
    super.initState();
    _authService = widget.authService ?? AuthService();
    _currentUserId = widget.initialUserId;
  }

  Future<LoginSubmissionResult> _signIn({
    required String email,
    required String password,
  }) async {
    final result = await _authService.signIn(email: email, password: password);
    if (result.isSuccess) {
      _authenticatedUserId = result.userId;
      return const LoginSubmissionResult(LoginSubmissionStatus.completed);
    }

    return LoginSubmissionResult(switch (result.status) {
      AuthenticationStatus.networkError => LoginSubmissionStatus.networkError,
      AuthenticationStatus.unknownError =>
        LoginSubmissionStatus.unexpectedError,
      // 成功は上のisSuccess分岐だけで処理し、失敗経路から遷移させない。
      AuthenticationStatus.authenticated =>
        LoginSubmissionStatus.unexpectedError,
      AuthenticationStatus.validationError ||
      AuthenticationStatus.invalidCredentials =>
        LoginSubmissionStatus.failed,
      AuthenticationStatus.emailNotConfirmed =>
        LoginSubmissionStatus.emailNotConfirmed,
    });
  }

  void _completeSignIn() {
    final userId = _authenticatedUserId;
    if (userId == null) return;
    setState(() => _currentUserId = userId);
    final onAuthenticated = widget.onAuthenticated;
    if (onAuthenticated != null) {
      onAuthenticated(userId);
    } else {
      _preloadAuthenticatedData(userId);
    }
  }

  Future<String?> _signOut() async {
    final result = await _authService.signOut();
    // SDKは通信エラーでもローカルセッションを先に消す場合があるため、実状態を優先する。
    final isSignedOut = !_authService.hasActiveSession;
    if (isSignedOut) {
      if (!mounted) return null;
      // ルート表示を置き換え、ログアウト前のホームをNavigatorスタックへ残さない。
      setState(() {
        _currentUserId = null;
        _authenticatedUserId = null;
      });
      return null;
    }
    // 成功応答でもセッションが残る場合は、完了とせずホームに留める。
    return result.message.isEmpty ? AppStrings.logoutFailed : result.message;
  }

  @override
  Widget build(BuildContext context) {
    final userId = _currentUserId;
    return MaterialApp(
      title: 'Tennis Rival',
      theme: AppTheme.lightTheme,
      home: userId == null
          ? LoginScreen(
              onSubmit: _signIn,
              onLoginSucceeded: _completeSignIn,
            )
          : widget.homeBuilder?.call(userId, _signOut) ??
              HomeScreen(currentUserId: userId, onLogout: _signOut),
    );
  }
}
