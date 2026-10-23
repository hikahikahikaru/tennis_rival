import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/constants/app_theme.dart';
import 'package:mobile/mocks/mock_data.dart';
import 'package:mobile/models/match_history_item.dart';
import 'package:mobile/models/match_history_query.dart';
import 'package:mobile/repositories/match_history_repository.dart';
import 'package:mobile/repositories/match_memo_repository.dart';
import 'package:mobile/screens/group_list_screen.dart';
import 'package:mobile/screens/home_screen.dart';
import 'package:mobile/screens/match_entry_screen.dart';
import 'package:mobile/screens/match_history_screen.dart';
import 'package:mobile/services/match_history_service.dart';
import 'package:mobile/services/match_memo_service.dart';
import 'package:mobile/widgets/stats_card.dart';

void main() {
  Future<void> pumpHome(
    WidgetTester tester, {
    Size? screenSize,
    _FakeMatchHistoryRepository? repository,
    MatchHistoryService? historyService,
    MatchMemoRepository? memoRepository,
  }) async {
    if (screenSize != null) {
      tester.view.physicalSize = screenSize;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
    }

    final resolvedHistoryService = historyService ??
        MatchHistoryService(
          repository:
              repository ?? _FakeMatchHistoryRepository.success(_recentMatches),
        );
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: HomeScreen(
          matchHistoryService: resolvedHistoryService,
          matchMemoService: MatchMemoService(
            repository: memoRepository ?? _FakeMatchMemoRepository(),
            matchHistoryService: resolvedHistoryService,
          ),
        ),
      ),
    );
    await tester.pump();
  }

  testWidgets(
    'shows greeting, monthly stats, pending count, and fetched recent matches',
    (WidgetTester tester) async {
      await pumpHome(tester);

      // 本体の文字列生成関数に依存せず、画面仕様として見える文言を検証する。
      expect(find.text('Tennis Rival'), findsOneWidget);
      expect(find.text('こんにちは、たけしさん'), findsOneWidget);
      expect(find.text('2試合'), findsOneWidget);
      expect(find.text('2勝 0敗'), findsOneWidget);
      expect(find.text('100%'), findsOneWidget);
      expect(find.text('確認待ちの試合'), findsOneWidget);
      expect(find.text('1件'), findsOneWidget);
      expect(find.text('最近の試合'), findsOneWidget);
      expect(find.text('8月24日'), findsOneWidget);
      expect(find.text('vs 西やん'), findsOneWidget);
      expect(find.text('6-4, 6-3'), findsOneWidget);
      expect(find.text('8月18日'), findsOneWidget);
      expect(find.text('vs ピンちゃん'), findsOneWidget);
      expect(find.text('4-6, 7-5, 10-8'), findsOneWidget);
    },
  );

  testWidgets('shows empty message when fetched recent matches are empty',
      (WidgetTester tester) async {
    await pumpHome(
      tester,
      repository: _FakeMatchHistoryRepository.success(const []),
    );

    expect(find.text('最近の試合はまだありません'), findsOneWidget);
    expect(find.text('0試合'), findsOneWidget);
    expect(find.text('0勝 0敗'), findsOneWidget);
    expect(find.text('0%'), findsOneWidget);
  });

  testWidgets('shows error and retries fetched recent matches',
      (WidgetTester tester) async {
    final repository = _FakeMatchHistoryRepository.responses([
      Exception('DB error'),
      _recentMatches,
    ], monthResponses: [
      _recentMatches,
    ]);

    await pumpHome(tester, repository: repository);

    expect(find.text('試合履歴の取得に失敗しました'), findsOneWidget);
    expect(repository.fetchCallCount, 1);

    await tester.tap(find.text('再試行'));
    await tester.pump();

    expect(find.text('vs 西やん'), findsOneWidget);
    expect(repository.fetchCallCount, 2);
  });

  testWidgets('aggregates the complete current month independently of recents',
      (WidgetTester tester) async {
    final repository = _FakeMatchHistoryRepository.responses(
      [_recentMatches],
      monthResponses: [
        [
          _match('month-win-1', true),
          _match('month-win-2', true),
          _match('month-loss', false),
          _match('month-unknown', null),
        ],
      ],
    );

    await pumpHome(tester, repository: repository);

    expect(find.text('4試合'), findsOneWidget);
    expect(find.text('2勝 1敗'), findsOneWidget);
    expect(find.text('67%'), findsOneWidget);
    expect(repository.monthFetchCallCount, 1);
  });

  testWidgets('shows loading while current month stats are pending',
      (WidgetTester tester) async {
    final monthResponse = Completer<List<MatchHistoryItem>>();
    final repository = _DeferredMonthlyMatchHistoryRepository(monthResponse);

    await pumpHome(
      tester,
      historyService: MatchHistoryService(repository: repository),
    );

    expect(find.text('今月の戦績を読み込み中です'), findsOneWidget);
    expect(find.byType(StatsCard), findsNothing);

    monthResponse.complete([_match('month-win', true)]);
    await tester.pump();
    expect(find.text('1試合'), findsOneWidget);
    expect(find.text('1勝 0敗'), findsOneWidget);
  });

  testWidgets('shows a monthly stats error and retries without showing zero',
      (WidgetTester tester) async {
    final repository = _FakeMatchHistoryRepository.responses(
      [_recentMatches],
      monthResponses: [
        Exception('monthly stats failed'),
        [_match('retry-win', true)],
      ],
    );

    await pumpHome(tester, repository: repository);

    expect(find.text('今月の戦績の取得に失敗しました'), findsOneWidget);
    expect(find.text('0試合'), findsNothing);

    await tester.tap(find.text('再試行'));
    await tester.pump();

    expect(find.text('1試合'), findsOneWidget);
    expect(find.text('1勝 0敗'), findsOneWidget);
    expect(repository.monthFetchCallCount, 2);
  });

  testWidgets('reuses the current month cache preloaded before HomeScreen',
      (WidgetTester tester) async {
    final repository = _FakeMatchHistoryRepository.responses(
      [_recentMatches],
      monthResponses: [
        [_match('cached-win', true)],
      ],
    );
    final service = MatchHistoryService(repository: repository);
    final now = DateTime.now();
    await service.loadMatchesByMonth(year: now.year, month: now.month);

    await pumpHome(tester, historyService: service);

    expect(find.text('1試合'), findsOneWidget);
    expect(find.text('1勝 0敗'), findsOneWidget);
    expect(repository.monthFetchCallCount, 1);
  });

  testWidgets('older success cannot replace newer user result',
      (WidgetTester tester) async {
    // Completerで応答順を逆転し、ユーザー変更後の古い成功が表示を戻さないことを確認する。
    final oldResponse = Completer<List<MatchHistoryItem>>();
    final newResponse = Completer<List<MatchHistoryItem>>();
    final repository = _DeferredMatchHistoryRepository({
      'old-user': oldResponse,
      'new-user': newResponse,
    });

    await _pumpHomeForUser(tester, repository, 'old-user');
    await _pumpHomeForUser(tester, repository, 'new-user');
    newResponse.complete(_recentMatches);
    await tester.pump();
    expect(find.text('vs 西やん'), findsOneWidget);

    oldResponse.complete(const []);
    await tester.pump();
    expect(find.text('vs 西やん'), findsOneWidget);
    expect(find.text('最近の試合はまだありません'), findsNothing);
  });

  testWidgets('older failure cannot replace newer loading or result',
      (WidgetTester tester) async {
    final oldResponse = Completer<List<MatchHistoryItem>>();
    final newResponse = Completer<List<MatchHistoryItem>>();
    final repository = _DeferredMatchHistoryRepository({
      'old-user': oldResponse,
      'new-user': newResponse,
    });

    await _pumpHomeForUser(tester, repository, 'old-user');
    await _pumpHomeForUser(tester, repository, 'new-user');
    // 古い失敗は新しいユーザーの読み込み表示を消してはならない。
    oldResponse.completeError(Exception('old request failed'));
    await tester.pump();
    expect(find.text('試合履歴を読み込み中です'), findsOneWidget);
    expect(find.text('試合履歴の取得に失敗しました'), findsNothing);

    newResponse.complete(_recentMatches);
    await tester.pump();
    expect(find.text('vs 西やん'), findsOneWidget);
  });

  testWidgets('shows indeterminate result without displaying LOSE',
      (WidgetTester tester) async {
    await pumpHome(
      tester,
      repository: _FakeMatchHistoryRepository.success(
        [
          MatchHistoryItem(
            matchDate: DateTime(2026, 8, 24),
            opponentName: '西やん',
            scoreText: 'スコア不明',
            isWin: null,
          ),
        ],
      ),
    );

    expect(find.text('判定不能'), findsOneWidget);
    expect(find.text('LOSE'), findsNothing);
  });

  testWidgets('opens cached match detail without another repository request',
      (WidgetTester tester) async {
    final repository = _FakeMatchHistoryRepository.success(_recentMatches);
    await pumpHome(tester, repository: repository);

    await tester.ensureVisible(find.text('vs 西やん'));
    await tester.tap(find.text('vs 西やん'));
    await tester.pumpAndSettle();

    expect(find.text('試合詳細'), findsOneWidget);
    expect(repository.fetchCallCount, 1);
  });

  testWidgets('keeps the saved memo when the detail sheet is reopened',
      (WidgetTester tester) async {
    final memoRepository = _FakeMatchMemoRepository();
    await pumpHome(tester, memoRepository: memoRepository);
    await tester.ensureVisible(find.text('vs 西やん'));
    final homeScrollState = tester.state<ScrollableState>(
      find.byType(Scrollable).first,
    );
    final scrollOffsetBeforeOpening = homeScrollState.position.pixels;
    await tester.tap(find.text('vs 西やん'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('個人メモを編集'));
    await tester.pump();
    await tester.enterText(find.byType(TextField), 'ホームにも反映するメモ');

    await tester.tap(find.text('保存する'));
    await tester.pumpAndSettle();

    expect(find.text('試合詳細'), findsNothing);
    expect(homeScrollState.position.pixels, scrollOffsetBeforeOpening);
    await tester.tap(find.text('vs 西やん'));
    await tester.pumpAndSettle();

    expect(find.text('ホームにも反映するメモ'), findsOneWidget);
    expect(
      memoRepository.memos[('match-1', MockData.currentUserId)],
      'ホームにも反映するメモ',
    );
  });

  testWidgets('opens match entry screen from record button',
      (WidgetTester tester) async {
    await pumpHome(tester);

    await tester.tap(find.text('試合結果を記録'));
    await tester.pumpAndSettle();

    expect(find.byType(MatchEntryScreen), findsOneWidget);
  });

  testWidgets('opens match entry screen from entry bottom navigation item',
      (WidgetTester tester) async {
    await pumpHome(tester);

    await tester.tap(find.text('登録'));
    await tester.pumpAndSettle();

    expect(find.byType(MatchEntryScreen), findsOneWidget);
  });

  testWidgets('switches from home to stats and back with selected tab updates',
      (WidgetTester tester) async {
    await pumpHome(tester);

    expect(find.byType(HomeScreen), findsOneWidget);
    expect(
      tester
          .widget<BottomNavigationBar>(find.byType(BottomNavigationBar))
          .currentIndex,
      0,
    );

    await tester.tap(find.text('戦績'));
    await tester.pumpAndSettle();

    expect(find.byType(MatchHistoryScreen), findsOneWidget);
    expect(
      tester
          .widget<BottomNavigationBar>(find.byType(BottomNavigationBar))
          .currentIndex,
      1,
    );

    await tester.tap(find.text('ホーム'));
    await tester.pumpAndSettle();

    expect(find.byType(HomeScreen), findsOneWidget);
    expect(find.byType(MatchHistoryScreen), findsNothing);
    expect(
      tester
          .widget<BottomNavigationBar>(find.byType(BottomNavigationBar))
          .currentIndex,
      0,
    );
  });

  testWidgets('switches home group stats home without growing the route stack',
      (WidgetTester tester) async {
    await pumpHome(tester);

    await tester.tap(find.text('グループ'));
    await tester.pumpAndSettle();

    expect(find.byType(GroupListScreen), findsOneWidget);
    expect(
      tester
          .widget<BottomNavigationBar>(find.byType(BottomNavigationBar))
          .currentIndex,
      3,
    );

    final groupScreen = tester.element(find.byType(GroupListScreen));
    await tester.tap(
      find.descendant(
        of: find.byType(BottomNavigationBar),
        matching: find.text('グループ'),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.element(find.byType(GroupListScreen)), same(groupScreen));

    await tester.tap(find.text('戦績'));
    await tester.pumpAndSettle();

    expect(find.byType(MatchHistoryScreen), findsOneWidget);
    expect(find.byType(GroupListScreen), findsNothing);
    expect(
      tester
          .widget<BottomNavigationBar>(find.byType(BottomNavigationBar))
          .currentIndex,
      1,
    );

    await tester.tap(find.text('ホーム'));
    await tester.pumpAndSettle();

    expect(find.byType(HomeScreen), findsOneWidget);
    expect(find.byType(MatchHistoryScreen), findsNothing);
    expect(
      tester
          .widget<BottomNavigationBar>(find.byType(BottomNavigationBar))
          .currentIndex,
      0,
    );
    expect(
        Navigator.of(tester.element(find.byType(HomeScreen))).canPop(), false);
  });

  testWidgets('opens match entry from group without retaining group route',
      (WidgetTester tester) async {
    await pumpHome(tester);

    await tester.tap(find.text('グループ'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('登録'));
    await tester.pumpAndSettle();

    expect(find.byType(MatchEntryScreen), findsOneWidget);
    expect(find.byType(GroupListScreen), findsNothing);

    Navigator.of(tester.element(find.byType(MatchEntryScreen))).pop();
    await tester.pumpAndSettle();
    expect(find.byType(HomeScreen), findsOneWidget);
  });

  testWidgets('switches group stats group without growing the route stack',
      (WidgetTester tester) async {
    await pumpHome(tester);

    await tester.tap(find.text('グループ'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('戦績'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('グループ'));
    await tester.pumpAndSettle();

    expect(find.byType(GroupListScreen), findsOneWidget);
    expect(find.byType(MatchHistoryScreen), findsNothing);
    expect(
      tester
          .widget<BottomNavigationBar>(find.byType(BottomNavigationBar))
          .currentIndex,
      3,
    );

    Navigator.of(tester.element(find.byType(GroupListScreen))).pop();
    await tester.pumpAndSettle();
    expect(find.byType(HomeScreen), findsOneWidget);
    expect(
        Navigator.of(tester.element(find.byType(HomeScreen))).canPop(), false);
  });

  testWidgets('returns directly from group to the root home screen',
      (WidgetTester tester) async {
    await pumpHome(tester);

    await tester.tap(find.text('グループ'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('ホーム'));
    await tester.pumpAndSettle();

    expect(find.byType(HomeScreen), findsOneWidget);
    expect(find.byType(GroupListScreen), findsNothing);
    expect(
        Navigator.of(tester.element(find.byType(HomeScreen))).canPop(), false);
  });

  testWidgets('shows SnackBar guidance for unimplemented home actions',
      (WidgetTester tester) async {
    await pumpHome(tester);

    await tester.tap(find.byTooltip('通知'));
    await tester.pump();
    expect(find.text('通知機能は未実装です'), findsOneWidget);

    await tester.ensureVisible(find.text('確認する'));
    await tester.tap(find.text('確認する'));
    await tester.pump();
    expect(find.text('確認待ち画面は未実装です'), findsOneWidget);

    await tester.tap(find.text('マイページ'));
    await tester.pump();
    expect(find.text('この機能は未実装です'), findsOneWidget);
  });

  testWidgets('does not overflow at 320px width while scrolling',
      (WidgetTester tester) async {
    await pumpHome(tester, screenSize: const Size(320, 700));

    expect(tester.takeException(), isNull);
    await tester.drag(
        find.byType(SingleChildScrollView), const Offset(0, -600));
    await tester.pump();
    expect(tester.takeException(), isNull);
  });

  testWidgets('does not overflow at 390px width while scrolling',
      (WidgetTester tester) async {
    await pumpHome(tester, screenSize: const Size(390, 700));

    expect(tester.takeException(), isNull);
    await tester.drag(
        find.byType(SingleChildScrollView), const Offset(0, -600));
    await tester.pump();
    expect(tester.takeException(), isNull);
  });
}

Future<void> _pumpHomeForUser(
  WidgetTester tester,
  MatchHistoryRepository repository,
  String userId,
) async {
  await tester.pumpWidget(MaterialApp(
    theme: AppTheme.lightTheme,
    home: HomeScreen(
      matchHistoryService: MatchHistoryService(repository: repository),
      currentUserId: userId,
    ),
  ));
  await tester.pump();
}

class _DeferredMatchHistoryRepository implements MatchHistoryRepository {
  final Map<String, Completer<List<MatchHistoryItem>>> responses;

  _DeferredMatchHistoryRepository(this.responses);

  @override
  Future<List<MatchHistoryItem>> fetchRecentMatches(String currentUserId) {
    return responses[currentUserId]!.future;
  }

  @override
  Future<List<MatchHistoryItem>> fetchMatches(MatchHistoryQuery query) {
    return responses[query.currentUserId]!.future;
  }
}

final List<MatchHistoryItem> _recentMatches = [
  MatchHistoryItem(
    matchId: 'match-1',
    matchDate: DateTime(2026, 8, 24),
    opponentName: '西やん',
    scoreText: '6-4, 6-3',
    isWin: true,
  ),
  MatchHistoryItem(
    matchId: 'match-2',
    matchDate: DateTime(2026, 8, 18),
    opponentName: 'ピンちゃん',
    scoreText: '4-6, 7-5, 10-8',
    isWin: true,
  ),
];

MatchHistoryItem _match(String matchId, bool? isWin) {
  return MatchHistoryItem(
    matchId: matchId,
    matchDate: DateTime.now(),
    opponentName: '月間対戦相手',
    scoreText: '6-4',
    isWin: isWin,
  );
}

class _FakeMatchHistoryRepository implements MatchHistoryRepository {
  final List<Object> _responses;
  final List<Object> _monthResponses;
  int fetchCallCount = 0;
  int monthFetchCallCount = 0;

  _FakeMatchHistoryRepository.responses(
    this._responses, {
    List<Object>? monthResponses,
  }) : _monthResponses = List<Object>.of(monthResponses ?? _responses);

  factory _FakeMatchHistoryRepository.success(List<MatchHistoryItem> matches) {
    return _FakeMatchHistoryRepository.responses([matches]);
  }

  @override
  Future<List<MatchHistoryItem>> fetchRecentMatches(
      String currentUserId) async {
    fetchCallCount++;
    final response =
        _responses.length > 1 ? _responses.removeAt(0) : _responses.first;

    if (response is Exception) {
      throw response;
    }

    return response as List<MatchHistoryItem>;
  }

  @override
  Future<List<MatchHistoryItem>> fetchMatches(MatchHistoryQuery query) async {
    monthFetchCallCount++;
    final response = _monthResponses.length > 1
        ? _monthResponses.removeAt(0)
        : _monthResponses.first;
    if (response is Exception) throw response;
    return response as List<MatchHistoryItem>;
  }
}

class _DeferredMonthlyMatchHistoryRepository implements MatchHistoryRepository {
  final Completer<List<MatchHistoryItem>> monthResponse;

  _DeferredMonthlyMatchHistoryRepository(this.monthResponse);

  @override
  Future<List<MatchHistoryItem>> fetchRecentMatches(
      String currentUserId) async {
    return _recentMatches;
  }

  @override
  Future<List<MatchHistoryItem>> fetchMatches(MatchHistoryQuery query) {
    return monthResponse.future;
  }
}

class _FakeMatchMemoRepository implements MatchMemoRepository {
  final Map<(String, String), String> memos = {};

  @override
  Future<void> upsertPersonalMemo({
    required String matchId,
    required String userId,
    required String memo,
  }) async {
    memos[(matchId, userId)] = memo;
  }

  @override
  Future<void> deletePersonalMemo({
    required String matchId,
    required String userId,
  }) async {
    memos.remove((matchId, userId));
  }
}
