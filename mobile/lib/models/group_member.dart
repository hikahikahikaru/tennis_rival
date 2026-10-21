/// グループ内のメンバーと、そのメンバーのグループ内戦績。
class GroupMember {
  final String id;
  final String name;
  final bool isAdmin;
  final int wins;
  final int losses;

  const GroupMember({
    required this.id,
    required this.name,
    required this.wins,
    required this.losses,
    this.isAdmin = false,
  });

  int get totalMatches => wins + losses;

  int get winRatePercentage {
    final total = totalMatches;
    if (total == 0) {
      return 0;
    }
    return (wins * 100 / total).round();
  }
}
