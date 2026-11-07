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

  /// 試合日の期間（両端を含む）。nullの側は無制限。
  final DateTime? from;
  final DateTime? to;

  const MatchSortCondition({
    this.result = MatchResultFilter.all,
    this.order = MatchDateOrder.newestFirst,
    this.from,
    this.to,
  });

  MatchSortCondition copyWith({
    MatchResultFilter? result,
    MatchDateOrder? order,
    DateTime? from,
    DateTime? to,
    bool clearFrom = false,
    bool clearTo = false,
  }) {
    return MatchSortCondition(
      result: result ?? this.result,
      order: order ?? this.order,
      from: clearFrom ? null : (from ?? this.from),
      to: clearTo ? null : (to ?? this.to),
    );
  }

  List<T> apply<T>(
    Iterable<T> items, {
    required DateTime Function(T item) dateOf,
    required bool Function(T item) isWinOf,
  }) {
    DateTime dayOf(DateTime d) => DateTime(d.year, d.month, d.day);
    final filtered = items.where((item) {
      if (!result.includes(isWinOf(item))) return false;
      final day = dayOf(dateOf(item));
      if (from != null && day.isBefore(dayOf(from!))) return false;
      if (to != null && day.isAfter(dayOf(to!))) return false;
      return true;
    }).toList();
    filtered.sort((a, b) {
      final compared = dateOf(a).compareTo(dateOf(b));
      return order == MatchDateOrder.newestFirst ? -compared : compared;
    });
    return filtered;
  }
}
