/// Persists auth credentials.
///
/// This package deliberately ships no plugin-backed implementation, so
/// adopting the interceptors never drags a native dependency into an app.
/// Use `wsm_secure_storage`'s `SecureTokenStorage` for the keychain/keystore
/// implementation, or implement this interface over an existing store the
/// app already has.
///
/// Credentials belong in the platform keystore/keychain — do not write a
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
