import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/user_model.dart';

/// ユーザー関連のデータベース（Supabase）通信を担当するリポジトリクラス
///
/// データベースへの直接のクエリ発行や生データの取得・変換に専念し、
/// キャッシュなどの画面制御ロジックは持ちません。
class UserRepository {
  final SupabaseClient? _client;

  /// コンストラクタ
  ///
  /// [client] を省略した場合は呼び出し時に [Supabase.instance.client] を使用します。
  /// 単体テスト時などにモッククライアントを注入することも可能です。
  UserRepository({SupabaseClient? client}) : _client = client;

  /// SupabaseClientのインスタンスを取得（遅延評価）
  SupabaseClient get client => _client ?? Supabase.instance.client;

  /// 指定したユーザーと同じグループに所属する「自分以外の対戦相手ユーザー一覧」をDBから取得します
  ///
  /// 1. `group_members` テーブルから対象ユーザーの所属する `group_id` を取得
  /// 2. 該当グループに所属する他ユーザーを取得し、`users` テーブルと結合して名前を取得
  Future<List<UserModel>> fetchGroupOpponents(String userId) async {
    // 1. 対象ユーザーが所属しているグループID (group_id) の一覧を取得
    final memberRows = await client
        .from('group_members')
        .select('group_id')
        .eq('user_id', userId);

    final groupIds =
        (memberRows as List).map((r) => r['group_id'] as String).toList();

    // 所属グループが存在しない場合は空リストを返却
    if (groupIds.isEmpty) {
      return [];
    }

    // 2. 該当グループに所属する「自分以外」のメンバーを取得し、usersテーブルとJOINしてユーザー情報を取得
    final response = await client
        .from('group_members')
        .select('users!inner(user_id, user_name)')
        .inFilter('group_id', groupIds)
        .neq('user_id', userId);

    // 3. 取得したJSONデータをUserModelのリストに変換
    return (response as List)
        .map(
            (item) => UserModel.fromJson(item['users'] as Map<String, dynamic>))
        .toList();
  }
}
