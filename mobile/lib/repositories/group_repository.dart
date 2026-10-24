import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/group_summary.dart';

/// グループのDB通信とレスポンス変換を担当するRepository。
abstract class GroupRepository {
  /// Supabase Authで認証済みのユーザーID。
  String? get currentUserId;

  /// 認証中のユーザーが所属するグループを取得する。
  Future<List<GroupSummary>> fetchGroups();

  /// 認証中のユーザーを管理者としてグループを作成する。
  Future<String> createGroup({
    required String name,
    String? description,
  });
}

class SupabaseGroupRepository implements GroupRepository {
  static const _groupSelect = 'group_id,groups!group_members_group_id_fkey('
      'group_id,group_name,group_members(count))';

  final SupabaseClient? _client;
  final String? Function()? _currentUserIdProvider;

  SupabaseGroupRepository({
    SupabaseClient? client,
    String? Function()? currentUserIdProvider,
  })  : _client = client,
        _currentUserIdProvider = currentUserIdProvider;

  SupabaseClient get client => _client ?? Supabase.instance.client;

  @override
  String? get currentUserId =>
      _currentUserIdProvider?.call() ?? client.auth.currentUser?.id;

  String get _authenticatedUserId {
    final userId = currentUserId;
    if (userId == null) {
      throw const GroupAuthenticationRequiredException();
    }
    return userId;
  }

  @override
  Future<List<GroupSummary>> fetchGroups() async {
    // 絞り込みIDは引数ではなく認証セッションから取得し、他ユーザーへの
    // なりすましをクライアントAPI上でも許可しない。
    final userId = _authenticatedUserId;
    final response = await client
        .from('group_members')
        .select(_groupSelect)
        .eq('user_id', userId);

    return (response as List<dynamic>)
        .map((row) => _groupSummaryFromRow(row as Map<String, dynamic>))
        .toList(growable: false);
  }

  @override
  Future<String> createGroup({
    required String name,
    String? description,
  }) async {
    _authenticatedUserId;
    final response = await client.rpc(
      'create_group',
      params: {
        'p_group_name': name,
        'p_group_description': description,
      },
    );
    return response as String;
  }

  GroupSummary _groupSummaryFromRow(Map<String, dynamic> row) {
    final group = row['groups'] as Map<String, dynamic>;
    final members = group['group_members'] as List<dynamic>? ?? const [];
    final count = members.isEmpty
        ? 0
        : (members.first as Map<String, dynamic>)['count'] as int;
    return GroupSummary(
      id: group['group_id'] as String,
      name: group['group_name'] as String,
      memberCount: count,
    );
  }
}

/// グループ操作に認証済みセッションが必要であることを表す。
class GroupAuthenticationRequiredException implements Exception {
  const GroupAuthenticationRequiredException();

  @override
  String toString() => 'GroupAuthenticationRequiredException';
}
