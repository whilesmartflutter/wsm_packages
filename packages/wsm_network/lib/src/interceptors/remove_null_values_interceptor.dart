import 'package:dio/dio.dart';

/// Strips null-valued entries from map request bodies.
///
/// Lets callers build request payloads with optional fields spelled as
/// `null` without the backend treating them as "set this to null".
/// [FormData] and list bodies are left untouched.
class RemoveNullValuesInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final data = options.data;
    if (data is Map) {
      data.removeWhere((_, dynamic value) => value == null);
    }
    handler.next(options);
  }
}
