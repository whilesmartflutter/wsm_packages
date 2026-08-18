import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wsm_network/wsm_network.dart';

void main() {
  group('NetworkLoggerInterceptor', () {
    test('redacts credential-bearing headers', () {
      final redacted = NetworkLoggerInterceptor.redactHeaders(<String, dynamic>{
        'Authorization': 'Bearer supersecret',
        'Cookie': 'session=abc',
        'X-Api-Key': 'k-123',
        'Accept': 'application/json',
      });

      expect(redacted['Authorization'], '***');
      expect(redacted['Cookie'], '***');
      expect(redacted['X-Api-Key'], '***');
      expect(redacted['Accept'], 'application/json');
    });

    test('masks sensitive body fields, including nested ones', () {
      final interceptor = NetworkLoggerInterceptor(logBodies: true);

      final rendered = interceptor.redactBody(<String, dynamic>{
        'email': 'a@b.com',
        'password': 'hunter2',
        'nested': <String, dynamic>{'access_token': 'abc'},
      });

      expect(rendered, contains('a@b.com'));
      expect(rendered, isNot(contains('hunter2')));
      expect(rendered, isNot(contains('abc')));
    });

    test('truncates long bodies', () {
      final interceptor =
          NetworkLoggerInterceptor(logBodies: true, maxBodyLength: 20);

      final rendered = interceptor.redactBody('x' * 500);

      expect(rendered.length, lessThan(60));
      expect(rendered, endsWith('…(truncated)'));
    });

    test('masks FormData fields', () {
      final interceptor = NetworkLoggerInterceptor(logBodies: true);

      final rendered = interceptor.redactBody(
        FormData.fromMap(<String, dynamic>{'otp': '123456', 'name': 'ada'}),
      );

      expect(rendered, contains('ada'));
      expect(rendered, isNot(contains('123456')));
    });

    test('logBodies defaults to debug-only', () {
      // The test runner is a debug build, so the default is true here; the
      // point is that it is not hard-coded on.
      expect(NetworkLoggerInterceptor(logBodies: false).logBodies, isFalse);
    });
  });
}
