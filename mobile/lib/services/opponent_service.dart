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

  /// キャッシュが紐付いているユーザーID
  String? _cachedUserId;

  /// メモリ上に保持する対戦相手一覧のキャッシュ
  List<UserModel>? _cachedOpponents;

  /// 実行中通信の対象ユーザーID
  String? _inFlightUserId;

  /// 現在実行中の非同期取得処理（Future）
  /// 通信中に別の箇所から同一ユーザーで呼び出された場合、このFutureを共有して同じ完了を待ちます
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

    // 1. 同一ユーザーのキャッシュが存在し、強制更新でなければ即座にキャッシュを返す
    if (_cachedUserId == targetUserId &&
        _cachedOpponents != null &&
        !forceRefresh) {
      return _cachedOpponents!;
    }

    // 2. 同一ユーザーで通信中の処理がある場合は、そのFutureを共有して完了を待つ
    if (_inFlightUserId == targetUserId && _inFlightFetch != null) {
      return _inFlightFetch!;
    }

    // 3. 新規に通信を開始し、完了するまで _inFlightFetch / _inFlightUserId に保持する
    _inFlightUserId = targetUserId;
    final fetchFuture = _fetchAndCacheOpponents(targetUserId);
    _inFlightFetch = fetchFuture;

    return fetchFuture;
  }

  /// 実際にリポジトリを呼び出してキャッシュに保存する内部メソッド
  Future<List<UserModel>> _fetchAndCacheOpponents(String userId) async {
    try {
      // リポジトリ経由でSupabaseから同じグループの対戦相手一覧を取得
      final opponents = await _userRepository.fetchGroupOpponents(userId);

      // 通信完了時にユーザーが変わっていなければキャッシュに保存（古い通信結果による上書き防止）
      if (_inFlightUserId == userId) {
        _cachedUserId = userId;
        _cachedOpponents = opponents;
      }
      return opponents;
    } catch (e) {
      debugPrint(AppStrings.errorOpponentFetch(e));
      // 例外を上位（UI層など）に伝達してエラー画面・再試行へ繋げる
      rethrow;
    } finally {
      // 通信完了（成功・失敗問わず）したら該当ユーザーの実行中フラグ/Futureをクリア
      if (_inFlightUserId == userId) {
        _inFlightFetch = null;
        _inFlightUserId = null;
      }
    }
  }

  /// 必要に応じてキャッシュを破棄するメソッド（ログアウト時やユーザー切り替え時に使用）
  void clearCache() {
    _cachedUserId = null;
    _cachedOpponents = null;
    _inFlightUserId = null;
    _inFlightFetch = null;
  }
}
