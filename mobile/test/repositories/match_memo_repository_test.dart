import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mobile/repositories/match_memo_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

const matchId = 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa';
const currentUserId = '11111111-1111-1111-1111-111111111111';

void main() {
  group('SupabaseMatchMemoRepository', () {
    test('upserts one memo by the match and user composite key', () async {
      final requests = <http.Request>[];
      final client = _clientReturning(requests);
      addTearDown(client.dispose);

      await SupabaseMatchMemoRepository(client: client).upsertPersonalMemo(
        matchId: matchId,
        userId: currentUserId,
        memo: '更新したメモ',
      );

      expect(requests, hasLength(1));
      final request = requests.single;
      expect(request.method, 'POST');
      expect(request.url.path, '/rest/v1/match_memos');
      expect(request.url.queryParameters['on_conflict'], 'match_id,user_id');
      expect(
          request.headers['prefer'], contains('resolution=merge-duplicates'));
      expect(jsonDecode(request.body), {
        'match_id': matchId,
        'user_id': currentUserId,
        'memo': '更新したメモ',
      });
    });

    test('deletes only the specified user memo for the match', () async {
      final requests = <http.Request>[];
      final client = _clientReturning(requests);
      addTearDown(client.dispose);

      await SupabaseMatchMemoRepository(client: client).deletePersonalMemo(
        matchId: matchId,
        userId: currentUserId,
      );

      expect(requests, hasLength(1));
      final request = requests.single;
      expect(request.method, 'DELETE');
      expect(request.url.path, '/rest/v1/match_memos');
      expect(request.url.queryParameters['match_id'], 'eq.$matchId');
      expect(request.url.queryParameters['user_id'], 'eq.$currentUserId');
    });
  });
}

SupabaseClient _clientReturning(List<http.Request> requests) {
  return SupabaseClient(
    'https://example.test',
    'test-anon-key',
    httpClient: MockClient((request) async {
      requests.add(request);
      return http.Response(
        '[]',
        200,
        headers: {'content-type': 'application/json'},
        request: request,
      );
    }),
  );
}
