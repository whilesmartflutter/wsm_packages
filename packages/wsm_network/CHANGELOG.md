## 0.1.1

- Widen the `flutter_secure_storage` constraint to `>=9.0.0 <11.0.0` so apps on
  9.x can adopt the package without a storage migration that could invalidate
  stored tokens.

## 0.1.0

- Initial release: `createDio` factory with enforced timeouts, `TokenInterceptor`,
  redacting `NetworkLoggerInterceptor`, `LocaleInterceptor`,
  `RemoveNullValuesInterceptor`, and `TokenStorage` (secure + in-memory).
