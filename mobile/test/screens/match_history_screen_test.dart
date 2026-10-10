import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/constants/app_theme.dart';
import 'package:mobile/models/match_detail.dart';
import 'package:mobile/models/match_history_item.dart';
import 'package:mobile/models/match_history_query.dart';
import 'package:mobile/models/match_set_score.dart';
import 'package:mobile/repositories/match_detail_repository.dart';
import 'package:mobile/repositories/match_history_repository.dart';
import 'package:mobile/repositories/match_memo_repository.dart';
import 'package:mobile/screens/match_history_screen.dart';
import 'package:mobile/services/match_detail_service.dart';
import 'package:mobile/services/match_history_service.dart';
import 'package:mobile/services/match_memo_service.dart';
import 'package:mobile/widgets/match_calendar.dart';
import 'package:mobile/widgets/match_card.dart';
import 'package:mobile/widgets/match_detail_sheet.dart';
import 'package:mobile/widgets/match_memo_field.dart';
import 'package:mobile/widgets/stats_card.dart';

const currentUserId = '11111111-1111-1111-1111-111111111111';
const opponentId = '22222222-2222-2222-2222-222222222222';
const firstMatchId = 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa';
const secondMatchId = 'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb';

void main() {
  Future<void> pumpScreen(
    WidgetTester tester, {
    required MatchHistoryRepository historyRepository,
    MatchDetailRepository? detailRepository,
    MatchMemoRepository? memoRepository,
    Size? screenSize,
  }) async {
    if (screenSize != null) {
      tester.view.physicalSize = screenSize;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
    }

    final historyService = MatchHistoryService(repository: historyRepository);
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: MatchHistoryScreen(
          initialMonth: DateTime(2026, 8),
          currentUserId: currentUserId,
          matchHistoryService: historyService,
          matchDetailService: MatchDetailService(
            repository: detailRepository ??
                _FakeMatchDetailRepository(
                  handler: (_, __) async => _detail(firstMatchId),
                ),
          ),
          matchMemoService: MatchMemoService(
            repository: memoRepository ?? _FakeMatchMemoRepository(),
            matchHistoryService: historyService,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('shows monthly matches from the service and an empty month',
      (tester) async {
    final repository = _FakeMatchHistoryRepository(
      handler: (query) async => query.startDate!.month == 8
          ? [
              _historyItem(firstMatchId),
              _historyItem(secondMatchId, opponentName: 'ピンちゃん'),
            ]
          : const [],
    );
    await pumpScreen(tester, historyRepository: repository);

    expect(find.text('戦績'), findsNWidgets(2));
    expect(find.byType(StatsCard), findsOneWidget);
    expect(find.byType(MatchCalendar), findsOneWidget);
    expect(find.byType(MatchCard), findsNWidgets(2));
    expect(find.text('vs 西やん'), findsOneWidget);
    expect(find.text('vs ピンちゃん'), findsOneWidget);

    await tester.tap(find.byTooltip('翌月'));
    await tester.pumpAndSettle();

    expect(find.text('2026年9月'), findsOneWidget);
    expect(find.text('この月の試合はありません'), findsOneWidget);
  });

  testWidgets('does not overwrite a newer month with an older response',
      (tester) async {
    final august = Completer<List<MatchHistoryItem>>();
    final september = Completer<List<MatchHistoryItem>>();
    final repository = _FakeMatchHistoryRepository(
      handler: (query) =>
          query.startDate!.month == 8 ? august.future : september.future,
    );

    await pumpScreenWithoutSettling(tester, historyRepository: repository);
    expect(find.text('試合一覧を読み込み中です'), findsOneWidget);

    await tester.tap(find.byTooltip('翌月'));
    await tester.pump();
    september.complete([
      _historyItem(secondMatchId, opponentName: '9月の相手'),
    ]);
    await tester.pumpAndSettle();
    expect(find.text('vs 9月の相手'), findsOneWidget);

    august.complete([
      _historyItem(firstMatchId, opponentName: '8月の相手'),
    ]);
    await tester.pumpAndSettle();
    expect(find.text('vs 9月の相手'), findsOneWidget);
    expect(find.text('vs 8月の相手'), findsNothing);
  });

  testWidgets('loads detail with match and user IDs then shows fetched data',
      (tester) async {
    final detailResponse = Completer<MatchDetail>();
    final detailRepository = _FakeMatchDetailRepository(
      handler: (_, __) => detailResponse.future,
    );
    await pumpScreen(
      tester,
      historyRepository: _immediateHistoryRepository(
        personalMemo: '一覧で取得済みのメモ',
      ),
      detailRepository: detailRepository,
      screenSize: const Size(800, 1600),
    );

    await tester.tap(find.text('vs 西やん'));
    await tester.pump();

    expect(detailRepository.receivedMatchIds, [firstMatchId]);
    expect(detailRepository.receivedUserIds, [currentUserId]);
    expect(find.text('試合詳細を読み込み中です'), findsOneWidget);

    detailResponse.complete(
      _detail(
        firstMatchId,
        matchDate: DateTime(2026, 9, 6),
        setScores: const [
          MatchSetScore(
            myScore: 7,
            opponentScore: 6,
            myTiebreakScore: 8,
            opponentTiebreakScore: 6,
          ),
        ],
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(MatchDetailSheet), findsOneWidget);
    expect(find.text('西やん'), findsWidgets);
    expect(
      find.descendant(
        of: find.byType(MatchDetailSheet),
        matching: find.text('WIN'),
      ),
      findsOneWidget,
    );
    expect(find.text('2026年9月6日（日）'), findsOneWidget);
    expect(find.text('7 (8-6)'), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(MatchDetailSheet),
        matching: find.text('6'),
      ),
      findsOneWidget,
    );
    expect(find.text('2026年8月24日（月）'), findsNothing);
    expect(find.text('一覧で取得済みのメモ'), findsOneWidget);
  });

  testWidgets('shows a detail error and succeeds after retry', (tester) async {
    final retryResponse = Completer<MatchDetail>();
    var attempts = 0;
    final detailRepository = _FakeMatchDetailRepository(
      handler: (_, __) {
        attempts++;
        if (attempts == 1) return Future.error(Exception('detail failed'));
        return retryResponse.future;
      },
    );
    await pumpScreen(
      tester,
      historyRepository: _immediateHistoryRepository(),
      detailRepository: detailRepository,
    );

    await tester.ensureVisible(find.text('vs 西やん'));
    await tester.tap(find.text('vs 西やん'));
    await tester.pumpAndSettle();
    expect(find.text('試合詳細の取得に失敗しました'), findsOneWidget);
    expect(find.byIcon(Icons.close), findsOneWidget);

    await tester.ensureVisible(find.text('再試行'));
    await tester.tap(find.text('再試行'));
    await tester.pump();
    expect(find.text('試合詳細を読み込み中です'), findsOneWidget);
    retryResponse.complete(_detail(firstMatchId));
    await tester.pumpAndSettle();
    expect(find.byType(MatchDetailSheet), findsOneWidget);
  });

  testWidgets('saves a memo through MatchMemoService and reuses it',
      (tester) async {
    final memoRepository = _FakeMatchMemoRepository();
    await pumpScreen(
      tester,
      historyRepository: _immediateHistoryRepository(),
      memoRepository: memoRepository,
      screenSize: const Size(800, 1600),
    );

    await tester.tap(find.text('vs 西やん'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('メモはまだありません'));
    await tester.pump();
    await tester.enterText(find.byType(TextField), '更新後のメモ');
    await tester.tap(find.text('保存する'));
    await tester.pumpAndSettle();

    expect(memoRepository.savedMemo, '更新後のメモ');
    expect(find.byType(MatchDetailSheet), findsNothing);

    await tester.tap(find.text('vs 西やん'));
    await tester.pumpAndSettle();
    expect(find.text('更新後のメモ'), findsOneWidget);
  });

  testWidgets('keeps the editor open when memo persistence fails',
      (tester) async {
    await pumpScreen(
      tester,
      historyRepository: _immediateHistoryRepository(),
      memoRepository: _FakeMatchMemoRepository(shouldFail: true),
      screenSize: const Size(800, 1600),
    );

    await tester.tap(find.text('vs 西やん'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('メモはまだありません'));
    await tester.pump();
    await tester.enterText(find.byType(TextField), '消さない入力');
    await tester.tap(find.text('保存する'));
    await tester.pumpAndSettle();

    expect(find.byType(MatchMemoField), findsOneWidget);
    expect(find.text('消さない入力'), findsOneWidget);
    expect(find.text('メモの保存に失敗しました。もう一度お試しください'), findsOneWidget);
  });

  testWidgets('prevents dismissing the screen modal while memo save is pending',
      (tester) async {
    final saveCompleter = Completer<void>();
    final memoRepository = _FakeMatchMemoRepository(
      upsertCompleter: saveCompleter,
    );
    await pumpScreen(
      tester,
      historyRepository: _immediateHistoryRepository(),
      memoRepository: memoRepository,
      screenSize: const Size(800, 1600),
    );

    await tester.tap(find.text('vs 西やん'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('メモはまだありません'));
    await tester.pump();
    await tester.enterText(find.byType(TextField), '保存待ちのメモ');
    await tester.tap(find.text('保存する'));
    await tester.pump();

    final closeButton = tester.widget<IconButton>(
      find.widgetWithIcon(IconButton, Icons.close),
    );
    expect(closeButton.onPressed, isNull);
    expect(find.text('保存中...'), findsOneWidget);

    await tester.tapAt(const Offset(5, 5));
    await tester.pump();
    expect(find.byType(MatchDetailSheet), findsOneWidget);

    await tester.binding.handlePopRoute();
    await tester.pump();
    expect(find.byType(MatchDetailSheet), findsOneWidget);

    saveCompleter.complete();
    await tester.pumpAndSettle();

    expect(memoRepository.savedMemo, '保存待ちのメモ');
    expect(find.byType(MatchDetailSheet), findsNothing);
    expect(find.byType(MatchHistoryScreen), findsOneWidget);
    expect(find.text('2026年8月'), findsOneWidget);
  });

  testWidgets('keeps selection and prevents duplicate detail requests',
      (tester) async {
    final detailResponse = Completer<MatchDetail>();
    final detailRepository = _FakeMatchDetailRepository(
      handler: (_, __) => detailResponse.future,
    );
    await pumpScreen(
      tester,
      historyRepository: _immediateHistoryRepository(twoMatches: true),
      detailRepository: detailRepository,
      screenSize: const Size(390, 700),
    );

    await tester.tap(find.byKey(const ValueKey('match-calendar-day-24')));
    await tester.pump();
    final card = find.text('vs 西やん');
    await tester.ensureVisible(card);
    final scrollable = find.descendant(
      of: find.byType(SingleChildScrollView),
      matching: find.byType(Scrollable),
    );
    final scrollPositionBeforeDetail =
        tester.state<ScrollableState>(scrollable).position.pixels;
    await tester.tap(card);
    await tester.tap(card, warnIfMissed: false);
    await tester.pump();
    expect(detailRepository.receivedMatchIds, [firstMatchId]);

    detailResponse.complete(_detail(firstMatchId));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.close));
    await tester.pumpAndSettle();

    expect(find.text('2026年8月'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('match-calendar-selected-24')),
      findsOneWidget,
    );
    expect(
      tester.state<ScrollableState>(scrollable).position.pixels,
      scrollPositionBeforeDetail,
    );
  });

  testWidgets('shows a month fetch error and retries', (tester) async {
    var attempts = 0;
    final repository = _FakeMatchHistoryRepository(
      handler: (_) async {
        attempts++;
        if (attempts == 1) throw Exception('month failed');
        return [_historyItem(firstMatchId)];
      },
    );
    await pumpScreen(tester, historyRepository: repository);

    expect(find.text('試合一覧の取得に失敗しました'), findsOneWidget);
    await tester.ensureVisible(find.text('再試行'));
    await tester.tap(find.text('再試行'));
    await tester.pumpAndSettle();
    expect(find.text('vs 西やん'), findsOneWidget);
  });

  testWidgets('scrolls without overflow on a small smartphone', (tester) async {
    await pumpScreen(
      tester,
      historyRepository: _immediateHistoryRepository(twoMatches: true),
      screenSize: const Size(320, 568),
    );

    await tester.drag(
      find.byType(SingleChildScrollView),
      const Offset(0, -700),
    );
    await tester.pumpAndSettle();
    expect(find.text('vs ピンちゃん'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

Future<void> pumpScreenWithoutSettling(
  WidgetTester tester, {
  required MatchHistoryRepository historyRepository,
}) async {
  final historyService = MatchHistoryService(repository: historyRepository);
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.lightTheme,
      home: MatchHistoryScreen(
        initialMonth: DateTime(2026, 8),
        currentUserId: currentUserId,
        matchHistoryService: historyService,
        matchDetailService: MatchDetailService(
          repository: _FakeMatchDetailRepository(
            handler: (_, __) async => _detail(firstMatchId),
          ),
        ),
        matchMemoService: MatchMemoService(
          repository: _FakeMatchMemoRepository(),
          matchHistoryService: historyService,
        ),
      ),
    ),
  );
  await tester.pump();
}

_FakeMatchHistoryRepository _immediateHistoryRepository({
  String? personalMemo,
  bool twoMatches = false,
}) {
  return _FakeMatchHistoryRepository(
    handler: (_) async => [
      _historyItem(firstMatchId, personalMemo: personalMemo),
      if (twoMatches) _historyItem(secondMatchId, opponentName: 'ピンちゃん'),
    ],
  );
}

MatchHistoryItem _historyItem(
  String matchId, {
  String opponentName = '西やん',
  String? personalMemo,
}) {
  return MatchHistoryItem(
    matchId: matchId,
    matchDate: DateTime(2026, 8, matchId == firstMatchId ? 24 : 18),
    currentUserName: 'たけし',
    opponentName: opponentName,
    scoreText: '6-4',
    isWin: true,
    setScores: const [MatchSetScore(myScore: 6, opponentScore: 4)],
    personalMemo: personalMemo,
  );
}

MatchDetail _detail(
  String matchId, {
  DateTime? matchDate,
  List<MatchSetScore>? setScores,
}) {
  final detailScores = setScores ??
      const [
        MatchSetScore(myScore: 6, opponentScore: 4),
      ];
  return MatchDetail(
    historyItem: MatchHistoryItem(
      matchId: matchId,
      matchDate: matchDate ?? DateTime(2026, 8, 24),
      currentUserName: 'たけし',
      opponentName: '西やん',
      scoreText: detailScores.map((score) => score.displayScore).join(', '),
      isWin: true,
      setScores: detailScores,
    ),
    currentUserId: currentUserId,
    opponentId: opponentId,
    winnerId: currentUserId,
    participants: const [
      MatchDetailParticipant(userId: currentUserId, displayName: 'たけし'),
      MatchDetailParticipant(userId: opponentId, displayName: '西やん'),
    ],
    sets: [
      for (var index = 0; index < detailScores.length; index++)
        MatchDetailSet(
          setNumber: index + 1,
          score: detailScores[index],
          winnerId: currentUserId,
        ),
    ],
  );
}

class _FakeMatchHistoryRepository implements MatchHistoryRepository {
  final Future<List<MatchHistoryItem>> Function(MatchHistoryQuery query)
      handler;

  _FakeMatchHistoryRepository({required this.handler});

  @override
  Future<List<MatchHistoryItem>> fetchMatches(MatchHistoryQuery query) {
    return handler(query);
  }

  @override
  Future<List<MatchHistoryItem>> fetchRecentMatches(String currentUserId) {
    return handler(MatchHistoryQuery.recent(currentUserId));
  }
}

class _FakeMatchDetailRepository implements MatchDetailRepository {
  final Future<MatchDetail> Function(String matchId, String currentUserId)
      handler;
  final List<String> receivedMatchIds = [];
  final List<String> receivedUserIds = [];

  _FakeMatchDetailRepository({required this.handler});

  @override
  Future<MatchDetail> fetchMatchDetail({
    required String matchId,
    required String currentUserId,
  }) {
    receivedMatchIds.add(matchId);
    receivedUserIds.add(currentUserId);
    return handler(matchId, currentUserId);
  }
}

class _FakeMatchMemoRepository implements MatchMemoRepository {
  final bool shouldFail;
  final Completer<void>? upsertCompleter;
  String? savedMemo;

  _FakeMatchMemoRepository({
    this.shouldFail = false,
    this.upsertCompleter,
  });

  @override
  Future<void> deletePersonalMemo({
    required String matchId,
    required String userId,
  }) async {
    if (shouldFail) throw Exception('delete failed');
    savedMemo = null;
  }

  @override
  Future<void> upsertPersonalMemo({
    required String matchId,
    required String userId,
    required String memo,
  }) async {
    if (shouldFail) throw Exception('upsert failed');
    if (upsertCompleter != null) await upsertCompleter!.future;
    savedMemo = memo;
  }
}
