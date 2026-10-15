import 'match_history_item.dart';

/// 取得済みの試合集合から期間に依存せず集計した戦績。
class UserStats {
  final int wins;
  final int losses;
  final int totalMatches;

  const UserStats({
    required this.wins,
    required this.losses,
    int? totalMatches,
  }) : totalMatches = totalMatches ?? wins + losses;

  factory UserStats.fromMatches(Iterable<MatchHistoryItem> matches) {
    var wins = 0;
    var losses = 0;
    var totalMatches = 0;

    for (final match in matches) {
      totalMatches++;
      if (match.isWin == true) {
        wins++;
      } else if (match.isWin == false) {
        losses++;
      }
    }

    return UserStats(
      wins: wins,
      losses: losses,
      totalMatches: totalMatches,
    );
  }

  int get winRatePercentage {
    final decidedMatches = wins + losses;
    if (decidedMatches == 0) {
      return 0;
    }

    return (wins / decidedMatches * 100).round();
  }
}
