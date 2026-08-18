# wsm_crash_firebase

Firebase Crashlytics implementation of [`wsm_crash`](../wsm_crash)'s
`CrashReportingInterface`.

Separate from `wsm_crash` on purpose: an app with no Firebase project yet can
depend on `wsm_crash` alone and wire `LoggingCrashReporter`, without pulling
the Crashlytics pods into its iOS and Android builds. When the Firebase
project exists, add this package and change one line in the composition root.

```yaml
dependencies:
  wsm_crash:
    git:
      url: https://github.com/whilesmartflutter/wsm_packages.git
      ref: wsm_crash-v0.1.0
      path: packages/wsm_crash
  wsm_crash_firebase:
    git:
      url: https://github.com/whilesmartflutter/wsm_packages.git
      ref: wsm_crash_firebase-v0.1.0
      path: packages/wsm_crash_firebase
```

Both entries are required — this package declares `wsm_crash` as a normal
version constraint, and the app's own git dependency is what supplies it.

```dart
Future<void> main() => runGuardedApp(
      builder: () => const App(),
      reporter: FirebaseCrashReporter(),
      beforeRun: () => Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      ),
    );
```

`FirebaseCrashReporter` adds the response body and endpoint to `DioException`
reports (which `DioException.toString()` omits) and deliberately never
includes request headers — they carry the bearer token.
