import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wsm_network/wsm_network.dart';

/// Returns a fixed status for every request, so interceptor behaviour can be
/// exercised end-to-end through a real [Dio] without a network.
class _StubAdapter implements HttpClientAdapter {
  _StubAdapter(this.statusCode);

  final int statusCode;
  RequestOptions? lastRequest;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    lastRequest = options;
    return ResponseBody.fromString(
      '{}',
      statusCode,
      headers: <String, List<String>>{
        Headers.contentTypeHeader: <String>[Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

({Dio dio, _StubAdapter adapter}) _client({
  required int status,
  required TokenInterceptor interceptor,
}) {
  final adapter = _StubAdapter(status);
  final dio = createDio(
    baseUrl: 'https://api.test',
    interceptors: [interceptor],
  )..httpClientAdapter = adapter;
  return (dio: dio, adapter: adapter);
}

void main() {
  group('TokenInterceptor.onRequest', () {
    test('attaches the bearer token', () async {
      final client = _client(
        status: 200,
        interceptor: TokenInterceptor(getToken: () => 'abc123'),
      );

      await client.dio.get<void>('/me');

      expect(
        client.adapter.lastRequest!.headers['Authorization'],
        'Bearer abc123',
      );
    });

    test('sends no header when signed out', () async {
      final client = _client(
        status: 200,
        interceptor: TokenInterceptor(getToken: () => null),
      );

      await client.dio.get<void>('/me');

      expect(
        client.adapter.lastRequest!.headers.containsKey('Authorization'),
        isFalse,
      );
    });

    test('does not overwrite an explicit Authorization header', () async {
      final client = _client(
        status: 200,
        interceptor: TokenInterceptor(getToken: () => 'abc123'),
      );

      await client.dio.get<void>(
        '/me',
        options:
            Options(headers: <String, dynamic>{'Authorization': 'Basic z'}),
      );

      expect(client.adapter.lastRequest!.headers['Authorization'], 'Basic z');
    });
  });

  group('TokenInterceptor.onError', () {
    test('signs out on a 401 for an authenticated request', () async {
      var signedOut = false;
      final client = _client(
        status: 401,
        interceptor: TokenInterceptor(
          getToken: () => 'abc123',
          onUnauthorized: () => signedOut = true,
        ),
      );

      await expectLater(
        client.dio.get<void>('/transactions'),
        throwsA(isA<DioException>()),
      );

      expect(signedOut, isTrue);
    });

    test('does not sign out on a 401 from the login endpoint', () async {
      var signedOut = false;
      final client = _client(
        status: 401,
        interceptor: TokenInterceptor(
          // A stale token can still be attached while re-authenticating.
          getToken: () => 'stale',
          onUnauthorized: () => signedOut = true,
        ),
      );

      await expectLater(
        client.dio.post<void>('/auth/login'),
        throwsA(isA<DioException>()),
      );

      expect(signedOut, isFalse);
    });

    test('does not sign out when the request carried no token', () async {
      var signedOut = false;
      final client = _client(
        status: 401,
        interceptor: TokenInterceptor(
          getToken: () => null,
          onUnauthorized: () => signedOut = true,
        ),
      );

      await expectLater(
        client.dio.get<void>('/transactions'),
        throwsA(isA<DioException>()),
      );

      expect(signedOut, isFalse);
    });

    test('ignores non-401 errors', () async {
      var signedOut = false;
      final client = _client(
        status: 500,
        interceptor: TokenInterceptor(
          getToken: () => 'abc123',
          onUnauthorized: () => signedOut = true,
        ),
      );

      await expectLater(
        client.dio.get<void>('/transactions'),
        throwsA(isA<DioException>()),
      );

      expect(signedOut, isFalse);
    });

    test('default matcher covers the shared auth endpoints', () {
      for (final path in [
        '/login',
        '/auth/login',
        '/register',
        '/password-reset',
        '/auth/otp/verify',
        '/token/refresh',
      ]) {
        expect(
          TokenInterceptor.defaultIsAuthEndpoint(path),
          isTrue,
          reason: path,
        );
      }
      for (final path in ['/transactions', '/me', '/wallets/1']) {
        expect(
          TokenInterceptor.defaultIsAuthEndpoint(path),
          isFalse,
          reason: path,
        );
      }
    });
  });
}
