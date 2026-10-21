/// グループ一覧に表示するグループの概要。
class GroupSummary {
  final String id;
  final String name;
  final int memberCount;

  const GroupSummary({
    required this.id,
    required this.name,
    required this.memberCount,
  });
}
