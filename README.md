# wsm_packages

Shared Flutter/Dart infrastructure for WhileSmart mobile apps.

`wsm_` = **W**hile**S**mart **M**obile. The prefix marks internal shared
libraries, as opposed to `whilesmart_*` package names, which are reserved for
shippable applications (`whilesmart_desk`, `whilesmart_pay`). Generic
open-source packages (e.g. [drift_sync](https://github.com/whilesmartflutter/drift_sync))
keep descriptive unprefixed names.

## Packages

| Package | Contents |
|---|---|
| [`wsm_core`](packages/wsm_core) | `Failure` model, `ApiException` hierarchy, `ErrorHandler` / `RepositoryErrorHandler`, use-case base classes, `AsyncState<T>` / `MutationState`, logger factory. Pure Dart. |
| [`wsm_network`](packages/wsm_network) | `createDio` factory with sane timeouts, `TokenInterceptor`, redacting `NetworkLoggerInterceptor`, `LocaleInterceptor`, `RemoveNullValuesInterceptor`, `TokenStorage`. |
| [`wsm_crash`](packages/wsm_crash) | `CrashReportingInterface`/`CrashReportingService`, Firebase Crashlytics and local-logging implementations, `CrashReportingInterceptor`, `AppBlocObserver`, `runGuardedApp` bootstrap helper. |

Packages are intentionally independent siblings (no cross-dependencies),
mirroring the drift_sync repo layout. Wire them together in the app's
composition root — see each package README.

## Consuming a package

```yaml
dependencies:
  wsm_core:
    git:
      url: https://github.com/whilesmartflutter/wsm_packages.git
      ref: wsm_core-v0.1.0
      path: packages/wsm_core
```

Each package is versioned independently through git tags of the form
`<package>-v<semver>`.

## Security defaults

These packages encode fixes for issues found in earlier in-app copies of this
code. Do not regress them when contributing:

- `NetworkLoggerInterceptor` **redacts `Authorization` and cookie headers** and
  only logs request/response bodies in debug builds, truncated.
- `createDio` always sets connect/receive/send **timeouts**.
- Crash reporting must only ever receive an **opaque user id** — never email,
  phone numbers, or names as custom keys. `CrashReportingService` *enforces*
  this: it drops custom keys whose name matches personal data and logs a
  warning.

## State modelling

`wsm_core` ships `AsyncState<T>` (`initial | loading | data | failure`, each
carrying the previous value through a refresh) and `MutationState`
(`idle | inProgress | success | failure`). Use them instead of
`isLoading`/`isSaving`/`isDeleting` boolean sets in bloc/cubit states: the
sealed types make contradictory states unrepresentable and make `switch` in
the UI exhaustive.

## Development

This repo is a Dart pub workspace. From the repo root:

```sh
flutter pub get
dart format .
flutter analyze
(cd packages/wsm_core && dart test)
(cd packages/wsm_network && flutter test)
(cd packages/wsm_crash && flutter test)
```

## Releasing

Bump the package's `version:` in its `pubspec.yaml` and update its
`CHANGELOG.md`, merge to `main`, then:

```sh
./scripts/release.sh wsm_core 0.2.0
```

The script verifies the pubspec version matches and pushes the
`wsm_core-v0.2.0` tag consumers pin against.
