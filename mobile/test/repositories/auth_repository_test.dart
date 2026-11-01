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

    test('signs in with a password and returns user and session state',
        () async {
      final requests = <http.Request>[];
      final client = _clientReturning(requests, (request) {
        return _jsonResponse({
          'access_token': 'test-access-token',
          'token_type': 'bearer',
          'expires_in': 3600,
          'refresh_token': 'test-refresh-token',
          'user': _userJson(),
        }, request);
      });
      addTearDown(client.dispose);

      final result = await SupabaseAuthRepository(client: client).signIn(
        email: 'takeshi@example.com',
        password: 'password8',
      );

      expect(result.userId, userId);
      expect(result.hasSession, isTrue);
      final request = requests.single;
      expect(request.url.path, '/auth/v1/token');
      expect(request.url.queryParameters['grant_type'], 'password');
      final body = jsonDecode(request.body) as Map<String, dynamic>;
      expect(body['email'], 'takeshi@example.com');
      expect(body['password'], 'password8');
    });

    test('signs out only the local session', () async {
      final requests = <http.Request>[];
      final client = _clientReturning(requests, (request) {
        if (request.url.path == '/auth/v1/token') {
          return _jsonResponse({
            'access_token': 'test-access-token',
            'token_type': 'bearer',
            'expires_in': 3600,
            'refresh_token': 'test-refresh-token',
            'user': _userJson(),
          }, request);
        }
        return http.Response('', 204, request: request);
      });
      addTearDown(client.dispose);
      final repository = SupabaseAuthRepository(client: client);
      await repository.signIn(
        email: 'takeshi@example.com',
        password: 'password8',
      );

      await repository.signOut();

      final logoutRequest = requests.last;
      expect(logoutRequest.url.path, '/auth/v1/logout');
      expect(logoutRequest.url.queryParameters['scope'], 'local');
      expect(client.auth.currentSession, isNull);
    });

    test('does not accept a session for an unconfirmed email', () async {
      final requests = <http.Request>[];
      final client = _clientReturning(requests, (request) {
        if (request.url.path == '/auth/v1/token') {
          final unconfirmedUser = Map<String, dynamic>.of(_userJson())
            ..remove('email_confirmed_at');
          return _jsonResponse({
            'access_token': 'test-access-token',
            'token_type': 'bearer',
            'expires_in': 3600,
            'refresh_token': 'test-refresh-token',
            'user': unconfirmedUser,
          }, request);
        }
        // リモート破棄に失敗しても、SDKがローカルセッションを消すことを確認する。
        return http.Response(
          jsonEncode({'msg': 'temporary failure'}),
          503,
          headers: {'content-type': 'application/json'},
          request: request,
        );
      });
      addTearDown(client.dispose);

      await expectLater(
        SupabaseAuthRepository(client: client).signIn(
          email: 'takeshi@example.com',
          password: 'password8',
        ),
        throwsA(
          isA<AuthException>().having(
            (error) => error.code,
            'code',
            'email_not_confirmed',
          ),
        ),
      );
      expect(client.auth.currentSession, isNull);
      expect(requests.last.url.path, '/auth/v1/logout');
    });

    test('does not accept a sign in response without a session', () async {
      final client = _clientReturning(
        [],
        (request) => _jsonResponse(_userJson(), request),
      );
      addTearDown(client.dispose);

      await expectLater(
        SupabaseAuthRepository(client: client).signIn(
          email: 'takeshi@example.com',
          password: 'password8',
        ),
        throwsA(
          isA<AuthException>().having(
            (error) => error.code,
            'code',
            'invalid_auth_response',
          ),
        ),
      );
    });

    test('clears a session when the sign in response has no user', () async {
      final requests = <http.Request>[];
      final client = _clientReturning(requests, (request) {
        if (request.url.path == '/auth/v1/token') {
          return _jsonResponse({
            'access_token': 'test-access-token',
            'token_type': 'bearer',
            'expires_in': 3600,
            'refresh_token': 'test-refresh-token',
            'user': null,
          }, request);
        }
        return http.Response('', 204, request: request);
      });
      addTearDown(client.dispose);

      await expectLater(
        SupabaseAuthRepository(client: client).signIn(
          email: 'takeshi@example.com',
          password: 'password8',
        ),
        throwsA(
          isA<AuthException>().having(
            (error) => error.code,
            'code',
            'invalid_auth_response',
          ),
        ),
      );
      expect(client.auth.currentSession, isNull);
      if (requests.length > 1) {
        expect(requests.last.url.path, '/auth/v1/logout');
      }
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
      'email_confirmed_at': '2026-10-25T00:01:00.000Z',
    };
