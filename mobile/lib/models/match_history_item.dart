/// ホーム画面の最近の試合へ表示する、閲覧者視点へ変換済みの試合履歴。
class MatchHistoryItem {
  final DateTime matchDate;
  final String opponentName;
  final String scoreText;
  final bool? isWin;

  const MatchHistoryItem({
    required this.matchDate,
    required this.opponentName,
    required this.scoreText,
    required this.isWin,
  });
}
