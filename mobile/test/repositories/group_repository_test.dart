import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mobile/repositories/group_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

const userId = '11111111-1111-1111-1111-111111111111';
const groupId = '99999999-9999-9999-9999-999999999999';

void main() {
  group('SupabaseGroupRepository', () {
    test('fetches and converts only groups for the authenticated user',
        () async {
      final requests = <http.Request>[];
      final client = _clientReturning(requests, (request) {
        return http.Response(
          jsonEncode([
            {
              'group_id': groupId,
              'groups': {
                'group_id': groupId,
                'group_name': '週末テニス',
                'group_members': [
                  {'count': 3},
                ],
              },
            },
          ]),
          200,
          headers: {'content-type': 'application/json'},
          request: request,
        );
      });
      addTearDown(client.dispose);
      final repository = SupabaseGroupRepository(
        client: client,
        currentUserIdProvider: () => userId,
      );

      final groups = await repository.fetchGroups();

      expect(groups, hasLength(1));
      expect(groups.single.id, groupId);
      expect(groups.single.name, '週末テニス');
      expect(groups.single.memberCount, 3);
      final request = requests.single;
      expect(request.url.path, '/rest/v1/group_members');
      expect(request.url.queryParameters['user_id'], 'eq.$userId');
      expect(
          request.url.queryParameters['select'], isNot(contains('password')));
    });

    test('returns an empty list when the user has no groups', () async {
      final client = _clientReturning(
        [],
        (request) => http.Response(
          '[]',
          200,
          headers: {'content-type': 'application/json'},
          request: request,
        ),
      );
      addTearDown(client.dispose);

      final groups = await SupabaseGroupRepository(
        client: client,
        currentUserIdProvider: () => userId,
      ).fetchGroups();

      expect(groups, isEmpty);
    });

    test('forwards database errors', () async {
      final client = _clientReturning(
        [],
        (request) => http.Response(
          '{"message":"DB error"}',
          500,
          headers: {'content-type': 'application/json'},
          request: request,
        ),
      );
      addTearDown(client.dispose);

      await expectLater(
        SupabaseGroupRepository(
          client: client,
          currentUserIdProvider: () => userId,
        ).fetchGroups(),
        throwsA(isA<PostgrestException>()),
      );
    });

    test('calls create_group and returns its group ID', () async {
      final requests = <http.Request>[];
      final client = _clientReturning(requests, (request) {
        return http.Response(
          jsonEncode(groupId),
          200,
          headers: {'content-type': 'application/json'},
          request: request,
        );
      });
      addTearDown(client.dispose);

      final createdId = await SupabaseGroupRepository(
        client: client,
        currentUserIdProvider: () => userId,
      ).createGroup(name: '新しいグループ', description: '説明');

      expect(createdId, groupId);
      final request = requests.single;
      expect(request.url.path, '/rest/v1/rpc/create_group');
      expect(jsonDecode(request.body), {
        'p_group_name': '新しいグループ',
        'p_group_description': '説明',
      });
    });

    test('forwards create_group errors', () async {
      final client = _clientReturning(
        [],
        (request) => http.Response(
          '{"message":"creation failed"}',
          400,
          headers: {'content-type': 'application/json'},
          request: request,
        ),
      );
      addTearDown(client.dispose);

      await expectLater(
        SupabaseGroupRepository(
          client: client,
          currentUserIdProvider: () => userId,
        ).createGroup(name: '失敗するグループ'),
        throwsA(isA<PostgrestException>()),
      );
    });

    test('rejects requests without an authenticated user before HTTP access',
        () async {
      final requests = <http.Request>[];
      final client = _clientReturning(
        requests,
        (request) => http.Response('[]', 200, request: request),
      );
      addTearDown(client.dispose);
      final repository = SupabaseGroupRepository(
        client: client,
        currentUserIdProvider: () => null,
      );

      await expectLater(
        repository.fetchGroups(),
        throwsA(isA<GroupAuthenticationRequiredException>()),
      );
      await expectLater(
        repository.createGroup(name: '未認証'),
        throwsA(isA<GroupAuthenticationRequiredException>()),
      );
      expect(requests, isEmpty);
    });
  });
}

SupabaseClient _clientReturning(
  List<http.Request> requests,
  FutureOr<http.Response> Function(http.Request request) handler,
) {
  return SupabaseClient(
    'https://example.test',
    'test-anon-key',
    httpClient: MockClient((request) async {
      requests.add(request);
      return handler(request);
    }),
  );
}
