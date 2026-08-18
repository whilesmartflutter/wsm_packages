import 'package:dio/dio.dart';

/// Default timeouts. Dio applies none of its own, so a request against a
/// silently dropped connection hangs forever unless these are set.
const Duration kDefaultConnectTimeout = Duration(seconds: 15);
const Duration kDefaultReceiveTimeout = Duration(seconds: 30);
const Duration kDefaultSendTimeout = Duration(seconds: 30);

/// Creates the app's [Dio] instance with WhileSmart defaults.
///
/// Timeouts are always set — pass explicit values to widen them for a
/// long-running endpoint rather than removing them.
///
/// ```dart
/// final dio = createDio(
///   baseUrl: env.apiBaseUrl,
///   interceptors: [
///     TokenInterceptor(getToken: tokenStorage.read, onUnauthorized: signOut),
///     RemoveNullValuesInterceptor(),
///     LocaleInterceptor(localeCode: () => Intl.getCurrentLocale()),
///     NetworkLoggerInterceptor(),
///   ],
/// );
/// ```
Dio createDio({
  required String baseUrl,
  Duration connectTimeout = kDefaultConnectTimeout,
  Duration receiveTimeout = kDefaultReceiveTimeout,
  Duration sendTimeout = kDefaultSendTimeout,
  Map<String, dynamic> headers = const {
    'Accept': 'application/json',
    'Content-Type': 'application/json',
  },
  List<Interceptor> interceptors = const [],
  ResponseType responseType = ResponseType.json,
  bool Function(int?)? validateStatus,
}) {
  final dio = Dio(
    BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: connectTimeout,
      receiveTimeout: receiveTimeout,
      sendTimeout: sendTimeout,
      headers: Map<String, dynamic>.of(headers),
      responseType: responseType,
      validateStatus: validateStatus,
    ),
  );

  dio.interceptors.addAll(interceptors);
  return dio;
}
