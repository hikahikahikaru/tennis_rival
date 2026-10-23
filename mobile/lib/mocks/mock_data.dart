import '../models/group_detail.dart';
import '../models/group_match_summary.dart';
import '../models/group_member.dart';
import '../models/group_member_match.dart';
import '../models/group_summary.dart';
import '../models/user_model.dart';

/// 開発・モック用の仮データをまとめたクラス
///
/// 認証機能（ログイン機能）の実装前や、UI開発時のダミーデータ、
/// seed.sql に登録されている初期データを定義します。
class MockData {
  MockData._();

  /// 仮ログインユーザー情報（supabase/seed.sql の「たけし」）
  static const UserModel currentUser = UserModel(
    id: '11111111-1111-1111-1111-111111111111',
    name: 'たけし',
  );

  /// 仮ログインユーザーのID（UUID）
  static String get currentUserId => currentUser.id;

  /// 切り替え確認用ダミーユーザー一覧
  static const List<UserModel> dummyLoginUsers = [
    UserModel(
      id: '11111111-1111-1111-1111-111111111111',
      name: 'たけし',
    ),
    UserModel(
      id: '22222222-2222-2222-2222-222222222222',
      name: '西やん',
    ),
    UserModel(
      id: '33333333-3333-3333-3333-333333333333',
      name: 'ピンちゃん',
    ),
  ];

  /// グループ一覧画面の確認用ダミーデータ（DB連携は別issue）
  static const List<GroupSummary> groups = [
    GroupSummary(id: 'group-1', name: '週末テニス', memberCount: 3),
    GroupSummary(id: 'group-2', name: 'テニスサークル', memberCount: 8),
  ];

  /// グループ詳細画面の確認用ダミーデータ（DB連携は別issue）
  static final GroupDetail groupDetail = GroupDetail(
    id: 'group-1',
    name: '週末テニス',
    description: '毎週土曜日に活動するテニス仲間です。',
    createdAt: DateTime(2026, 4, 1),
    adminName: 'たけし',
    inviteCode: 'ABC123',
    memberCount: groupMembers.length,
  );

  static const List<GroupMember> groupMembers = [
    GroupMember(id: 'u1', name: 'たけし', wins: 12, losses: 8, isAdmin: true),
    GroupMember(id: 'u2', name: '西やん', wins: 10, losses: 10),
    GroupMember(id: 'u3', name: 'ピンちゃん', wins: 8, losses: 4),
  ];

  static final List<GroupMemberMatch> memberMatches = [
    GroupMemberMatch(
      id: 'mm1',
      matchDate: DateTime(2026, 8, 24),
      opponentName: 'たけし',
      scoreText: '4-6, 3-6',
      isWin: false,
    ),
    GroupMemberMatch(
      id: 'mm2',
      matchDate: DateTime(2026, 8, 18),
      opponentName: 'ピンちゃん',
      scoreText: '6-4, 7-5',
      isWin: true,
    ),
  ];

  static final List<GroupMatchSummary> groupMatches = [
    GroupMatchSummary(
      id: 'm1',
      matchDate: DateTime(2026, 8, 24),
      player1Name: 'たけし',
      player2Name: '西やん',
      winnerName: 'たけし',
      scoreText: '6-4, 6-3',
    ),
    GroupMatchSummary(
      id: 'm2',
      matchDate: DateTime(2026, 8, 18),
      player1Name: 'たけし',
      player2Name: 'ピンちゃん',
      winnerName: 'たけし',
      scoreText: '6-4, 6-3',
    ),
  ];

  static final GroupDetail tennisCircleDetail = GroupDetail(
    id: 'group-2',
    name: 'テニスサークル',
    description: '平日の夜を中心に活動するテニスサークルです。',
    createdAt: DateTime(2026, 5, 10),
    adminName: '西やん',
    inviteCode: 'XYZ789',
    memberCount: tennisCircleMembers.length,
  );

  static const List<GroupMember> tennisCircleMembers = [
    GroupMember(id: 'u2', name: '西やん', wins: 10, losses: 10, isAdmin: true),
    GroupMember(id: 'u4', name: 'さくら', wins: 6, losses: 3),
    GroupMember(id: 'u5', name: 'ゆうき', wins: 5, losses: 5),
    GroupMember(id: 'u6', name: 'あおい', wins: 7, losses: 4),
    GroupMember(id: 'u7', name: 'れん', wins: 3, losses: 6),
    GroupMember(id: 'u8', name: 'みお', wins: 4, losses: 4),
    GroupMember(id: 'u9', name: 'はる', wins: 9, losses: 2),
    GroupMember(id: 'u10', name: 'そら', wins: 2, losses: 7),
  ];

  static final List<GroupMatchSummary> tennisCircleMatches = [
    GroupMatchSummary(
      id: 'm3',
      matchDate: DateTime(2026, 9, 6),
      player1Name: '西やん',
      player2Name: 'さくら',
      winnerName: 'さくら',
      scoreText: '4-6, 6-7',
    ),
  ];

  static final Map<String, GroupDetail> groupDetailsById = {
    groupDetail.id: groupDetail,
    tennisCircleDetail.id: tennisCircleDetail,
  };

  static final Map<String, List<GroupMember>> groupMembersById = {
    groupDetail.id: groupMembers,
    tennisCircleDetail.id: tennisCircleMembers,
  };

  static final Map<String, List<GroupMatchSummary>> groupMatchesById = {
    groupDetail.id: groupMatches,
    tennisCircleDetail.id: tennisCircleMatches,
  };

  /// 「たけし」と同じグループに所属する対戦相手のモックリスト
  static const List<UserModel> opponents = [
    UserModel(
      id: '22222222-2222-2222-2222-222222222222',
      name: '西やん',
    ),
    UserModel(
      id: '33333333-3333-3333-3333-333333333333',
      name: 'ピンちゃん',
    ),
  ];
}
