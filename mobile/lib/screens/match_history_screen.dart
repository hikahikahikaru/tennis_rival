import 'package:flutter/material.dart';

import '../constants/app_nav_items.dart';
import '../constants/app_sizes.dart';
import '../constants/app_strings.dart';
import '../constants/app_text_styles.dart';
import '../models/match_format.dart';
import '../models/match_history_item.dart';
import '../models/match_set_score.dart';
import '../models/user_stats.dart';
import '../widgets/bottom_nav_bar.dart';
import '../widgets/match_calendar.dart';
import '../widgets/match_card.dart';
import '../widgets/match_detail_sheet.dart';
import '../widgets/stats_card.dart';
import 'match_entry_screen.dart';

/// 共通部品を配置し、表示月と選択日のUI状態だけを管理する戦績画面。
class MatchHistoryScreen extends StatefulWidget {
  final DateTime? initialMonth;

  const MatchHistoryScreen({
    super.key,
    this.initialMonth,
  });

  // DB・月次集計との接続前に画面構成を確認するための仮データ。
  static const UserStats _sampleStats = UserStats(wins: 2, losses: 2);

  static final List<MatchHistoryItem> _sampleMatches = [
    MatchHistoryItem(
      matchDate: DateTime(2026, 8, 24),
      opponentName: '西やん',
      scoreText: '6-4, 6-3',
      isWin: true,
      matchFormat: MatchFormat.threeSets,
      setScores: const [
        MatchSetScore(myScore: 6, opponentScore: 4),
        MatchSetScore(myScore: 6, opponentScore: 3),
      ],
      personalMemo: 'モック値',
    ),
    MatchHistoryItem(
      matchDate: DateTime(2026, 8, 16),
      opponentName: 'ピンちゃん',
      scoreText: '4-6, 7-5, 10-8',
      isWin: true,
      matchFormat: MatchFormat.threeSets,
      setScores: const [
        MatchSetScore(myScore: 4, opponentScore: 6),
        MatchSetScore(myScore: 7, opponentScore: 5),
        MatchSetScore(myScore: 10, opponentScore: 8),
      ],
      personalMemo: 'モック値',
    ),
  ];

  @override
  State<MatchHistoryScreen> createState() => _MatchHistoryScreenState();
}

class _MatchHistoryScreenState extends State<MatchHistoryScreen> {
  late DateTime _displayedMonth;
  DateTime? _selectedDate;
  var _isMatchDetailOpen = false;

  @override
  void initState() {
    super.initState();
    final initialMonth = widget.initialMonth ?? DateTime.now();
    _displayedMonth = DateTime(initialMonth.year, initialMonth.month);
  }

  List<DateTime> get _sampleMatchDates => [
        DateTime(_displayedMonth.year, _displayedMonth.month, 16),
        DateTime(_displayedMonth.year, _displayedMonth.month, 24),
      ];

  void _changeMonth(DateTime month) {
    setState(() {
      _displayedMonth = month;
      _selectedDate = null;
    });
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

    _isMatchDetailOpen = true;
    try {
      await MatchDetailSheet.show(
        context,
        match: match,
        // メモ保存は別Issueのため、入力値をそのまま返す。
        onSaveMemo: (memo) async => memo,
      );
    } finally {
      _isMatchDetailOpen = false;
    }
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
                matchDates: _sampleMatchDates,
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
              for (var index = 0;
                  index < MatchHistoryScreen._sampleMatches.length;
                  index++) ...[
                _buildMatchCard(MatchHistoryScreen._sampleMatches[index]),
                if (index != MatchHistoryScreen._sampleMatches.length - 1)
                  const SizedBox(height: AppSizes.scoreHeaderSpacing),
              ],
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
