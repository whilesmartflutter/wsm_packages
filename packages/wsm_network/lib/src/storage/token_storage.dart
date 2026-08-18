import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Persists auth credentials.
///
/// Credentials belong in the platform keystore/keychain — do not add a
/// SharedPreferences implementation of this interface.
abstract class TokenStorage {
  Future<String?> read();

  Future<void> save(String token);

  Future<String?> readRefreshToken();

  Future<void> saveRefreshToken(String token);

  /// Removes both the access and refresh tokens.
  Future<void> clear();

  Future<bool> get hasToken;
}

/// [TokenStorage] backed by the platform keychain/keystore.
///
/// [keyPrefix] namespaces the entries so several WhileSmart apps can coexist
/// on one device without colliding — pass the app's package suffix
/// (e.g. `desk`, `pay`).
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

/// Non-persistent [TokenStorage] for tests and previews.
class InMemoryTokenStorage implements TokenStorage {
  InMemoryTokenStorage({String? token, String? refreshToken})
      : _token = token,
        _refreshToken = refreshToken;

  String? _token;
  String? _refreshToken;

  @override
  Future<String?> read() async => _token;

  @override
  Future<void> save(String token) async => _token = token;

  @override
  Future<String?> readRefreshToken() async => _refreshToken;

  @override
  Future<void> saveRefreshToken(String token) async => _refreshToken = token;

  @override
  Future<void> clear() async {
    _token = null;
    _refreshToken = null;
  }

  @override
  Future<bool> get hasToken async => _token != null && _token!.isNotEmpty;
}
