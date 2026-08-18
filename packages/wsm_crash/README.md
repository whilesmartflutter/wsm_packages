# wsm_crash

Shared crash reporting for WhileSmart mobile apps: a provider-agnostic
interface, a Firebase Crashlytics implementation, a bootstrap that captures
every uncaught-error channel, a Dio interceptor for API failures, and a Bloc
observer.

```yaml
dependencies:
  wsm_crash:
    git:
      url: https://github.com/whilesmartflutter/wsm_packages.git
      ref: wsm_crash-v0.1.0
      path: packages/wsm_crash
```

## Bootstrap

```dart
Future<void> main() => runGuardedApp(
      builder: () => const App(),
      reporter: FirebaseCrashReporter(),
      beforeRun: () async {
        await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
        await configureDependencies();
      },
      onReady: (service) {
        Bloc.observer = AppBlocObserver(service);          // package:wsm_crash/bloc.dart
        dio.interceptors.add(CrashReportingInterceptor(service));
      },
    );
```

`runGuardedApp` wires `FlutterError.onError`, `PlatformDispatcher.onError` and
a guarded zone. The reporter is a parameter rather than a service-locator
lookup, so an error thrown *before* DI finishes still has somewhere to go.

## No crash backend yet?

Use `LoggingCrashReporter()` in place of `FirebaseCrashReporter()`. Every call
site, the bootstrap and the interceptor are then already in place, and
switching to Crashlytics later is one line in the composition root.

## The personal-data rule

**Crash reports carry an opaque user id and nothing else identifying a
person.** `CrashReportingService.setCustomKey` refuses keys that name personal
data (email, phone, first/last name, username, address, card, …): it asserts in
debug and drops the key in release. An earlier in-app version of this code sent
all four of email, phone, first and last name to Crashlytics on every report —
this class exists so that cannot recur.

Use `setUserId('usr_9f2c')` for identity, and coarse attributes (plan tier,
flavor, feature flag) for context.

## Reporting rules

`CrashReportingInterceptor` reports **5xx and 422 only**, deduplicated per
`method + normalized path + status` for the process lifetime, with the
response body truncated. Other 4xx responses are the app's own business.
`AppBlocObserver` forwards bloc/cubit errors, which Bloc otherwise swallows
before they reach the zone.
