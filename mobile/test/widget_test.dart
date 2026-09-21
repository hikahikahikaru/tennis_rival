import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/constants/app_theme.dart';
import 'package:mobile/models/match_history_item.dart';
import 'package:mobile/repositories/match_history_repository.dart';
import 'package:mobile/screens/home_screen.dart';
import 'package:mobile/screens/match_entry_screen.dart';
import 'package:mobile/services/match_history_service.dart';

void main() {
  Future<void> pumpHome(
    WidgetTester tester, {
    Size? screenSize,
    _FakeMatchHistoryRepository? repository,
  }) async {
    if (screenSize != null) {
      tester.view.physicalSize = screenSize;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
    }

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: HomeScreen(
          matchHistoryService: MatchHistoryService(
            repository: repository ??
                _FakeMatchHistoryRepository.success(_recentMatches),
          ),
        ),
      ),
    );
    await tester.pump();
  }

  testWidgets(
    'shows greeting, sample stats, pending count, and fetched recent matches',
    (WidgetTester tester) async {
      await pumpHome(tester);

      // 本体の文字列生成関数に依存せず、画面仕様として見える文言を検証する。
      expect(find.text('Tennis Rival'), findsOneWidget);
      expect(find.text('こんにちは、たけしさん'), findsOneWidget);
      expect(find.text('4勝 2敗'), findsOneWidget);
      expect(find.text('67%'), findsOneWidget);
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
  });

  testWidgets('shows error and retries fetched recent matches',
      (WidgetTester tester) async {
    final repository = _FakeMatchHistoryRepository.responses([
      Exception('DB error'),
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

    await tester.tap(find.text('戦績'));
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
}

final List<MatchHistoryItem> _recentMatches = [
  MatchHistoryItem(
    matchDate: DateTime(2026, 8, 24),
    opponentName: '西やん',
    scoreText: '6-4, 6-3',
    isWin: true,
  ),
  MatchHistoryItem(
    matchDate: DateTime(2026, 8, 18),
    opponentName: 'ピンちゃん',
    scoreText: '4-6, 7-5, 10-8',
    isWin: true,
  ),
];

class _FakeMatchHistoryRepository implements MatchHistoryRepository {
  final List<Object> _responses;
  int fetchCallCount = 0;

  _FakeMatchHistoryRepository.responses(this._responses);

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
}
