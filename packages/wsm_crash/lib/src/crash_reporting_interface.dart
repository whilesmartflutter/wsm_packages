/// A crash reporting backend.
///
/// Implemented by `FirebaseCrashReporter` and `LoggingCrashReporter`; add
/// another implementation (Sentry, …) rather than depending on a vendor SDK
/// from app code.
abstract class CrashReportingInterface {
  /// Prepares the backend. Must tolerate being called before the app has a
  /// signed-in user, and must not throw.
  Future<void> initialize();

  /// Records a handled error.
  Future<void> recordError(
    Object error, {
    StackTrace? stackTrace,
    String? reason,
    Map<String, dynamic>? information,
  });

  /// Records an error that terminated (or should be treated as terminating)
  /// the app.
  Future<void> recordFatalError(
    Object error, {
    StackTrace? stackTrace,
    String? reason,
    Map<String, dynamic>? information,
  });

  /// Attaches a key/value pair to subsequent reports.
  ///
  /// Values must not contain personal data — see [CrashReportingService].
  Future<void> setCustomKey(String key, Object? value);

  /// Associates subsequent reports with an **opaque** user id.
  Future<void> setUserId(String userId);

  /// Adds a breadcrumb to subsequent reports.
  Future<void> log(String message, {String? level});
}
