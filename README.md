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
| [`wsm_network`](packages/wsm_network) | `createDio` factory with sane timeouts, `TokenInterceptor`, redacting `NetworkLoggerInterceptor`, `LocaleInterceptor`, `RemoveNullValuesInterceptor`, and the `TokenStorage` interface. No plugin dependencies. |
| [`wsm_bloc`](packages/wsm_bloc) | `CubitListenable` (go_router bridge) and `SafeCubit` (emits guarded after close). |
| [`wsm_secure_storage`](packages/wsm_secure_storage) | `SecureTokenStorage` — the keychain/keystore implementation of `TokenStorage`. |
| [`wsm_crash_firebase`](packages/wsm_crash_firebase) | `FirebaseCrashReporter` — the Crashlytics implementation of `wsm_crash`'s interface, split out so apps without a Firebase project skip the pods. |
| [`wsm_crash`](packages/wsm_crash) | `CrashReportingInterface`/`CrashReportingService`, Firebase Crashlytics and local-logging implementations, `CrashReportingInterceptor`, `AppBlocObserver`, `runGuardedApp` bootstrap helper. |

## Layering rule

**`wsm_x` holds interfaces and pure-Dart logic and depends on no plugins.
`wsm_x_<vendor>` / `wsm_<impl>` holds the plugin-backed implementation.**

Plugin dependencies (native code, Gradle plugins, pods, platform floors) are
the ones that cause irreducible version conflicts between apps. Keeping them
out of the interface packages means adopting shared code never forces a native
version decision on an app — `wsm_crash` works without Firebase, `wsm_network`
works without a secure-storage plugin, and each app opts into the
implementation it wants:

| Interface package | Implementation package |
|---|---|
| `wsm_crash` (`CrashReportingInterface`, `LoggingCrashReporter`) | `wsm_crash_firebase` (Crashlytics) |
| `wsm_network` (`TokenStorage`) | `wsm_secure_storage` (keychain/keystore) |

Implementation packages depend on their interface package, which is the only
dependency between siblings. **That cross-dependency requires a
`dependency_overrides` entry in the consuming app** — pub treats the app's git
source and the package's hosted constraint as incompatible sources otherwise.
Each implementation package's README shows the exact block. Wire them together in the app's
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
(cd packages/wsm_crash_firebase && flutter test)
(cd packages/wsm_bloc && flutter test)
(cd packages/wsm_secure_storage && flutter test)
```

## Releasing

Bump the package's `version:` in its `pubspec.yaml` and update its
`CHANGELOG.md`, merge to `main`, then:

```sh
./scripts/release.sh wsm_core 0.2.0
```

The script verifies the pubspec version matches and pushes the
`wsm_core-v0.2.0` tag consumers pin against.
