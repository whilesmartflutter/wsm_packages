import 'package:dio/dio.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:meta/meta.dart';

import 'crash_reporting_interface.dart';

/// Firebase Crashlytics implementation of [CrashReportingInterface].
///
/// Requires `Firebase.initializeApp()` to have completed first — do that in
/// the `beforeRun` callback of `runGuardedApp`.
class FirebaseCrashReporter implements CrashReportingInterface {
  FirebaseCrashReporter({FirebaseCrashlytics? crashlytics})
      : _crashlytics = crashlytics ?? FirebaseCrashlytics.instance;

  final FirebaseCrashlytics _crashlytics;

  @override
  Future<void> initialize() async {
    await _crashlytics.setCrashlyticsCollectionEnabled(true);
    await _crashlytics.sendUnsentReports();
  }

  @override
  Future<void> recordError(
    Object error, {
    StackTrace? stackTrace,
    String? reason,
    Map<String, dynamic>? information,
  }) =>
      _record(
        error,
        stackTrace: stackTrace,
        reason: reason,
        information: information,
        fatal: false,
      );

  @override
  Future<void> recordFatalError(
    Object error, {
    StackTrace? stackTrace,
    String? reason,
    Map<String, dynamic>? information,
  }) =>
      _record(
        error,
        stackTrace: stackTrace,
        reason: reason,
        information: information,
        fatal: true,
      );

  Future<void> _record(
    Object error, {
    required bool fatal,
    StackTrace? stackTrace,
    String? reason,
    Map<String, dynamic>? information,
  }) {
    return _crashlytics.recordError(
      error,
      stackTrace,
      reason: reason ?? (error is DioException ? dioErrorReason(error) : null),
      information: <Object>[
        ...?information?.entries.map((e) => '{ ${e.key}: ${e.value} }'),
        if (error is DioException) ...dioErrorInformation(error),
      ],
      fatal: fatal,
    );
  }

  @override
  Future<void> setCustomKey(String key, Object? value) =>
      _crashlytics.setCustomKey(key, value ?? 'null');

  @override
  Future<void> setUserId(String userId) =>
      _crashlytics.setUserIdentifier(userId);

  @override
  Future<void> log(String message, {String? level}) =>
      _crashlytics.log(level == null ? message : '[$level] $message');
}

/// `DioException.toString()` omits the response body; this restores the part
/// that makes an API failure diagnosable. Headers stay out — they carry the
/// bearer token.
@visibleForTesting
String dioErrorReason(DioException error) {
  final options = error.requestOptions;
  final status = error.response?.statusCode;
  return 'HTTP ${status ?? error.type.name} on '
      '${options.method} ${options.uri.path}';
}

/// Request/response context lines for a [DioException], body truncated.
@visibleForTesting
List<String> dioErrorInformation(
  DioException error, {
  int maxBodyLength = 2000,
}) {
  final options = error.requestOptions;
  final body = error.response?.data?.toString() ?? '';
  return <String>[
    '${options.method} ${options.uri}',
    if (error.response?.statusCode != null)
      'status: ${error.response!.statusCode}',
    if (body.isNotEmpty)
      'response: ${body.length > maxBodyLength ? '${body.substring(0, maxBodyLength)}…(truncated)' : body}',
  ];
}
