import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wsm_network/wsm_network.dart';

/// Returns a fixed status for every request, so interceptor behaviour can be
/// exercised end-to-end through a real [Dio] without a network.
class _StubAdapter implements HttpClientAdapter {
  _StubAdapter(int statusCode) : statusCodes = <int>[statusCode];

  _StubAdapter.sequence(this.statusCodes);

  final List<int> statusCodes;
  RequestOptions? lastRequest;
  int requests = 0;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    lastRequest = options;
    final statusCode = statusCodes[requests.clamp(0, statusCodes.length - 1)];
    requests++;
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
        options: Options(
          headers: <String, dynamic>{'Authorization': 'Basic z'},
        ),
      );

      expect(client.adapter.lastRequest!.headers['Authorization'], 'Basic z');
    });
  });

  group('TokenInterceptor.onError', () {
    test('refreshes the token and retries the request once', () async {
      var token = 'expired';
      final adapter = _StubAdapter.sequence(<int>[401, 200]);
      final dio = createDio(baseUrl: 'https://api.test')
        ..httpClientAdapter = adapter;
      dio.interceptors.add(
        TokenInterceptor(
          getToken: () => token,
          refreshToken: () async {
            token = 'renewed';
            return token;
          },
          retryClient: dio,
        ),
      );

      final response = await dio.get<void>('/transactions');

      expect(response.statusCode, 200);
      expect(adapter.requests, 2);
      expect(adapter.lastRequest!.headers['Authorization'], 'Bearer renewed');
    });

    test('signs out when refreshing fails', () async {
      var signedOut = false;
      late Dio dio;
      final adapter = _StubAdapter(401);
      dio = createDio(
        baseUrl: 'https://api.test',
        interceptors: <Interceptor>[
          TokenInterceptor(
            getToken: () => 'expired',
            refreshToken: () async => null,
            retryClient: Dio(BaseOptions(baseUrl: 'https://api.test'))
              ..httpClientAdapter = adapter,
            onUnauthorized: () => signedOut = true,
          ),
        ],
      )..httpClientAdapter = adapter;

      await expectLater(
        dio.get<void>('/transactions'),
        throwsA(isA<DioException>()),
      );

      expect(signedOut, isTrue);
      expect(adapter.requests, 1);
    });

    test('signs out once when the retried request is unauthorized', () async {
      var signedOut = 0;
      var token = 'expired';
      final adapter = _StubAdapter.sequence(<int>[401, 401]);
      final dio = createDio(baseUrl: 'https://api.test')
        ..httpClientAdapter = adapter;
      dio.interceptors.add(
        TokenInterceptor(
          getToken: () => token,
          refreshToken: () async {
            token = 'renewed';
            return token;
          },
          retryClient: dio,
          onUnauthorized: () => signedOut++,
        ),
      );

      await expectLater(
        dio.get<void>('/transactions'),
        throwsA(isA<DioException>()),
      );

      expect(signedOut, 1);
      expect(adapter.requests, 2);
    });

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
