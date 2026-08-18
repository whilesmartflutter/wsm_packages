import 'package:logger/logger.dart';

/// Creates a [Logger] with the WhileSmart house format.
///
/// Uses the `logger` package's default [DevelopmentFilter], so output is
/// automatically suppressed in release builds.
Logger createWsmLogger({
  int methodCount = 2,
  int errorMethodCount = 8,
  int lineLength = 120,
}) {
  return Logger(
    printer: PrettyPrinter(
      methodCount: methodCount,
      errorMethodCount: errorMethodCount,
      lineLength: lineLength,
    ),
  );
}

/// Shared default logger for app and package code.
final Logger wsmLogger = createWsmLogger();
