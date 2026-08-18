import 'package:logger/logger.dart';
import 'package:meta/meta.dart';

import 'crash_reporting_interface.dart';

/// The façade app code talks to. Wraps a [CrashReportingInterface] and
/// enforces the one rule that must never be broken:
///
/// **Crash reports must carry an opaque user id and nothing else that
/// identifies a person.** Email addresses, phone numbers, real names and
/// usernames are not permitted as custom keys — an earlier in-app version of
/// this code sent all four to Crashlytics on every report. [setCustomKey]
/// drops such keys instead of forwarding them.
///
/// Every method swallows backend errors: a failure to report a crash must
/// never itself crash the app.
class CrashReportingService {
  CrashReportingService(this._reporter, {Logger? logger})
      : _log = logger ?? Logger(printer: PrettyPrinter(methodCount: 0));

  final CrashReportingInterface _reporter;
  final Logger _log;

  static final RegExp _piiKey = RegExp(
    r'(e-?mail|phone|msisdn|first_?name|last_?name|full_?name|user_?name|street|address|date_?of_?birth|passport|national_?id|card_?number|iban|ssn)',
    caseSensitive: false,
  );

  /// Whether [key] names something that must not reach a crash report.
  @visibleForTesting
  static bool isPersonalDataKey(String key) => _piiKey.hasMatch(key);

  Future<void> initialize() => _guard('initialize', _reporter.initialize);

  Future<void> recordError(
    Object error, {
    StackTrace? stackTrace,
    String? reason,
    Map<String, dynamic>? information,
  }) =>
      _guard(
        'recordError',
        () => _reporter.recordError(
          error,
          stackTrace: stackTrace,
          reason: reason,
          information: information,
        ),
      );

  Future<void> recordFatalError(
    Object error, {
    StackTrace? stackTrace,
    String? reason,
    Map<String, dynamic>? information,
  }) =>
      _guard(
        'recordFatalError',
        () => _reporter.recordFatalError(
          error,
          stackTrace: stackTrace,
          reason: reason,
          information: information,
        ),
      );

  /// Attaches a key/value pair to subsequent reports.
  ///
  /// Keys naming personal data are dropped with a warning — pass an opaque
  /// id or a coarse attribute (plan tier, feature flag) instead.
  Future<void> setCustomKey(String key, Object? value) async {
    if (isPersonalDataKey(key)) {
      _log.w(
        'wsm_crash: dropped custom key "$key" — crash reports must not '
        'contain personal data. Use an opaque identifier instead.',
      );
      return;
    }
    await _guard('setCustomKey', () => _reporter.setCustomKey(key, value));
  }

  /// Associates subsequent reports with an opaque user id — a server-side
  /// user id or a random installation id, never an email or phone number.
  Future<void> setUserId(String userId) =>
      _guard('setUserId', () => _reporter.setUserId(userId));

  /// Convenience for [setCustomKey] over several entries; each key goes
  /// through the same personal-data check.
  Future<void> setUserProperties(Map<String, Object?> properties) async {
    for (final entry in properties.entries) {
      await setCustomKey(entry.key, entry.value);
    }
  }

  Future<void> log(String message, {String? level}) =>
      _guard('log', () => _reporter.log(message, level: level));

  /// Records an API failure as a non-fatal, with the endpoint as context.
  Future<void> recordApiError(
    String endpoint,
    int? statusCode,
    String message, {
    Map<String, dynamic>? information,
  }) =>
      recordError(
        Exception('API error: $message'),
        reason: 'HTTP ${statusCode ?? 'error'} on $endpoint',
        information: <String, dynamic>{
          'endpoint': endpoint,
          'status': statusCode,
          ...?information,
        },
      );

  Future<void> _guard(String operation, Future<void> Function() action) async {
    try {
      await action();
    } on Object catch (error, stackTrace) {
      _log.e('wsm_crash: $operation failed',
          error: error, stackTrace: stackTrace);
    }
  }
}
