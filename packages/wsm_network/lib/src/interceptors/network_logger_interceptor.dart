import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';

/// Logs requests, responses and errors **without leaking credentials**.
///
/// Three rules this interceptor exists to enforce:
///
/// 1. `Authorization`, cookie and other credential-bearing headers are
///    replaced with `***` — never printed, in any build.
/// 2. Bodies are only logged when [logBodies] is true, which defaults to
///    [kDebugMode]. A release build logs status lines only.
/// 3. Bodies are truncated to [maxBodyLength] so a large response cannot
///    flood the log buffer.
///
/// Uses the `logger` package (release-suppressed by default) rather than
/// `debugPrint`, which prints in release builds too.
class NetworkLoggerInterceptor extends Interceptor {
  NetworkLoggerInterceptor({
    Logger? logger,
    bool? logBodies,
    this.maxBodyLength = 2000,
  })  : _log = logger ?? Logger(printer: PrettyPrinter(methodCount: 0)),
        logBodies = logBodies ?? kDebugMode;

  final Logger _log;

  /// Whether request/response bodies are logged at all. Defaults to
  /// [kDebugMode] — leave it off in release.
  final bool logBodies;

  /// Bodies longer than this are truncated with a `…(truncated)` marker.
  final int maxBodyLength;

  static const String _redacted = '***';

  static final RegExp _sensitiveHeader = RegExp(
    r'^(authorization|proxy-authorization|cookie|set-cookie|x-api-key|x-auth-token|api-?key)$',
    caseSensitive: false,
  );

  static final RegExp _sensitiveField = RegExp(
    r'(password|token|secret|otp|pin|authorization|api_?key)',
    caseSensitive: false,
  );

  /// Copies [headers] with credential-bearing values replaced by `***`.
  @visibleForTesting
  static Map<String, dynamic> redactHeaders(Map<String, dynamic> headers) {
    return headers.map(
      (key, dynamic value) => MapEntry(
        key,
        _sensitiveHeader.hasMatch(key.trim()) ? _redacted : value,
      ),
    );
  }

  /// Renders [body] for logging: sensitive fields masked, output truncated.
  @visibleForTesting
  String redactBody(Object? body) {
    if (body == null) return '';
    if (body is FormData) {
      final fields = body.fields
          .map((f) => _sensitiveField.hasMatch(f.key)
              ? '${f.key}: $_redacted'
              : '${f.key}: ${f.value}')
          .join(', ');
      return _truncate('FormData{$fields, files: ${body.files.length}}');
    }

    final Object? masked = _mask(body);
    final String text;
    try {
      text = masked is String ? masked : jsonEncode(masked);
    } on Object {
      return _truncate(masked.toString());
    }
    return _truncate(text);
  }

  static Object? _mask(Object? value) {
    if (value is Map) {
      return value.map<String, dynamic>(
        (dynamic key, dynamic v) => MapEntry(
          key.toString(),
          _sensitiveField.hasMatch(key.toString()) ? _redacted : _mask(v),
        ),
      );
    }
    if (value is List) return value.map(_mask).toList();
    return value;
  }

  String _truncate(String text) => text.length <= maxBodyLength
      ? text
      : '${text.substring(0, maxBodyLength)}…(truncated)';

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    _log.i('-> ${options.method} ${options.uri}');
    if (logBodies) {
      _log
        ..d('   headers: ${redactHeaders(options.headers)}')
        ..d('   body: ${redactBody(options.data)}');
    }
    handler.next(options);
  }

  @override
  void onResponse(
    Response<dynamic> response,
    ResponseInterceptorHandler handler,
  ) {
    _log.i('<- ${response.statusCode} '
        '${response.requestOptions.method} ${response.requestOptions.uri}');
    if (logBodies) {
      _log.d('   body: ${redactBody(response.data)}');
    }
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    _log.e('xx ${err.response?.statusCode ?? err.type.name} '
        '${err.requestOptions.method} ${err.requestOptions.uri}: '
        '${err.message}');
    if (logBodies) {
      _log.d('   body: ${redactBody(err.response?.data)}');
    }
    handler.next(err);
  }
}
