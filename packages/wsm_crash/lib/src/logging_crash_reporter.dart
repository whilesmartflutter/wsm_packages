import 'package:logger/logger.dart';

import 'crash_reporting_interface.dart';

/// [CrashReportingInterface] that only writes to the local log.
///
/// Use it while an app has no crash backend provisioned yet, and in tests.
/// Wiring this from day one means the call sites, the guarded bootstrap and
/// the Dio interceptor are all in place; switching to
/// `FirebaseCrashReporter` later is a one-line change in the composition
/// root instead of a retrofit.
class LoggingCrashReporter implements CrashReportingInterface {
  LoggingCrashReporter({Logger? logger})
      : _log = logger ?? Logger(printer: PrettyPrinter(methodCount: 0));

  final Logger _log;

  @override
  Future<void> initialize() async {
    _log.i('wsm_crash: local logging reporter active (no crash backend)');
  }

  @override
  Future<void> recordError(
    Object error, {
    StackTrace? stackTrace,
    String? reason,
    Map<String, dynamic>? information,
  }) async {
    _log.e(reason ?? 'non-fatal', error: error, stackTrace: stackTrace);
  }

  @override
  Future<void> recordFatalError(
    Object error, {
    StackTrace? stackTrace,
    String? reason,
    Map<String, dynamic>? information,
  }) async {
    _log.f(reason ?? 'fatal', error: error, stackTrace: stackTrace);
  }

  @override
  Future<void> setCustomKey(String key, Object? value) async {
    _log.d('wsm_crash key: $key=$value');
  }

  @override
  Future<void> setUserId(String userId) async {
    _log.d('wsm_crash user: $userId');
  }

  @override
  Future<void> log(String message, {String? level}) async {
    _log.d('wsm_crash: ${level == null ? '' : '[$level] '}$message');
  }
}
