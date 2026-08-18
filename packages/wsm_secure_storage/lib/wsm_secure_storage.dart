/// Keychain/keystore-backed implementation of `wsm_network`'s `TokenStorage`.
///
/// Separate from `wsm_network` on purpose: that package is pure Dart plus
/// `dio`, so an app can adopt the interceptors without inheriting a native
/// plugin — and without being forced into a `flutter_secure_storage` major
/// version it isn't ready for. Apps that already have their own credential
/// store implement `TokenStorage` themselves and skip this package.
library;

export 'src/secure_token_storage.dart';
