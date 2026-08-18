# wsm_core

Pure-Dart core for WhileSmart mobile apps: the `Failure` model, the
`ApiException` hierarchy, centralized error mapping, use-case base classes,
and a logger factory.

## Error flow

Two-stage mapping, same contract trakli has used in production:

1. **Datasources** wrap calls in `ErrorHandler.handleApiCall(...)` — raw
   `DioException`s become typed `ApiException`s.
2. **Repositories** wrap calls in `RepositoryErrorHandler.handleApiCall(...)`
   — typed exceptions become `Either<Failure, T>` (fpdart).

```dart
// datasource
Future<UserDto> login(LoginRequest req) => ErrorHandler.handleApiCall(() async {
  final res = await _dio.post('/auth/login', data: req.toJson());
  return UserDto.fromJson(res.data as Map<String, dynamic>);
});

// repository
Future<Either<Failure, User>> login(LoginRequest req) =>
    RepositoryErrorHandler.handleApiCall(() async {
      final dto = await _remote.login(req);
      return dto.toEntity();
    });
```

## Crash reporting hookup (optional)

`wsm_core` has no crash-reporting dependency. To report API/unknown errors,
pass tear-offs at bootstrap — `wsm_crash`'s `CrashReportingService` matches the
signatures:

```dart
ErrorHandler.setReporter(
  recordError: crashReportingService.recordError,
  recordApiError: crashReportingService.recordApiError,
);
```

## Failure messages

`Failure` deliberately carries no user-facing message logic. Localize in the
app:

```dart
extension FailureMessage on Failure {
  String message(AppLocalizations l10n) => switch (this) {
        NetworkFailure() => l10n.noInternet,
        UnauthorizedFailure() => l10n.invalidCredentials,
        ValidationFailure(:final errors) => errors.first.messages.join(', '),
        _ => l10n.somethingWentWrong,
      };
}
```
