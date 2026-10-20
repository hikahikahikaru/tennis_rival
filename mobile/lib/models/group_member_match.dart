/// メンバー個人の視点で見た、グループ内の試合1件。
class GroupMemberMatch {
  final String id;
  final DateTime matchDate;
  final String opponentName;
  final String scoreText;
  final bool isWin;

  const GroupMemberMatch({
    required this.id,
    required this.matchDate,
    required this.opponentName,
    required this.scoreText,
    required this.isWin,
  });

  String get dateText =>
      '${matchDate.year}年${matchDate.month}月${matchDate.day}日';
}
