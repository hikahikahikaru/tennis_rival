import 'package:flutter/material.dart';

import '../constants/app_sizes.dart';
import '../constants/app_strings.dart';
import '../constants/app_text_styles.dart';
import '../models/user_stats.dart';
import '../widgets/match_calendar.dart';
import '../widgets/match_card.dart';
import '../widgets/stats_card.dart';

/// 共通部品を配置し、表示月と選択日のUI状態だけを管理する戦績画面。
class MatchHistoryScreen extends StatefulWidget {
  final DateTime? initialMonth;

  const MatchHistoryScreen({
    super.key,
    this.initialMonth,
  });

  // DB・月次集計との接続前に画面構成を確認するための仮データ。
  static const UserStats _sampleStats = UserStats(wins: 2, losses: 2);
  static const List<_SampleMatch> _sampleMatches = [
    _SampleMatch(
      date: '8月24日',
      opponentName: '西やん',
      score: '6-4, 6-3',
      isWin: true,
    ),
    _SampleMatch(
      date: '8月18日',
      opponentName: 'ピンちゃん',
      score: '4-6, 7-5, 10-8',
      isWin: true,
    ),
  ];

  @override
  State<MatchHistoryScreen> createState() => _MatchHistoryScreenState();
}

class _MatchHistoryScreenState extends State<MatchHistoryScreen> {
  late DateTime _displayedMonth;
  DateTime? _selectedDate;

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
    );
  }

  Widget _buildMatchCard(_SampleMatch match) {
    return MatchCard(
      date: match.date,
      opponentName: match.opponentName,
      score: match.score,
      isWin: match.isWin,
    );
  }
}

class _SampleMatch {
  final String date;
  final String opponentName;
  final String score;
  final bool? isWin;

  const _SampleMatch({
    required this.date,
    required this.opponentName,
    required this.score,
    required this.isWin,
  });
}
