/// WhileSmart mobile shared crash reporting: a provider-agnostic interface,
/// a guarded bootstrap that captures every uncaught-error channel, and a Dio
/// interceptor for API failures.
///
/// The Firebase Crashlytics implementation lives in `wsm_crash_firebase`, so
/// an app with no Firebase project can wire `LoggingCrashReporter` without
/// pulling in the Crashlytics pods.
///
/// The Bloc observer lives in `package:wsm_crash/bloc.dart` so apps that do
/// not use Bloc never import it.
library;

export 'src/crash_reporting_interceptor.dart';
export 'src/crash_reporting_interface.dart';
export 'src/crash_reporting_service.dart';
export 'src/logging_crash_reporter.dart';
export 'src/run_guarded_app.dart';
