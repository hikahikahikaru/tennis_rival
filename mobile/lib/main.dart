import 'dart:async';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'constants/app_strings.dart';
import 'constants/app_theme.dart';
import 'constants/supabase_constants.dart';
import 'navigation/browser_history.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
import 'screens/sign_up_screen.dart';
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
  late final _AppRouterDelegate _routerDelegate;
  late final _GuardedRouteInformationProvider _routeInformationProvider;
  String? _currentUserId;
  String? _authenticatedUserId;
  String? _loginNotice;

  @override
  void initState() {
    super.initState();
    _authService = widget.authService ?? AuthService();
    _currentUserId = widget.initialUserId;
    _routerDelegate = _AppRouterDelegate(
      initialUserId: _currentUserId,
      loginBuilder: _buildLoginScreen,
      signUpBuilder: _buildSignUpScreen,
      homeBuilder: _buildHomeScreen,
    );
    _routeInformationProvider = _GuardedRouteInformationProvider(
      initialRouteInformation: RouteInformation(
        uri: Uri.parse(
          WidgetsBinding.instance.platformDispatcher.defaultRouteName,
        ),
      ),
      shouldReject: _routerDelegate.shouldRejectRouteInformation,
      currentRouteInformation: () => RouteInformation(
        uri: _AppRouteInformationParser.uriFor(
          _routerDelegate.currentConfiguration,
        ),
      ),
    );
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

  Future<SignUpSubmissionResult> _signUp({
    required String displayName,
    required String email,
    required String password,
    required String confirmPassword,
  }) async {
    final result = await _authService.signUp(
      displayName: displayName,
      email: email,
      password: password,
      confirmPassword: confirmPassword,
    );
    return SignUpSubmissionResult(switch (result.status) {
      AccountRegistrationStatus.emailConfirmationRequired =>
        SignUpSubmissionStatus.emailConfirmationRequired,
      AccountRegistrationStatus.authenticated =>
        SignUpSubmissionStatus.completed,
      AccountRegistrationStatus.networkError =>
        SignUpSubmissionStatus.networkError,
      AccountRegistrationStatus.validationError ||
      AccountRegistrationStatus.authError ||
      AccountRegistrationStatus.unknownError =>
        SignUpSubmissionStatus.failed,
    });
  }

  void _completeSignIn() {
    final userId = _authenticatedUserId;
    if (userId == null) return;
    setState(() {
      _currentUserId = userId;
      _loginNotice = null;
    });
    _routerDelegate.setAuthenticatedUser(userId);
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
        _loginNotice =
            result.isSuccess ? null : AppStrings.logoutSessionWarning;
      });
      _routerDelegate.setAuthenticatedUser(null);
      return null;
    }
    // 成功応答でもセッションが残る場合は、完了とせずホームに留める。
    return result.message.isEmpty ? AppStrings.logoutFailed : result.message;
  }

  @override
  Widget build(BuildContext context) {
    final userId = _currentUserId;
    return MaterialApp.router(
      // 認証境界を越えたときNavigatorも作り直し、保護画面の履歴を破棄する。
      key: ValueKey(
          userId == null ? 'unauthenticated' : 'authenticated:$userId'),
      title: 'Tennis Rival',
      theme: AppTheme.lightTheme,
      routeInformationProvider: _routeInformationProvider,
      routeInformationParser: const _AppRouteInformationParser(),
      routerDelegate: _routerDelegate,
    );
  }

  Widget _buildLoginScreen(BuildContext context) {
    return LoginScreen(
      onSubmit: _signIn,
      onLoginSucceeded: _completeSignIn,
      onSignUpPressed: () {
        // URL変更を明示的なナビゲーションとしてブラウザ履歴へ追加する。
        Router.navigate(context, _routerDelegate.openSignUp);
      },
      noticeMessage: _loginNotice,
    );
  }

  Widget _buildSignUpScreen(BuildContext context) {
    return SignUpScreen(
      onSubmit: _signUp,
      onSubmissionStateChanged: _routerDelegate.setSignUpSubmitting,
      onLoginPressed: () {
        // 画面内の戻る導線では現在の履歴を置換し、往復で履歴を増やさない。
        Router.neglect(context, _routerDelegate.closeSignUp);
      },
    );
  }

  Widget _buildHomeScreen(BuildContext context, String userId) {
    return widget.homeBuilder?.call(userId, _signOut) ??
        HomeScreen(currentUserId: userId, onLogout: _signOut);
  }
}

enum _AppRoutePath { login, signUp, home }

class _AppRouteInformationParser extends RouteInformationParser<_AppRoutePath> {
  const _AppRouteInformationParser();

  static Uri uriFor(_AppRoutePath path) => switch (path) {
        _AppRoutePath.login => Uri(path: '/login'),
        _AppRoutePath.signUp => Uri(path: '/sign-up'),
        _AppRoutePath.home => Uri(path: '/'),
      };

  @override
  Future<_AppRoutePath> parseRouteInformation(
    RouteInformation routeInformation,
  ) async {
    return switch (routeInformation.uri.path) {
      '/sign-up' => _AppRoutePath.signUp,
      '/' => _AppRoutePath.home,
      _ => _AppRoutePath.login,
    };
  }

  @override
  RouteInformation restoreRouteInformation(_AppRoutePath configuration) {
    return RouteInformation(uri: uriFor(configuration));
  }
}

class _GuardedRouteInformationProvider
    extends PlatformRouteInformationProvider {
  _GuardedRouteInformationProvider({
    required super.initialRouteInformation,
    required this.shouldReject,
    required this.currentRouteInformation,
  });

  final bool Function(RouteInformation routeInformation) shouldReject;
  final RouteInformation Function() currentRouteInformation;
  var _historyIndex = 0;
  var _isRestoringRejectedNavigation = false;

  static const _historyIndexKey = 'authHistoryIndex';

  int? _readHistoryIndex(RouteInformation routeInformation) {
    final state = routeInformation.state;
    if (state is! Map) return null;
    return (state[_historyIndexKey] as num?)?.toInt();
  }

  RouteInformation _withHistoryIndex(
    RouteInformation routeInformation,
    int historyIndex,
  ) {
    return RouteInformation(
      uri: routeInformation.uri,
      state: <String, Object?>{_historyIndexKey: historyIndex},
    );
  }

  @override
  void routerReportsNewRouteInformation(
    RouteInformation routeInformation, {
    RouteInformationReportingType type = RouteInformationReportingType.none,
  }) {
    if (type == RouteInformationReportingType.navigate) {
      _historyIndex++;
    }
    super.routerReportsNewRouteInformation(
      _withHistoryIndex(routeInformation, _historyIndex),
      type: type,
    );
  }

  @override
  Future<bool> didPushRouteInformation(RouteInformation routeInformation) {
    if (shouldReject(routeInformation)) {
      if (_isRestoringRejectedNavigation) return Future<bool>.value(true);

      final targetIndex = _readHistoryIndex(routeInformation);
      final delta = targetIndex == null ? 0 : _historyIndex - targetIndex;
      final restored = delta != 0 && restoreBrowserHistoryBy(delta);
      if (restored) {
        // 復旧先のpopstateを待ち、同じ戻る要求の連続処理を防止する。
        _isRestoringRejectedNavigation = true;
      } else {
        // 非Webや履歴番号がない直接URL変更では、現在のURLで置換する。
        routerReportsNewRouteInformation(
          currentRouteInformation(),
          type: RouteInformationReportingType.neglect,
        );
      }
      return Future<bool>.value(true);
    }

    final targetIndex = _readHistoryIndex(routeInformation);
    if (targetIndex != null) {
      _historyIndex = targetIndex;
    }
    _isRestoringRejectedNavigation = false;
    return super.didPushRouteInformation(routeInformation);
  }
}

class _AppRouterDelegate extends RouterDelegate<_AppRoutePath>
    with ChangeNotifier, PopNavigatorRouterDelegateMixin<_AppRoutePath> {
  _AppRouterDelegate({
    required String? initialUserId,
    required this.loginBuilder,
    required this.signUpBuilder,
    required this.homeBuilder,
  }) : _userId = initialUserId;

  final WidgetBuilder loginBuilder;
  final WidgetBuilder signUpBuilder;
  final Widget Function(BuildContext context, String userId) homeBuilder;

  @override
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  String? _userId;
  var _isSignUpOpen = false;
  var _isSignUpSubmitting = false;

  @override
  _AppRoutePath get currentConfiguration {
    if (_userId != null) return _AppRoutePath.home;
    return _isSignUpOpen ? _AppRoutePath.signUp : _AppRoutePath.login;
  }

  void openSignUp() {
    // 同一フレーム内で複数回要求されてもページは1枚だけにする。
    if (_userId != null || _isSignUpOpen) return;
    _isSignUpOpen = true;
    notifyListeners();
  }

  void closeSignUp() {
    if (!_isSignUpOpen || _isSignUpSubmitting) return;
    _isSignUpOpen = false;
    notifyListeners();
  }

  void setSignUpSubmitting(bool isSubmitting) {
    _isSignUpSubmitting = isSubmitting;
  }

  void setAuthenticatedUser(String? userId) {
    _userId = userId;
    _isSignUpOpen = false;
    _isSignUpSubmitting = false;
    notifyListeners();
  }

  bool shouldRejectRouteInformation(RouteInformation routeInformation) {
    return _isSignUpOpen &&
        _isSignUpSubmitting &&
        routeInformation.uri.path != '/sign-up';
  }

  @override
  Future<void> setNewRoutePath(_AppRoutePath configuration) async {
    if (_userId != null) {
      _isSignUpOpen = false;
      return;
    }
    if (_isSignUpOpen &&
        _isSignUpSubmitting &&
        configuration != _AppRoutePath.signUp) {
      return;
    }
    _isSignUpOpen = configuration == _AppRoutePath.signUp;
  }

  @override
  Future<bool> popRoute() async {
    if (_isSignUpOpen) {
      if (_isSignUpSubmitting) return true;
      final navigator = navigatorKey.currentState;
      return navigator?.maybePop() ?? false;
    }
    return super.popRoute();
  }

  @override
  Widget build(BuildContext context) {
    final userId = _userId;
    return Navigator(
      key: navigatorKey,
      pages: [
        if (userId == null)
          MaterialPage<void>(
            key: const ValueKey('login'),
            name: '/login',
            child: Builder(builder: loginBuilder),
          )
        else
          MaterialPage<void>(
            key: ValueKey('home:$userId'),
            name: '/',
            child: Builder(builder: (context) => homeBuilder(context, userId)),
          ),
        if (userId == null && _isSignUpOpen)
          MaterialPage<void>(
            key: const ValueKey('sign-up'),
            name: '/sign-up',
            child: Builder(builder: signUpBuilder),
          ),
      ],
      onDidRemovePage: (page) {
        if (page.name != '/sign-up' || !_isSignUpOpen) return;
        // AppBarやAndroidの戻る操作も履歴を増やさずログインへ戻す。
        Router.neglect(context, closeSignUp);
      },
    );
  }
}
