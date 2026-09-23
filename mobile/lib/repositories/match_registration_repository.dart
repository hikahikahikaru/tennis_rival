import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/match_registration.dart';

abstract class MatchRegistrationRepository {
  /// 試合・参加者・各セットのスコアを一つのDBトランザクションで登録する。
  Future<String> registerMatch(MatchRegistration registration);
}

class SupabaseMatchRegistrationRepository
    implements MatchRegistrationRepository {
  final SupabaseClient? _client;

  SupabaseMatchRegistrationRepository({SupabaseClient? client})
      : _client = client;

  SupabaseClient get client => _client ?? Supabase.instance.client;

  @override
  Future<String> registerMatch(MatchRegistration registration) async {
    // 関連テーブルへの登録はDB関数内で一括実行し、途中失敗時の部分登録を防ぐ。
    final response = await client.rpc(
      'create_singles_match',
      params: registration.toRpcParameters(),
    );
    return response as String;
  }
}
