import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:wsm_network/wsm_network.dart';

/// [TokenStorage] backed by the platform keychain/keystore.
///
/// [keyPrefix] namespaces the entries so several WhileSmart apps can coexist
/// on one device without colliding — pass the app's short name
/// (e.g. `desk`, `pay`).
///
/// Credentials belong in the platform keystore. Do not write a
/// SharedPreferences implementation of [TokenStorage].
class SecureTokenStorage implements TokenStorage {
  SecureTokenStorage({
    required String keyPrefix,
    FlutterSecureStorage? storage,
  })  : _keyPrefix = keyPrefix,
        _storage = storage ??
            const FlutterSecureStorage(
              iOptions: IOSOptions(
                accessibility: KeychainAccessibility.first_unlock,
              ),
            );

  final String _keyPrefix;
  final FlutterSecureStorage _storage;

  String get _tokenKey => '${_keyPrefix}_access_token';

  String get _refreshTokenKey => '${_keyPrefix}_refresh_token';

  @override
  Future<String?> read() => _storage.read(key: _tokenKey);

  @override
  Future<void> save(String token) =>
      _storage.write(key: _tokenKey, value: token);

  @override
  Future<String?> readRefreshToken() => _storage.read(key: _refreshTokenKey);

  @override
  Future<void> saveRefreshToken(String token) =>
      _storage.write(key: _refreshTokenKey, value: token);

  @override
  Future<void> clear() async {
    await _storage.delete(key: _tokenKey);
    await _storage.delete(key: _refreshTokenKey);
  }

  @override
  Future<bool> get hasToken async {
    final token = await read();
    return token != null && token.isNotEmpty;
  }
}
