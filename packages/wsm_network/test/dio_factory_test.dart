import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wsm_network/wsm_network.dart';

void main() {
  group('createDio', () {
    test('always sets timeouts', () {
      final dio = createDio(baseUrl: 'https://api.example.com');

      expect(dio.options.connectTimeout, isNotNull);
      expect(dio.options.receiveTimeout, isNotNull);
      expect(dio.options.sendTimeout, isNotNull);
    });

    test('applies base url, json headers and interceptors', () {
      final interceptor = RemoveNullValuesInterceptor();
      final dio = createDio(
        baseUrl: 'https://api.example.com',
        interceptors: [interceptor],
      );

      expect(dio.options.baseUrl, 'https://api.example.com');
      expect(dio.options.headers['Accept'], 'application/json');
      expect(dio.interceptors, contains(interceptor));
    });

    test('honours overridden timeouts', () {
      final dio = createDio(
        baseUrl: 'https://api.example.com',
        receiveTimeout: const Duration(minutes: 2),
      );

      expect(dio.options.receiveTimeout, const Duration(minutes: 2));
    });
  });

  group('RemoveNullValuesInterceptor', () {
    test('drops null entries from map bodies', () {
      final options = RequestOptions(
        path: '/x',
        data: <String, dynamic>{'a': 1, 'b': null},
      );

      RemoveNullValuesInterceptor()
          .onRequest(options, RequestInterceptorHandler());

      expect(options.data, <String, dynamic>{'a': 1});
    });

    test('leaves non-map bodies alone', () {
      final options = RequestOptions(path: '/x', data: 'raw');

      RemoveNullValuesInterceptor()
          .onRequest(options, RequestInterceptorHandler());

      expect(options.data, 'raw');
    });
  });

  group('LocaleInterceptor', () {
    test('sets Accept-Language from the supplier', () {
      final options = RequestOptions(path: '/x');

      LocaleInterceptor(localeCode: () => 'fr')
          .onRequest(options, RequestInterceptorHandler());

      expect(options.headers['Accept-Language'], 'fr');
    });

    test('omits the header when the supplier returns null', () {
      final options = RequestOptions(path: '/x');

      LocaleInterceptor(localeCode: () => null)
          .onRequest(options, RequestInterceptorHandler());

      expect(options.headers.containsKey('Accept-Language'), isFalse);
    });
  });

  group('InMemoryTokenStorage', () {
    test('round-trips and clears both tokens', () async {
      final storage = InMemoryTokenStorage();

      expect(await storage.hasToken, isFalse);

      await storage.save('a');
      await storage.saveRefreshToken('r');

      expect(await storage.read(), 'a');
      expect(await storage.readRefreshToken(), 'r');
      expect(await storage.hasToken, isTrue);

      await storage.clear();

      expect(await storage.read(), isNull);
      expect(await storage.readRefreshToken(), isNull);
    });
  });
}
