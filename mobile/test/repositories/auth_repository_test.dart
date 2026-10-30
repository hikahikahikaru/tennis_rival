import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mobile/repositories/auth_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

const userId = '11111111-1111-1111-1111-111111111111';

void main() {
  group('SupabaseAuthRepository', () {
    test('calls signUp with user_name metadata and returns confirmation state',
        () async {
      final requests = <http.Request>[];
      final client = _clientReturning(requests, (request) {
        return _jsonResponse(_userJson(), request);
      });
      addTearDown(client.dispose);

      final result = await SupabaseAuthRepository(client: client).signUp(
        displayName: 'たけし',
        email: 'takeshi@example.com',
        password: 'password8',
      );

      expect(result.userId, userId);
      expect(result.hasSession, isFalse);
      final request = requests.single;
      expect(request.url.path, '/auth/v1/signup');
      expect(request.method, 'POST');
      final body = jsonDecode(request.body) as Map<String, dynamic>;
      expect(body['email'], 'takeshi@example.com');
      expect(body['password'], 'password8');
      expect(body['data'], {'user_name': 'たけし'});
    });

    test('reports when signUp returns an authenticated session', () async {
      final client = _clientReturning(
        [],
        (request) => _jsonResponse({
          'access_token': 'test-access-token',
          'token_type': 'bearer',
          'expires_in': 3600,
          'refresh_token': 'test-refresh-token',
          'user': _userJson(),
        }, request),
      );
      addTearDown(client.dispose);

      final result = await SupabaseAuthRepository(client: client).signUp(
        displayName: 'たけし',
        email: 'takeshi@example.com',
        password: 'password8',
      );

      expect(result.userId, userId);
      expect(result.hasSession, isTrue);
    });

    test('forwards AuthException from Supabase Auth', () async {
      final client = _clientReturning(
        [],
        (request) => http.Response(
          jsonEncode({
            'code': 422,
            'error_code': 'weak_password',
            'msg': 'Password should be at least 8 characters.',
          }),
          422,
          headers: {'content-type': 'application/json'},
          request: request,
        ),
      );
      addTearDown(client.dispose);

      await expectLater(
        SupabaseAuthRepository(client: client).signUp(
          displayName: 'たけし',
          email: 'takeshi@example.com',
          password: 'short',
        ),
        throwsA(isA<AuthException>()),
      );
    });

    test('maps a server 5xx response to a retryable Auth failure', () async {
      final client = _clientReturning(
        [],
        (request) => http.Response(
          jsonEncode({'msg': 'temporary server failure'}),
          503,
          headers: {'content-type': 'application/json'},
          request: request,
        ),
      );
      addTearDown(client.dispose);

      await expectLater(
        SupabaseAuthRepository(client: client).signUp(
          displayName: 'たけし',
          email: 'takeshi@example.com',
          password: 'password8',
        ),
        throwsA(
          isA<AuthRetryableFetchException>().having(
            (error) => error.statusCode,
            'statusCode',
            '503',
          ),
        ),
      );
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
    authOptions: const AuthClientOptions(
      authFlowType: AuthFlowType.implicit,
    ),
    httpClient: MockClient((request) async {
      requests.add(request);
      return handler(request);
    }),
  );
}

http.Response _jsonResponse(
  Map<String, dynamic> body,
  http.Request request,
) {
  return http.Response(
    jsonEncode(body),
    200,
    headers: {'content-type': 'application/json'},
    request: request,
  );
}

Map<String, dynamic> _userJson() => {
      'id': userId,
      'aud': 'authenticated',
      'role': 'authenticated',
      'email': 'takeshi@example.com',
      'app_metadata': {
        'provider': 'email',
        'providers': ['email']
      },
      'user_metadata': {'user_name': 'たけし'},
      'created_at': '2026-10-25T00:00:00.000Z',
    };
