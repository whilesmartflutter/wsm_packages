import 'dart:async';

import 'package:dio/dio.dart';
import 'package:meta/meta.dart';

import 'crash_reporting_service.dart';

/// Reports server-side API failures (5xx and 422) as non-fatals.
///
/// Deduplicated per `method + normalized path + status` for the lifetime of
/// the process, so one broken endpoint hit in a retry loop produces one
/// report rather than hundreds. 4xx responses other than 422 are the app's
/// own business and are not reported.
class CrashReportingInterceptor extends Interceptor {
  CrashReportingInterceptor(
    this._crashReporting, {
    this.maxBodyLength = 2000,
  });

  final CrashReportingService _crashReporting;
  final int maxBodyLength;
  final Set<String> _reported = <String>{};

  static final RegExp _idSegment = RegExp(r'^(\d+|[0-9a-fA-F:-]{8,})$');

  /// Whether a response with [status] warrants a report.
  @visibleForTesting
  static bool shouldReport(int? status) =>
      status != null && (status >= 500 || status == 422);

  /// Replaces numeric and uuid-ish path segments with `{id}` so the same
  /// endpoint deduplicates across records.
  @visibleForTesting
  static String normalizePath(String path) => path
      .split('/')
      .map((segment) => _idSegment.hasMatch(segment) ? '{id}' : segment)
      .join('/');

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final status = err.response?.statusCode;
    if (shouldReport(status)) {
      final options = err.requestOptions;
      final key =
          '${options.method} ${normalizePath(options.uri.path)} $status';

      if (_reported.add(key)) {
        final body = err.response?.data?.toString() ?? '';
        unawaited(
          _crashReporting.recordError(
            err,
            stackTrace: err.stackTrace,
            reason: 'HTTP $status on ${options.method} ${options.uri.path}',
            information: <String, dynamic>{
              'url': options.uri.toString(),
              'status': status,
              if (body.isNotEmpty)
                'response': body.length > maxBodyLength
                    ? '${body.substring(0, maxBodyLength)}…(truncated)'
                    : body,
            },
          ),
        );
      }
    }
    handler.next(err);
  }
}
