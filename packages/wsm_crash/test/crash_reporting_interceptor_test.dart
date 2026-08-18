import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wsm_crash/wsm_crash.dart';

class _CountingReporter implements CrashReportingInterface {
  int errors = 0;

  @override
  Future<void> initialize() async {}

  @override
  Future<void> recordError(
    Object error, {
    StackTrace? stackTrace,
    String? reason,
    Map<String, dynamic>? information,
  }) async =>
      errors++;

  @override
  Future<void> recordFatalError(
    Object error, {
    StackTrace? stackTrace,
    String? reason,
    Map<String, dynamic>? information,
  }) async {}

  @override
  Future<void> setCustomKey(String key, Object? value) async {}

  @override
  Future<void> setUserId(String userId) async {}

  @override
  Future<void> log(String message, {String? level}) async {}
}

/// Returns a fixed status for every request, so the interceptor can be
/// exercised end-to-end through a real [Dio] without a network.
class _StubAdapter implements HttpClientAdapter {
  _StubAdapter(this.statusCode);

  final int statusCode;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
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

Dio _client(CrashReportingInterceptor interceptor, int status) => Dio(
      BaseOptions(baseUrl: 'https://api.test'),
    )
      ..interceptors.add(interceptor)
      ..httpClientAdapter = _StubAdapter(status);

Future<void> _hit(Dio dio, String path) async {
  try {
    await dio.get<void>(path);
  } on DioException {
    // expected
  }
}

void main() {
  group('CrashReportingInterceptor', () {
    test('reports 5xx and 422 only', () {
      expect(CrashReportingInterceptor.shouldReport(500), isTrue);
      expect(CrashReportingInterceptor.shouldReport(503), isTrue);
      expect(CrashReportingInterceptor.shouldReport(422), isTrue);
      expect(CrashReportingInterceptor.shouldReport(404), isFalse);
      expect(CrashReportingInterceptor.shouldReport(401), isFalse);
      expect(CrashReportingInterceptor.shouldReport(200), isFalse);
      expect(CrashReportingInterceptor.shouldReport(null), isFalse);
    });

    test('normalizes ids out of paths', () {
      expect(
        CrashReportingInterceptor.normalizePath('/wallets/42/transactions'),
        '/wallets/{id}/transactions',
      );
      expect(
        CrashReportingInterceptor.normalizePath(
          '/mail/9f2c1b7e-77aa-4a1e-9a3f-2f7a0b3c5d11',
        ),
        '/mail/{id}',
      );
      expect(
        CrashReportingInterceptor.normalizePath('/mail/inbox'),
        '/mail/inbox',
      );
    });

    test('deduplicates the same endpoint across record ids', () async {
      final reporter = _CountingReporter();
      final dio = _client(
        CrashReportingInterceptor(CrashReportingService(reporter)),
        500,
      );

      await _hit(dio, '/mail/1');
      await _hit(dio, '/mail/2');
      await _hit(dio, '/mail/3');

      expect(reporter.errors, 1);
    });

    test('reports distinct endpoints separately', () async {
      final reporter = _CountingReporter();
      final dio = _client(
        CrashReportingInterceptor(CrashReportingService(reporter)),
        500,
      );

      await _hit(dio, '/mail/1');
      await _hit(dio, '/contacts');
      await _hit(dio, '/calendar/events');

      expect(reporter.errors, 3);
    });

    test('ignores client errors', () async {
      final reporter = _CountingReporter();
      final dio = _client(
        CrashReportingInterceptor(CrashReportingService(reporter)),
        404,
      );

      await _hit(dio, '/mail/1');

      expect(reporter.errors, 0);
    });

    test('reports 422 validation failures', () async {
      final reporter = _CountingReporter();
      final dio = _client(
        CrashReportingInterceptor(CrashReportingService(reporter)),
        422,
      );

      await _hit(dio, '/mail');

      expect(reporter.errors, 1);
    });
  });
}
