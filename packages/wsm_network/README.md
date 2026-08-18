# wsm_network

Shared networking for WhileSmart mobile apps: one `Dio` factory and the
standard interceptor set.

**No plugin dependencies** — `dio` plus pure Dart. The keychain-backed
`TokenStorage` implementation lives in
[`wsm_secure_storage`](../wsm_secure_storage); apps that already have a
credential store implement the interface over it instead.

```yaml
dependencies:
  wsm_network:
    git:
      url: https://github.com/whilesmartflutter/wsm_packages.git
      ref: wsm_network-v0.2.0
      path: packages/wsm_network
```

## Composition root

```dart
final tokenStorage = SecureTokenStorage(keyPrefix: 'desk'); // wsm_secure_storage

final dio = createDio(
  baseUrl: env.apiBaseUrl,
  interceptors: [
    TokenInterceptor(
      getToken: tokenStorage.read,
      onUnauthorized: () async {
        await tokenStorage.clear();
        authCubit.signedOut();          // the UI must react immediately
      },
    ),
    RemoveNullValuesInterceptor(),
    LocaleInterceptor(localeCode: () => Localizations.localeOf(context).languageCode),
    NetworkLoggerInterceptor(),
  ],
);
```

## What each piece guarantees

| Component | Guarantee |
|---|---|
| `createDio` | connect/receive/send timeouts are **always** set — a dropped connection cannot hang forever |
| `TokenInterceptor` | attaches the bearer token; on a 401 it calls `onUnauthorized` **only** for requests that carried a token and did not target an auth endpoint, so a wrong password never signs the user out |
| `NetworkLoggerInterceptor` | `Authorization`/cookie/api-key headers are replaced with `***`; bodies are logged only in debug (`logBodies`), masked (`password`, `token`, `otp`, …) and truncated |
| `RemoveNullValuesInterceptor` | drops null entries from map bodies so optional fields are omitted rather than nulled |
| `LocaleInterceptor` | sets `Accept-Language` from a supplier — no dependency on a specific localization package |
| `TokenStorage` | the interface the interceptor's token supplier is usually backed by; `InMemoryTokenStorage` for tests. Keychain implementation in `wsm_secure_storage` |

## Security defaults

These encode fixes for real leaks found in earlier in-app copies. Do not
regress them:

- never log credential-bearing headers, in any build;
- never log bodies in release;
- always set timeouts;
- credentials live in secure storage, never `SharedPreferences`.

`TokenInterceptor` takes a `getToken` **callback**, not a storage object, so
nothing here is coupled to how an app persists credentials.
