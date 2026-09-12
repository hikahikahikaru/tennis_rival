class UserStats {
  final int wins;
  final int losses;

  const UserStats({
    required this.wins,
    required this.losses,
  });

  int get totalMatches => wins + losses;

  int get winRatePercentage {
    if (totalMatches == 0) {
      return 0;
    }

    return (wins / totalMatches * 100).round();
  }
}
