import 'package:flutter/material.dart';

import '../constants/app_strings.dart';

/// 試合の勝敗による絞り込み種別。
enum MatchResultFilter {
  all,
  wins,
  losses;

  String get label => switch (this) {
        MatchResultFilter.all => AppStrings.matchSortResultAll,
        MatchResultFilter.wins => AppStrings.matchSortResultWins,
        MatchResultFilter.losses => AppStrings.matchSortResultLosses,
      };

  bool includes(bool isWin) => switch (this) {
        MatchResultFilter.all => true,
        MatchResultFilter.wins => isWin,
        MatchResultFilter.losses => !isWin,
      };
}

/// 試合日の並び順。
enum MatchDateOrder {
  newestFirst,
  oldestFirst;

  String get label => switch (this) {
        MatchDateOrder.newestFirst => AppStrings.matchSortOrderNewest,
        MatchDateOrder.oldestFirst => AppStrings.matchSortOrderOldest,
      };
}

/// 試合一覧の絞り込み・並び替え条件。試合の型に依存せず再利用できる。
class MatchSortCondition {
  final MatchResultFilter result;
  final MatchDateOrder order;

  /// 試合日の期間（両端を含む）。nullの場合は期間指定なし。
  final DateTimeRange? period;

  const MatchSortCondition({
    this.result = MatchResultFilter.all,
    this.order = MatchDateOrder.newestFirst,
    this.period,
  });

  MatchSortCondition copyWith({
    MatchResultFilter? result,
    MatchDateOrder? order,
    DateTimeRange? period,
    bool clearPeriod = false,
  }) {
    return MatchSortCondition(
      result: result ?? this.result,
      order: order ?? this.order,
      period: clearPeriod ? null : (period ?? this.period),
    );
  }

  List<T> apply<T>(
    Iterable<T> items, {
    required DateTime Function(T item) dateOf,
    required bool Function(T item) isWinOf,
  }) {
    DateTime dayOf(DateTime d) => DateTime(d.year, d.month, d.day);
    final range = period;
    final filtered = items.where((item) {
      if (!result.includes(isWinOf(item))) return false;
      if (range == null) return true;
      final day = dayOf(dateOf(item));
      return !day.isBefore(dayOf(range.start)) &&
          !day.isAfter(dayOf(range.end));
    }).toList();
    filtered.sort((a, b) {
      final compared = dateOf(a).compareTo(dateOf(b));
      return order == MatchDateOrder.newestFirst ? -compared : compared;
    });
    return filtered;
  }
}
