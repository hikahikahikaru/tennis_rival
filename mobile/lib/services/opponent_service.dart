import 'package:flutter/foundation.dart';

import '../constants/app_strings.dart';
import '../mocks/mock_data.dart';
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

  /// メモリ上に保持する対戦相手一覧のキャッシュ
  List<UserModel>? _cachedOpponents;

  /// 現在実行中の非同期取得処理（Future）
  /// 通信中に別の箇所から呼び出された場合、このFutureを共有して同じ完了を待ちます
  Future<List<UserModel>>? _inFlightFetch;

  /// キャッシュ済みの対戦相手一覧を取得します（未取得の場合は空リストを返却）
  List<UserModel> get cachedOpponents => _cachedOpponents ?? [];

  /// 対戦相手一覧を非同期で取得・キャッシュするメソッド
  ///
  /// [currentUserId] 取得基準となるログインユーザーのID（未指定時は [MockData.currentUserId]）
  /// [forceRefresh] trueにするとキャッシュを無視して再取得します（引っ張って更新など用）
  Future<List<UserModel>> loadOpponents({
    String? currentUserId,
    bool forceRefresh = false,
  }) async {
    final targetUserId = currentUserId ?? MockData.currentUserId;

    // 1. すでにキャッシュが存在し、強制更新でなければ即座にキャッシュを返す
    if (_cachedOpponents != null && !forceRefresh) {
      return _cachedOpponents!;
    }

    // 2. すでに通信中の処理がある場合は、そのFutureを共有して完了を待つ
    if (_inFlightFetch != null) {
      return _inFlightFetch!;
    }

    // 3. 新規に通信を開始し、完了するまで _inFlightFetch に保持する
    final fetchFuture = _fetchAndCacheOpponents(targetUserId);
    _inFlightFetch = fetchFuture;

    return fetchFuture;
  }

  /// 実際にリポジトリを呼び出してキャッシュに保存する内部メソッド
  Future<List<UserModel>> _fetchAndCacheOpponents(String userId) async {
    try {
      // リポジトリ経由でSupabaseから同じグループの対戦相手一覧を取得
      final opponents = await _userRepository.fetchGroupOpponents(userId);

      // 取得結果をメモリキャッシュに保存
      _cachedOpponents = opponents;
      return opponents;
    } catch (e) {
      debugPrint(AppStrings.errorOpponentFetch(e));
      // 例外を上位（UI層など）に伝達してエラー画面・再試行へ繋げる
      rethrow;
    } finally {
      // 通信完了（成功・失敗問わず）したら進行中フラグ/Futureをクリア
      _inFlightFetch = null;
    }
  }

  /// 必要に応じてキャッシュを破棄するメソッド（ログアウト時などに使用）
  void clearCache() {
    _cachedOpponents = null;
    _inFlightFetch = null;
  }
}
