import 'package:flutter/foundation.dart';

import '../constants/app_strings.dart';
import '../models/user_model.dart';
import '../repositories/user_repository.dart';

/// 対戦相手の一覧取得およびキャッシュ管理を行うサービスクラス
///
/// アプリ起動時に非同期で先読み（プリロード）してメモリ上に保持しておくことで、
/// 試合登録画面で対戦相手を選択する際のUI表示レスポンスを向上させます。
/// DB通信自体は [UserRepository] に委譲し、このクラスはキャッシュと状態管理を担当します。
class OpponentService {
  // --- シングルトンパターンの実装 ---
  // アプリ全体で同一のインスタンス（キャッシュ）を共有できるようにします
  OpponentService._internal();
  static final OpponentService instance = OpponentService._internal();

  /// データベース通信を担当するリポジトリ
  UserRepository _userRepository = UserRepository();

  /// テスト用などに [UserRepository] を差し替え可能にするセッター
  @visibleForTesting
  set userRepository(UserRepository repo) {
    _userRepository = repo;
  }

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
      // リポジトリ経由でSupabaseから同じグループの対戦相手一覧を取得
      final opponents =
          await _userRepository.fetchGroupOpponents(currentUserId);

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
