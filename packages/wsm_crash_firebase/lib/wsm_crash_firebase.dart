/// Firebase Crashlytics implementation of `wsm_crash`'s
/// `CrashReportingInterface`.
///
/// Kept in its own package so an app that has no Firebase project yet can
/// depend on `wsm_crash` alone — wiring `LoggingCrashReporter` — without
/// pulling the Crashlytics pods into its iOS and Android builds.
library;

export 'src/firebase_crash_reporter.dart';
