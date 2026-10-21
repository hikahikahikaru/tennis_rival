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
