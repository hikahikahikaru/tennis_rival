import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import '../constants/app_nav_items.dart';
import '../constants/app_sizes.dart';
import '../constants/app_strings.dart';
import '../constants/app_text_styles.dart';
import '../mocks/mock_data.dart';
import '../models/match_detail.dart';
import '../models/match_history_item.dart';
import '../models/user_stats.dart';
import '../services/match_detail_service.dart';
import '../services/match_history_service.dart';
import '../services/match_memo_service.dart';
import '../widgets/bottom_nav_bar.dart';
import '../widgets/match_calendar.dart';
import '../widgets/match_card.dart';
import '../widgets/match_detail_sheet.dart';
import '../widgets/stats_card.dart';
import 'match_entry_screen.dart';

/// 月別履歴の取得状態と、表示月・選択日を管理する戦績画面。
class MatchHistoryScreen extends StatefulWidget {
  final DateTime? initialMonth;
  final MatchHistoryService? matchHistoryService;
  final MatchDetailService? matchDetailService;
  final MatchMemoService? matchMemoService;
  final String? currentUserId;

  const MatchHistoryScreen({
    super.key,
    this.initialMonth,
    this.matchHistoryService,
    this.matchDetailService,
    this.matchMemoService,
    this.currentUserId,
  });

  // 月次集計は後続Issueのため、サマリーのみ仮データを維持する。
  static const UserStats _sampleStats = UserStats(wins: 2, losses: 2);

  @override
  State<MatchHistoryScreen> createState() => _MatchHistoryScreenState();
}

class _MatchHistoryScreenState extends State<MatchHistoryScreen> {
  late MatchHistoryService _matchHistoryService;
  late MatchDetailService _matchDetailService;
  late MatchMemoService _matchMemoService;
  late String _currentUserId;
  late DateTime _displayedMonth;
  DateTime? _selectedDate;
  List<MatchHistoryItem> _matches = const [];
  Object? _matchesError;
  var _isMatchesLoading = true;
  var _isMatchDetailOpen = false;
  var _matchesRequestId = 0;

  @override
  void initState() {
    super.initState();
    _setDependencies();
    final initialMonth = widget.initialMonth ?? DateTime.now();
    _displayedMonth = DateTime(initialMonth.year, initialMonth.month);
    _loadMatchesForDisplayedMonth();
  }

  @override
  void didUpdateWidget(covariant MatchHistoryScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.matchHistoryService != widget.matchHistoryService ||
        oldWidget.matchDetailService != widget.matchDetailService ||
        oldWidget.matchMemoService != widget.matchMemoService ||
        oldWidget.currentUserId != widget.currentUserId) {
      _setDependencies();
      _loadMatchesForDisplayedMonth();
    }
  }

  void _setDependencies() {
    _matchHistoryService =
        widget.matchHistoryService ?? MatchHistoryService.instance;
    _matchDetailService =
        widget.matchDetailService ?? MatchDetailService.instance;
    _matchMemoService = widget.matchMemoService ??
        MatchMemoService(matchHistoryService: _matchHistoryService);
    _currentUserId = widget.currentUserId ?? MockData.currentUserId;
  }

  List<DateTime> get _matchDates =>
      _matches.map((match) => match.matchDate).toList(growable: false);

  Future<void> _loadMatchesForDisplayedMonth() async {
    // 月切り替えが連続しても、古い月の応答で最新表示を上書きしない。
    final requestId = ++_matchesRequestId;
    final requestedMonth = _displayedMonth;
    setState(() {
      _isMatchesLoading = true;
      _matchesError = null;
      _matches = const [];
    });

    try {
      final matches = await _matchHistoryService.loadMatchesByMonth(
        currentUserId: _currentUserId,
        year: requestedMonth.year,
        month: requestedMonth.month,
      );
      if (!mounted || requestId != _matchesRequestId) return;
      setState(() {
        _matches = matches;
        _isMatchesLoading = false;
      });
    } catch (error) {
      if (!mounted || requestId != _matchesRequestId) return;
      setState(() {
        _matchesError = error;
        _isMatchesLoading = false;
      });
    }
  }

  void _changeMonth(DateTime month) {
    setState(() {
      _displayedMonth = month;
      _selectedDate = null;
    });
    _loadMatchesForDisplayedMonth();
  }

  void _selectDate(DateTime date) {
    setState(() => _selectedDate = date);
  }

  int get _statsNavIndex {
    return appNavItems.indexWhere((item) => item.label == AppStrings.navStats);
  }

  void _openMatchEntryScreen() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const MatchEntryScreen(),
      ),
    );
  }

  Future<void> _showMatchDetail(MatchHistoryItem match) async {
    if (_isMatchDetailOpen) return;

    final matchId = match.matchId;
    if (matchId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(AppStrings.matchDetailIdMissing)),
      );
      return;
    }

    _isMatchDetailOpen = true;
    try {
      await showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        enableDrag: false,
        backgroundColor: Colors.transparent,
        builder: (_) => _MatchDetailLoader(
          matchId: matchId,
          currentUserId: _currentUserId,
          selectedMatch: match,
          matchDetailService: _matchDetailService,
          onSaveMemo: (memo) => _savePersonalMemo(match, memo),
        ),
      );
    } finally {
      _isMatchDetailOpen = false;
    }
  }

  Future<String?> _savePersonalMemo(
    MatchHistoryItem match,
    String memo,
  ) async {
    final matchId = match.matchId;
    if (matchId == null) {
      throw StateError('A match ID is required to save a personal memo.');
    }

    final savedMemo = await _matchMemoService.savePersonalMemo(
      matchId: matchId,
      userId: _currentUserId,
      memo: memo,
    );
    if (!mounted) return savedMemo;

    setState(() {
      _matches = [
        for (final item in _matches)
          if (item.matchId == matchId)
            item.copyWithPersonalMemo(savedMemo)
          else
            item,
      ];
    });
    return savedMemo;
  }

  void _handleBottomNavTap(int index) {
    final selectedItem = appNavItems[index];

    if (selectedItem.label == AppStrings.navStats) {
      return;
    }

    if (selectedItem.label == AppStrings.navHome) {
      Navigator.pop(context);
      return;
    }

    if (selectedItem.label == AppStrings.navEntry) {
      _openMatchEntryScreen();
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text(AppStrings.homeNavUnavailable)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.navStats),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSizes.screenPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const StatsCard(
                stats: MatchHistoryScreen._sampleStats,
                title: AppStrings.matchHistoryStatsTitle,
              ),
              const SizedBox(height: AppSizes.spacingLarge),
              MatchCalendar(
                displayedMonth: _displayedMonth,
                matchDates: _matchDates,
                selectedDate: _selectedDate,
                onDateSelected: _selectDate,
                onMonthChanged: _changeMonth,
              ),
              const SizedBox(height: AppSizes.spacingLarge),
              const Text(
                AppStrings.matchHistoryMatchListTitle,
                style: AppTextStyles.homeSectionTitle,
              ),
              const SizedBox(height: AppSizes.scoreSectionSpacing),
              _buildMatchList(),
            ],
          ),
        ),
      ),
      bottomNavigationBar: CustomBottomNavBar(
        currentIndex: _statsNavIndex,
        onTap: _handleBottomNavTap,
      ),
    );
  }

  Widget _buildMatchList() {
    if (_isMatchesLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: AppSizes.spacingLarge),
          child: Column(
            children: [
              CircularProgressIndicator(),
              SizedBox(height: AppSizes.spacingMedium),
              Text(
                AppStrings.matchHistoryMatchesLoading,
                style: AppTextStyles.opponentPickerEmpty,
              ),
            ],
          ),
        ),
      );
    }

    if (_matchesError != null) {
      return Center(
        child: Column(
          children: [
            const Text(
              AppStrings.matchHistoryMatchesFetchFailed,
              style: AppTextStyles.opponentPickerError,
            ),
            const SizedBox(height: AppSizes.spacingSmall),
            OutlinedButton(
              onPressed: _loadMatchesForDisplayedMonth,
              child: const Text(AppStrings.retry),
            ),
          ],
        ),
      );
    }

    if (_matches.isEmpty) {
      return const Text(
        AppStrings.matchHistoryMatchesEmpty,
        style: AppTextStyles.opponentPickerEmpty,
      );
    }

    return Column(
      children: [
        for (var index = 0; index < _matches.length; index++) ...[
          _buildMatchCard(_matches[index]),
          if (index != _matches.length - 1)
            const SizedBox(height: AppSizes.scoreHeaderSpacing),
        ],
      ],
    );
  }

  Widget _buildMatchCard(MatchHistoryItem match) {
    return MatchCard(
      date: match.displayDate,
      opponentName: match.opponentName,
      score: match.scoreText,
      isWin: match.isWin,
      onTap: () => _showMatchDetail(match),
    );
  }
}

class _MatchDetailLoader extends StatefulWidget {
  final String matchId;
  final String currentUserId;
  final MatchHistoryItem selectedMatch;
  final MatchDetailService matchDetailService;
  final Future<String?> Function(String memo) onSaveMemo;

  const _MatchDetailLoader({
    required this.matchId,
    required this.currentUserId,
    required this.selectedMatch,
    required this.matchDetailService,
    required this.onSaveMemo,
  });

  @override
  State<_MatchDetailLoader> createState() => _MatchDetailLoaderState();
}

class _MatchDetailLoaderState extends State<_MatchDetailLoader> {
  MatchDetail? _detail;
  Object? _error;
  var _isLoading = true;
  var _requestId = 0;

  @override
  void initState() {
    super.initState();
    _loadDetail(updateStateBeforeLoad: false);
  }

  Future<void> _loadDetail({bool updateStateBeforeLoad = true}) async {
    final requestId = ++_requestId;
    if (updateStateBeforeLoad) {
      setState(() {
        _isLoading = true;
        _error = null;
      });
    }

    try {
      final detail = await widget.matchDetailService.loadMatchDetail(
        matchId: widget.matchId,
        currentUserId: widget.currentUserId,
      );
      if (!mounted || requestId != _requestId) return;
      setState(() {
        _detail = detail;
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted || requestId != _requestId) return;
      setState(() {
        _error = error;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final detail = _detail;
    if (!_isLoading && _error == null && detail != null) {
      final sheetItem = detail.historyItem.copyWithPersonalMemo(
        widget.selectedMatch.personalMemo,
      );
      return MatchDetailSheet(
        match: sheetItem,
        onSaveMemo: widget.onSaveMemo,
      );
    }

    return SafeArea(
      child: Container(
        padding: const EdgeInsets.all(AppSizes.bottomSheetPadding),
        decoration: const BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppSizes.bottomSheetRadius),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: IconButton(
                tooltip: AppStrings.matchDetailClose,
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close),
              ),
            ),
            if (_isLoading) ...[
              const CircularProgressIndicator(),
              const SizedBox(height: AppSizes.spacingMedium),
              const Text(
                AppStrings.matchDetailLoading,
                style: AppTextStyles.opponentPickerEmpty,
              ),
            ] else ...[
              const Icon(
                Icons.error_outline,
                size: AppSizes.bottomSheetErrorIconSize,
                color: AppColors.matchLose,
              ),
              const SizedBox(height: AppSizes.bottomSheetErrorSpacing),
              const Text(
                AppStrings.matchDetailFetchFailed,
                style: AppTextStyles.opponentPickerError,
              ),
              const SizedBox(height: AppSizes.spacingMedium),
              OutlinedButton(
                onPressed: _loadDetail,
                child: const Text(AppStrings.retry),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
