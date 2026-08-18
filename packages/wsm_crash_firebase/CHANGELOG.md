## 0.1.1

- Widen the `firebase_crashlytics` constraint to `>=4.0.0 <6.0.0` so apps on
  Crashlytics 4.x (mobile-pay) can adopt the package without a Firebase major
  upgrade.

## 0.1.0

- Initial release: `FirebaseCrashReporter`, split out of `wsm_crash` so apps
  without a Firebase project do not pull in the Crashlytics pods.
