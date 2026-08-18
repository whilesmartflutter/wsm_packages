# wsm_secure_storage

Keychain/keystore-backed implementation of [`wsm_network`](../wsm_network)'s
`TokenStorage`.

Separate from `wsm_network` on purpose. That package is `dio` plus pure Dart,
so an app can take the interceptors without inheriting a **native plugin** —
and without being forced into a `flutter_secure_storage` major version it is
not ready for. Adopting shared code should never make a native-dependency
decision on an app's behalf.

```yaml
dependencies:
  wsm_network:
    git:
      url: https://github.com/whilesmartflutter/wsm_packages.git
      ref: wsm_network-v0.2.0
      path: packages/wsm_network
  wsm_secure_storage:
    git:
      url: https://github.com/whilesmartflutter/wsm_packages.git
      ref: wsm_secure_storage-v0.1.0
      path: packages/wsm_secure_storage

# Required. wsm_secure_storage declares wsm_network as a version constraint
# (a hosted source), while the app takes it from git. pub treats those as
# different sources and refuses to resolve unless told which one wins.
dependency_overrides:
  wsm_network:
    git:
      url: https://github.com/whilesmartflutter/wsm_packages.git
      ref: wsm_network-v0.2.0
      path: packages/wsm_network
```

```dart
final tokenStorage = SecureTokenStorage(keyPrefix: 'desk');

final dio = createDio(
  baseUrl: env.apiBaseUrl,
  interceptors: [
    TokenInterceptor(getToken: tokenStorage.read, onUnauthorized: signOut),
  ],
);
```

`keyPrefix` namespaces the entries (`desk_access_token`, `pay_access_token`),
so several WhileSmart apps installed on one device never collide.

## When not to use this

If the app already has its own credential store, implement `TokenStorage`
over it instead — that keeps existing keys, so adopting `wsm_network` does not
sign current users out. `mobile-pay` does exactly that with a ~30-line
adapter.
