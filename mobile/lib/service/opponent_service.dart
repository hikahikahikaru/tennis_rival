import 'package:flutter/foundation.dart';
import '../constants/app_strings.dart';
import '../models/user_model.dart';
// ※ 今後Supabaseを本格接続する際は以下のパッケージを利用します
// import 'package:supabase_flutter/supabase_flutter.dart';

/// 対戦相手（同じグループに所属するユーザー）の一覧取得およびキャッシュ管理を行うサービスクラス
///
/// アプリ起動時に非同期で先読み（プリロード）してメモリ上に保持しておくことで、
/// 試合登録画面で対戦相手を選択する際のUI表示レスポンスを向上させます。
class OpponentService {
  // --- シングルトンパターンの実装 ---
  // アプリ全体で同一のインスタンス（キャッシュ）を共有できるようにします
  OpponentService._internal();
  static final OpponentService instance = OpponentService._internal();

  /// ログイン機能未実装時の仮ログインユーザーID
  /// （supabase/seed.sql に登録されている「たけし」のUUID）
  static const String dummyCurrentUserId =
      '11111111-1111-1111-1111-111111111111';

  /// メモリ上に保持する対戦相手一覧のキャッシュ
  List<UserModel>? _cachedOpponents;

  /// 重複リクエストを防ぐための通信中フラグ
  bool _isLoading = false;

  /// キャッシュ済みの対戦相手一覧を取得します（未取得の場合は空リストを返却）
  List<UserModel> get cachedOpponents => _cachedOpponents ?? [];

  /// 対戦相手一覧を非同期で取得・キャッシュするメソッド
  ///
  /// [currentUserId] 取得基準となるログインユーザーのID（未指定時はダミーID）
  /// [forceRefresh] trueにするとキャッシュを無視して再取得します（引っ張って更新など用）
  Future<List<UserModel>> loadOpponents({
    String currentUserId = dummyCurrentUserId,
    bool forceRefresh = false,
  }) async {
    // すでにキャッシュが存在し、強制更新でなければ即座にキャッシュを返す
    if (_cachedOpponents != null && !forceRefresh) {
      return _cachedOpponents!;
    }

    // すでに別の処理で読み込み中の場合は現在のキャッシュ（または空リスト）を返して二重取得を防止
    if (_isLoading) {
      return _cachedOpponents ?? [];
    }
    _isLoading = true;

    try {
      /*
      // ========================================================================
      // 【Supabase本格連携時の実装例】
      //
      // 1. ログインユーザーが所属しているグループID (group_id) の一覧を取得
      final memberRows = await Supabase.instance.client
          .from('group_members')
          .select('group_id')
          .eq('user_id', currentUserId);
      
      final groupIds = (memberRows as List)
          .map((r) => r['group_id'] as String)
          .toList();

      if (groupIds.isEmpty) {
        _cachedOpponents = [];
        return [];
      }

      // 2. 該当グループに所属する「自分以外」のメンバーを取得し、usersテーブルとJOINしてユーザー名を取得
      final response = await Supabase.instance.client
          .from('group_members')
          .select('users!inner(user_id, user_name)')
          .inFilter('group_id', groupIds)
          .neq('user_id', currentUserId);

      // 3. 取得したJSONデータをUserModelのリストに変換
      final opponents = (response as List)
          .map((item) => UserModel.fromJson(item['users'] as Map<String, dynamic>))
          .toList();
      // ========================================================================
      */

      // --- 【開発用モックデータ】Supabase未接続時のダミー取得（seed.sql準拠） ---
      // ネットワーク通信の遅延を擬似的に再現 (300ms)
      await Future.delayed(const Duration(milliseconds: 300));

      // seed.sql にある「たけし」と同じグループ（週末テニスサークル）の他メンバー
      final opponents = [
        const UserModel(
          id: '22222222-2222-2222-2222-222222222222',
          name: '西やん',
        ),
        const UserModel(
          id: '33333333-3333-3333-3333-333333333333',
          name: 'ピンちゃん',
        ),
      ];

      // 取得結果をメモリキャッシュに保存
      _cachedOpponents = opponents;
      return opponents;
    } catch (e) {
      debugPrint(AppStrings.errorOpponentFetch(e));
      return _cachedOpponents ?? [];
    } finally {
      _isLoading = false;
    }
  }

  /// 必要に応じてキャッシュを破棄するメソッド（ログアウト時などに使用）
  void clearCache() {
    _cachedOpponents = null;
  }
}
