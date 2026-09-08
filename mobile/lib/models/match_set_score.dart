class MatchSetScore {
  final int myScore;
  final int opponentScore;
  final int? myTiebreakScore;
  final int? opponentTiebreakScore;

  const MatchSetScore({
    required this.myScore,
    required this.opponentScore,
    this.myTiebreakScore,
    this.opponentTiebreakScore,
  });

  bool get isMyWin => myScore > opponentScore;

  bool get hasTiebreak {
    final isTiebreakScore = (myScore == 7 && opponentScore == 6) ||
        (myScore == 6 && opponentScore == 7);

    return isTiebreakScore &&
        myTiebreakScore != null &&
        opponentTiebreakScore != null;
  }

  String get displayScore {
    final scoreText = '$myScore-$opponentScore';

    if (!hasTiebreak) {
      return scoreText;
    }

    return '$scoreText ($myTiebreakScore-$opponentTiebreakScore)';
  }
}
