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
    late final Future<List<MatchHistoryItem>> request;
    request = _fetchAndCache(targetUserId).whenComplete(() {
      if (identical(_inFlightRequests[targetUserId], request)) {
        _inFlightRequests.remove(targetUserId);
      }
    });
    _inFlightRequests[targetUserId] = request;
    return request;
  }

  Future<List<MatchHistoryItem>> _fetchAndCache(String userId) async {
    final matches = await _repository.fetchRecentMatches(userId);
    _cache[userId] = matches;
    return matches;
  }

  void clearCache() {
    _cache.clear();
    _inFlightRequests.clear();
  }
}
