import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import 'crash_reporting_interface.dart';
import 'crash_reporting_service.dart';

/// Boots the app with every uncaught-error channel wired to [reporter].
///
/// Flutter leaks errors through four separate channels, and an app that only
/// covers one or two silently loses most of its crashes:
///
/// - `FlutterError.onError` — errors inside the framework (build, layout, …)
/// - `PlatformDispatcher.instance.onError` — uncaught async errors
/// - the enclosing [runZonedGuarded] zone — everything else on this isolate
/// - `Isolate.current.addErrorListener` — errors on other isolates
///   (Crashlytics installs this itself; not duplicated here)
///
/// The reporter is passed in rather than resolved from a service locator, so
/// an error thrown *before* dependency injection finishes still has somewhere
/// to go.
///
/// ```dart
/// Future<void> main() => runGuardedApp(
///       builder: () => const App(),
///       reporter: FirebaseCrashReporter(),
///       beforeRun: () async {
///         await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
///         await configureDependencies();
///       },
///     );
/// ```
Future<void> runGuardedApp({
  required FutureOr<Widget> Function() builder,
  required CrashReportingInterface reporter,
  FutureOr<void> Function()? beforeRun,
  void Function(CrashReportingService service)? onReady,
}) async {
  final service = CrashReportingService(reporter);

  await runZonedGuarded<Future<void>>(
    () async {
      WidgetsFlutterBinding.ensureInitialized();

      await beforeRun?.call();
      await service.initialize();

      FlutterError.onError = (details) {
        FlutterError.presentError(details);
        unawaited(
          service.recordFatalError(
            details.exception,
            stackTrace: details.stack,
            reason: details.context?.toDescription() ?? 'flutter-error',
          ),
        );
      };

      PlatformDispatcher.instance.onError = (error, stackTrace) {
        unawaited(
          service.recordFatalError(
            error,
            stackTrace: stackTrace,
            reason: 'uncaught-async-error',
          ),
        );
        return true;
      };

      onReady?.call(service);

      runApp(await builder());
    },
    (error, stackTrace) {
      unawaited(
        service.recordFatalError(
          error,
          stackTrace: stackTrace,
          reason: 'uncaught-zone-error',
        ),
      );
    },
  );
}
