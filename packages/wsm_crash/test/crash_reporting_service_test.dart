import 'package:flutter_test/flutter_test.dart';
import 'package:wsm_crash/wsm_crash.dart';

class _FakeReporter implements CrashReportingInterface {
  final List<String> calls = <String>[];
  final Map<String, Object?> keys = <String, Object?>{};
  bool throwOnEverything = false;

  void _record(String call) {
    calls.add(call);
    if (throwOnEverything) throw StateError('backend down');
  }

  @override
  Future<void> initialize() async => _record('initialize');

  @override
  Future<void> recordError(
    Object error, {
    StackTrace? stackTrace,
    String? reason,
    Map<String, dynamic>? information,
  }) async =>
      _record('recordError:$error:$reason');

  @override
  Future<void> recordFatalError(
    Object error, {
    StackTrace? stackTrace,
    String? reason,
    Map<String, dynamic>? information,
  }) async =>
      _record('recordFatalError:$error');

  @override
  Future<void> setCustomKey(String key, Object? value) async {
    _record('setCustomKey:$key');
    keys[key] = value;
  }

  @override
  Future<void> setUserId(String userId) async => _record('setUserId:$userId');

  @override
  Future<void> log(String message, {String? level}) async =>
      _record('log:$message');
}

void main() {
  group('CrashReportingService personal-data guard', () {
    test('identifies personal-data keys', () {
      for (final key in [
        'email',
        'e-mail',
        'userEmail',
        'phone',
        'phone_number',
        'first_name',
        'lastName',
        'username',
        'address',
        'card_number',
        'national_id',
      ]) {
        expect(
          CrashReportingService.isPersonalDataKey(key),
          isTrue,
          reason: key,
        );
      }

      for (final key in [
        'user_id',
        'plan',
        'flavor',
        'screen',
        'build',
        'card_type',
      ]) {
        expect(
          CrashReportingService.isPersonalDataKey(key),
          isFalse,
          reason: key,
        );
      }
    });

    test('drops personal-data custom keys instead of forwarding them',
        () async {
      final reporter = _FakeReporter();
      final service = CrashReportingService(reporter);

      await service.setCustomKey('email', 'a@b.com');
      await service.setUserProperties(<String, Object?>{
        'phone_number': '+237600000000',
        'plan': 'pro',
      });

      expect(reporter.keys.containsKey('email'), isFalse);
      expect(reporter.keys.containsKey('phone_number'), isFalse);
      expect(reporter.keys['plan'], 'pro');
    });

    test('forwards non-personal custom keys', () async {
      final reporter = _FakeReporter();
      final service = CrashReportingService(reporter);

      await service.setCustomKey('plan', 'pro');

      expect(reporter.keys['plan'], 'pro');
    });

    test('setUserId is allowed through — ids are opaque', () async {
      final reporter = _FakeReporter();
      final service = CrashReportingService(reporter);

      await service.setUserId('usr_9f2c');

      expect(reporter.calls, contains('setUserId:usr_9f2c'));
    });
  });

  group('CrashReportingService robustness', () {
    test('a failing backend never throws at the call site', () async {
      final reporter = _FakeReporter()..throwOnEverything = true;
      final service = CrashReportingService(reporter);

      await service.initialize();
      await service.recordError(Exception('boom'));
      await service.recordFatalError(Exception('boom'));
      await service.log('hello');

      expect(reporter.calls, hasLength(4));
    });

    test('recordApiError includes endpoint and status in the reason', () async {
      final reporter = _FakeReporter();
      final service = CrashReportingService(reporter);

      await service.recordApiError('/mail/1', 500, 'server exploded');

      expect(
        reporter.calls.single,
        contains('HTTP 500 on /mail/1'),
      );
    });
  });
}
