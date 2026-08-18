import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wsm_secure_storage/wsm_secure_storage.dart';

/// In-memory stand-in so the key-naming contract can be asserted without a
/// platform channel.
class _FakeSecureStorage extends FlutterSecureStorage {
  const _FakeSecureStorage(this.values);

  final Map<String, String> values;

  @override
  Future<String?> read({
    required String key,
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    AppleOptions? mOptions,
    WindowsOptions? wOptions,
  }) async =>
      values[key];

  @override
  Future<void> write({
    required String key,
    required String? value,
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    AppleOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    if (value == null) {
      values.remove(key);
    } else {
      values[key] = value;
    }
  }

  @override
  Future<void> delete({
    required String key,
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    AppleOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    values.remove(key);
  }
}

void main() {
  late Map<String, String> values;
  late SecureTokenStorage storage;

  setUp(() {
    values = <String, String>{};
    storage = SecureTokenStorage(
      keyPrefix: 'desk',
      storage: _FakeSecureStorage(values),
    );
  });

  test('namespaces keys by prefix so apps do not collide', () async {
    await storage.save('a');
    await storage.saveRefreshToken('r');

    expect(
        values.keys, containsAll(['desk_access_token', 'desk_refresh_token']));
  });

  test('two apps on one device keep separate tokens', () async {
    final pay = SecureTokenStorage(
      keyPrefix: 'pay',
      storage: _FakeSecureStorage(values),
    );

    await storage.save('desk-token');
    await pay.save('pay-token');

    expect(await storage.read(), 'desk-token');
    expect(await pay.read(), 'pay-token');
  });

  test('round-trips and clears both tokens', () async {
    expect(await storage.hasToken, isFalse);

    await storage.save('a');
    await storage.saveRefreshToken('r');

    expect(await storage.read(), 'a');
    expect(await storage.readRefreshToken(), 'r');
    expect(await storage.hasToken, isTrue);

    await storage.clear();

    expect(await storage.read(), isNull);
    expect(await storage.readRefreshToken(), isNull);
    expect(await storage.hasToken, isFalse);
  });

  test('an empty stored token does not count as signed in', () async {
    await storage.save('');

    expect(await storage.hasToken, isFalse);
  });
}
