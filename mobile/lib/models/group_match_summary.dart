/// グループ内で行われた試合の概要。
class GroupMatchSummary {
  final String id;
  final DateTime matchDate;
  final String player1Name;
  final String player2Name;
  final String winnerName;
  final String scoreText;

  const GroupMatchSummary({
    required this.id,
    required this.matchDate,
    required this.player1Name,
    required this.player2Name,
    required this.winnerName,
    required this.scoreText,
  });

  String get dateText =>
      '${matchDate.year}年${matchDate.month}月${matchDate.day}日';
}
