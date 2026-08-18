import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wsm_crash_firebase/wsm_crash_firebase.dart';

void main() {
  group('dio error formatting', () {
    test('reason names method, path and status without headers', () {
      final options = RequestOptions(
        path: '/mail',
        baseUrl: 'https://api.test',
        method: 'POST',
        headers: <String, dynamic>{'Authorization': 'Bearer secret'},
      );
      final error = DioException(
        requestOptions: options,
        response: Response<dynamic>(requestOptions: options, statusCode: 500),
      );

      final reason = dioErrorReason(error);

      expect(reason, 'HTTP 500 on POST /mail');
      expect(reason, isNot(contains('secret')));
    });

    test('information truncates long response bodies', () {
      final options =
          RequestOptions(path: '/mail', baseUrl: 'https://api.test');
      final error = DioException(
        requestOptions: options,
        response: Response<dynamic>(
          requestOptions: options,
          statusCode: 500,
          data: 'x' * 5000,
        ),
      );

      final info = dioErrorInformation(error, maxBodyLength: 100).last;

      expect(info.length, lessThan(200));
      expect(info, endsWith('…(truncated)'));
    });
  });
}
