import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:test/test.dart';
import 'package:wsm_core/wsm_core.dart';

DioException _dioError({
  DioExceptionType type = DioExceptionType.badResponse,
  int? status,
  dynamic body,
  String path = '/things',
}) {
  final options = RequestOptions(path: path);
  return DioException(
    requestOptions: options,
    type: type,
    response: status == null
        ? null
        : Response(requestOptions: options, statusCode: status, data: body),
  );
}

void main() {
  tearDown(() => ErrorHandler.setReporter());

  group('handleDioException', () {
    test('connection error -> NetworkException', () {
      final ex = ErrorHandler.handleDioException(
        _dioError(type: DioExceptionType.connectionError),
      );
      expect(ex, isA<NetworkException>());
    });

    test('cancel -> CancelException', () {
      final ex = ErrorHandler.handleDioException(
        _dioError(type: DioExceptionType.cancel),
      );
      expect(ex, isA<CancelException>());
    });

    test('401 -> UnauthorizedException with server message', () {
      final ex = ErrorHandler.handleDioException(
        _dioError(status: 401, body: {'message': 'Invalid credentials'}),
      );
      expect(ex, isA<UnauthorizedException>());
      expect(ex.message, 'Invalid credentials');
      expect(ex.statusCode, 401);
    });

    test('422 -> ValidationException with parsed field errors', () {
      final ex = ErrorHandler.handleDioException(
        _dioError(
          status: 422,
          body: {
            'message': 'Validation failed',
            'errors': {
              'amount': ['must be positive'],
            },
          },
        ),
      );
      expect(ex, isA<ValidationException>());
      expect((ex as ValidationException).errors.single.field, 'amount');
    });

    test('500 -> ServerException', () {
      final ex = ErrorHandler.handleDioException(
        _dioError(status: 500, body: {'message': 'oops'}),
      );
      expect(ex, isA<ServerException>());
    });

    test('409 -> DuplicateException', () {
      final ex = ErrorHandler.handleDioException(
        _dioError(status: 409, body: {'message': 'exists'}),
      );
      expect(ex, isA<DuplicateException>());
    });

    test('byte-array body is decoded (failed file download)', () {
      final bytes = utf8.encode(jsonEncode({'message': 'Not found'}));
      final ex = ErrorHandler.handleDioException(
        _dioError(status: 404, body: bytes),
      );
      expect(ex, isA<NotFoundException>());
      expect(ex.message, 'Not found');
    });

    group('server message', () {
      test('is read from `error` when the body has no `message`', () {
        final ex = ErrorHandler.handleDioException(
          _dioError(
            status: 422,
            body: {
              'code': 'mailbox_required',
              'error': 'A sending mailbox is required.',
              'setup_required': true,
            },
          ),
        );
        expect(ex, isA<ValidationException>());
        expect(ex.message, 'A sending mailbox is required.');
      });

      test('prefers `message` when both are present', () {
        final ex = ErrorHandler.handleDioException(
          _dioError(
            status: 400,
            body: {'message': 'From message', 'error': 'From error'},
          ),
        );
        expect(ex.message, 'From message');
      });

      test('skips a `message` that is not text', () {
        final ex = ErrorHandler.handleDioException(
          _dioError(
            status: 409,
            body: {
              'message': {'nested': true},
              'error': 'Already taken',
            },
          ),
        );
        expect(ex, isA<DuplicateException>());
        expect(ex.message, 'Already taken');
      });

      test('falls back when neither is usable', () {
        for (final body in [
          {'error': ''},
          {'error': 42},
          {'errors': <String, dynamic>{}},
          'not a map',
          null,
        ]) {
          final ex = ErrorHandler.handleDioException(
            _dioError(status: 400, body: body),
          );
          expect(ex.message, 'Unknown error', reason: 'body: $body');
        }
      });
    });
  });

  group('handleApiCall', () {
    test('passes through the result on success', () async {
      final result = await ErrorHandler.handleApiCall(() async => 42);
      expect(result, 42);
    });

    test('throws typed exception on DioException', () {
      expect(
        () => ErrorHandler.handleApiCall<void>(
          () => throw _dioError(status: 403, body: {'message': 'no'}),
        ),
        throwsA(isA<ForbiddenException>()),
      );
    });

    test('unknown errors are reported via setReporter', () async {
      Object? reported;
      ErrorHandler.setReporter(
        recordError: (
          error, {
          stackTrace,
          reason,
          information,
        }) async {
          reported = error;
        },
      );

      await expectLater(
        () => ErrorHandler.handleApiCall<void>(() => throw StateError('boom')),
        throwsA(isA<UnknownException>()),
      );
      expect(reported, isA<StateError>());
    });
  });
}
