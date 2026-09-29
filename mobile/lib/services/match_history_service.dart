import '../mocks/mock_data.dart';
import '../models/match_history_item.dart';
import '../models/match_history_query.dart';
import '../models/match_type.dart';
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
  final Map<String, List<MatchHistoryItem>> _monthCache = {};
  final Map<String, Future<List<MatchHistoryItem>>> _inFlightMonthRequests = {};
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

  /// 画面指定の検索条件で履歴を取得する。月や期間ごとの結果を混在させないよう、
  /// 任意条件の取得はホーム用キャッシュを介さずRepositoryへ委譲する。
  Future<List<MatchHistoryItem>> loadMatches(MatchHistoryQuery query) {
    return _repository.fetchMatches(query);
  }

  List<MatchHistoryItem> cachedMatchesByMonth({
    String? currentUserId,
    required int year,
    required int month,
    Set<MatchType> matchTypes = const {MatchType.singles},
  }) {
    final targetUserId = currentUserId ?? MockData.currentUserId;
    return _monthCache[_monthCacheKey(
          targetUserId,
          year,
          month,
          matchTypes,
        )] ??
        const [];
  }

  Future<List<MatchHistoryItem>> loadMatchesByMonth({
    String? currentUserId,
    required int year,
    required int month,
    Set<MatchType> matchTypes = const {MatchType.singles},
    bool forceRefresh = false,
  }) {
    final targetUserId = currentUserId ?? MockData.currentUserId;
    final cacheKey = _monthCacheKey(
      targetUserId,
      year,
      month,
      matchTypes,
    );
    final cachedMatches = _monthCache[cacheKey];
    if (cachedMatches != null && !forceRefresh) {
      return Future.value(cachedMatches);
    }

    final inFlightRequest = _inFlightMonthRequests[cacheKey];
    if (inFlightRequest != null) {
      return inFlightRequest;
    }

    final query = MatchHistoryQuery.forMonth(
      currentUserId: targetUserId,
      year: year,
      month: month,
      matchTypes: matchTypes,
    );
    final requestGeneration = _cacheGeneration;
    late final Future<List<MatchHistoryItem>> request;
    request = _fetchAndCacheMonth(cacheKey, query, requestGeneration)
        .whenComplete(() {
      if (identical(_inFlightMonthRequests[cacheKey], request)) {
        _inFlightMonthRequests.remove(cacheKey);
      }
    });
    _inFlightMonthRequests[cacheKey] = request;
    return request;
  }

  Future<List<MatchHistoryItem>> _fetchAndCacheMonth(
    String cacheKey,
    MatchHistoryQuery query,
    int requestGeneration,
  ) async {
    final matches = await _repository.fetchMatches(query);
    // メモ更新やキャッシュ破棄より前に開始した取得結果を再保存しない。
    if (requestGeneration == _cacheGeneration) {
      _monthCache[cacheKey] = matches;
    }
    return matches;
  }

  String _monthCacheKey(
    String userId,
    int year,
    int month,
    Set<MatchType> matchTypes,
  ) {
    final typeKey = matchTypes.map((type) => type.dbValue).toList()..sort();
    return '$userId:$year-${month.toString().padLeft(2, '0')}:${typeKey.join(',')}';
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

  void updatePersonalMemo({
    required String currentUserId,
    required String matchId,
    required String? personalMemo,
  }) {
    // 保存前に始まった取得結果を、更新済みメモのキャッシュへ反映させない。
    _cacheGeneration++;
    final matches = _cache[currentUserId];
    if (matches != null) {
      _cache[currentUserId] = [
        for (final match in matches)
          if (match.matchId == matchId)
            match.copyWithPersonalMemo(personalMemo)
          else
            match,
      ];
    }

    for (final entry in _monthCache.entries) {
      if (!entry.key.startsWith('$currentUserId:')) continue;
      _monthCache[entry.key] = [
        for (final match in entry.value)
          if (match.matchId == matchId)
            match.copyWithPersonalMemo(personalMemo)
          else
            match,
      ];
    }
  }

  void clearCache() {
    // 進行中の通信は止めず、完了時に古い結果をキャッシュしないよう世代を更新する。
    _cacheGeneration++;
    _cache.clear();
    _inFlightRequests.clear();
    _monthCache.clear();
    _inFlightMonthRequests.clear();
  }
}
