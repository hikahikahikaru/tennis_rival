import '../models/group_summary.dart';
import '../repositories/group_repository.dart';

/// グループ一覧のユーザー別キャッシュと作成ユースケースを管理する。
class GroupService {
  static final GroupService instance = GroupService();

  final GroupRepository _repository;
  final Map<String, List<GroupSummary>> _cache = {};
  final Map<String, Future<List<GroupSummary>>> _inFlightRequests = {};
  int _cacheGeneration = 0;

  GroupService({GroupRepository? repository})
      : _repository = repository ?? SupabaseGroupRepository();

  List<GroupSummary> cachedGroups() {
    final userId = _requireAuthenticatedUserId();
    return _cache[userId] ?? const [];
  }

  Future<List<GroupSummary>> loadGroups({bool forceRefresh = false}) {
    final userId = _requireAuthenticatedUserId();
    final cachedGroups = _cache[userId];
    if (cachedGroups != null && !forceRefresh) {
      return Future.value(cachedGroups);
    }

    final inFlightRequest = _inFlightRequests[userId];
    if (inFlightRequest != null) {
      return inFlightRequest;
    }

    final requestGeneration = _cacheGeneration;
    late final Future<List<GroupSummary>> request;
    request = _fetchAndCache(userId, requestGeneration).whenComplete(() {
      if (identical(_inFlightRequests[userId], request)) {
        _inFlightRequests.remove(userId);
      }
    });
    _inFlightRequests[userId] = request;
    return request;
  }

  Future<String> createGroup({
    required String name,
    String? description,
  }) async {
    final userId = _requireAuthenticatedUserId();
    final groupId = await _repository.createGroup(
      name: name,
      description: description,
    );
    _invalidateUser(userId);
    return groupId;
  }

  Future<List<GroupSummary>> _fetchAndCache(
    String userId,
    int requestGeneration,
  ) async {
    final groups = await _repository.fetchGroups();
    // ログアウトやユーザー変更より前に開始した結果をキャッシュへ戻さない。
    if (requestGeneration == _cacheGeneration &&
        _repository.currentUserId == userId) {
      _cache[userId] = groups;
    }
    return groups;
  }

  void _invalidateUser(String userId) {
    _cacheGeneration++;
    _cache.remove(userId);
    _inFlightRequests.remove(userId);
  }

  void clearCache() {
    _cacheGeneration++;
    _cache.clear();
    _inFlightRequests.clear();
  }

  String _requireAuthenticatedUserId() {
    final userId = _repository.currentUserId;
    if (userId == null) {
      throw const GroupAuthenticationRequiredException();
    }
    return userId;
  }
}
