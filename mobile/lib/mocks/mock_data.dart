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
