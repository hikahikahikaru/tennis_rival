/// グループ詳細画面の上部に表示する、グループの詳細情報。
class GroupDetail {
  final String id;
  final String name;
  final String description;
  final DateTime createdAt;
  final String adminName;
  final String inviteCode;
  final int memberCount;

  const GroupDetail({
    required this.id,
    required this.name,
    required this.description,
    required this.createdAt,
    required this.adminName,
    required this.inviteCode,
    required this.memberCount,
  });

  String get createdDateText =>
      '${createdAt.year}年${createdAt.month}月${createdAt.day}日';
}
