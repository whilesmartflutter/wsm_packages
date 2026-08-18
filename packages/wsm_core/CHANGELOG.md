# Changelog

## 0.1.0

- Initial release, lifted from trakli-mobile's `lib/core/error` and
  `lib/core/usecases` with the following changes:
  - `Failure` is a plain Dart sealed class hierarchy (no freezed codegen),
    keeping trakli's named factory constructors (`Failure.serverError(...)`,
    `Failure.none()`, …) so call sites migrate mechanically.
  - `Failure.customMessage` removed: user-facing messages are localization,
    which belongs to the app. Map failures to strings in the app layer.
  - `ErrorHandler` no longer depends on a crash-reporting class; wire one in
    with `ErrorHandler.setReporter(...)` tear-offs (signatures match
    `wsm_crash`'s `CrashReportingService`).
  - `FieldError.getErrors` no longer logs whole response bodies.
