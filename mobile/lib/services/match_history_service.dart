import '../mocks/mock_data.dart';
import '../models/match_history_item.dart';
import '../repositories/match_history_repository.dart';

/// 最近の試合について、ユーザー別キャッシュと進行中の取得処理を管理する。
///
/// DB通信とレスポンス変換は[MatchHistoryRepository]へ委譲し、アプリ全体では
/// [instance]を使うことで起動時プリロードとHomeScreenが同じデータを共有する。
class MatchHistoryService {
  static final MatchHistoryService instance = MatchHistoryService();

  final MatchHistoryRepository _repository;
  final Map<String, List<MatchHistoryItem>> _cache = {};
  final Map<String, Future<List<MatchHistoryItem>>> _inFlightRequests = {};
  int _cacheGeneration = 0;

  MatchHistoryService({MatchHistoryRepository? repository})
      : _repository = repository ?? SupabaseMatchHistoryRepository();

  List<MatchHistoryItem> cachedRecentMatches({String? currentUserId}) {
    final targetUserId = currentUserId ?? MockData.currentUserId;
    return _cache[targetUserId] ?? const [];
  }

  Future<List<MatchHistoryItem>> loadRecentMatches({
    String? currentUserId,
    bool forceRefresh = false,
  }) {
    final targetUserId = currentUserId ?? MockData.currentUserId;
    final cachedMatches = _cache[targetUserId];
    if (cachedMatches != null && !forceRefresh) {
      return Future.value(cachedMatches);
    }

    final inFlightRequest = _inFlightRequests[targetUserId];
    if (inFlightRequest != null) {
      return inFlightRequest;
    }

    // プリロードと画面取得が重なっても、同一ユーザーでは一つの通信完了を共有する。
    final requestGeneration = _cacheGeneration;
    late final Future<List<MatchHistoryItem>> request;
    request = _fetchAndCache(targetUserId, requestGeneration).whenComplete(() {
      if (identical(_inFlightRequests[targetUserId], request)) {
        _inFlightRequests.remove(targetUserId);
      }
    });
    _inFlightRequests[targetUserId] = request;
    return request;
  }

  Future<List<MatchHistoryItem>> _fetchAndCache(
    String userId,
    int requestGeneration,
  ) async {
    final matches = await _repository.fetchRecentMatches(userId);
    // 無効化前に開始した取得結果で、新しいキャッシュを上書きしない。
    if (requestGeneration == _cacheGeneration) {
      _cache[userId] = matches;
    }
    return matches;
  }

  void clearCache() {
    // 進行中の通信は止めず、完了時に古い結果をキャッシュしないよう世代を更新する。
    _cacheGeneration++;
    _cache.clear();
    _inFlightRequests.clear();
  }
}
