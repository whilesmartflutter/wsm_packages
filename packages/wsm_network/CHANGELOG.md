## 0.2.0

**Breaking:** `SecureTokenStorage` moved to the new `wsm_secure_storage`
package, and the `flutter_secure_storage` dependency went with it. This
package now has **no plugin dependencies** — adopting the interceptors can no
longer force a native-plugin version decision on an app.

- apps using `SecureTokenStorage`: add `wsm_secure_storage` and change the
  import
- apps implementing `TokenStorage` themselves (mobile-pay): no code change,
  and one fewer transitive dependency

## 0.1.1

- Widen the `flutter_secure_storage` constraint to `>=9.0.0 <11.0.0` so apps on
  9.x can adopt the package without a storage migration that could invalidate
  stored tokens.

## 0.1.0

- Initial release: `createDio` factory with enforced timeouts, `TokenInterceptor`,
  redacting `NetworkLoggerInterceptor`, `LocaleInterceptor`,
  `RemoveNullValuesInterceptor`, and `TokenStorage` (secure + in-memory).
