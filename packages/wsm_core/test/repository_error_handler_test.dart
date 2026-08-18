import 'dart:io';

import 'package:dio/dio.dart';
import 'package:test/test.dart';
import 'package:wsm_core/wsm_core.dart';

void main() {
  group('RepositoryErrorHandler.handleApiCall', () {
    test('returns Right on success', () async {
      final result = await RepositoryErrorHandler.handleApiCall(() async => 1);
      expect(result.isRight(), isTrue);
    });

    test('UnauthorizedException -> UnauthorizedFailure', () async {
      final result = await RepositoryErrorHandler.handleApiCall<void>(
        () => throw UnauthorizedException('nope'),
      );
      expect(result.getLeft().toNullable(), const UnauthorizedFailure());
    });

    test('ValidationException keeps message and errors', () async {
      final result = await RepositoryErrorHandler.handleApiCall<void>(
        () => throw ValidationException(
          'invalid',
          errors: const [
            FieldError(field: 'email', messages: ['taken']),
          ],
        ),
      );
      final failure = result.getLeft().toNullable();
      expect(failure, isA<ValidationFailure>());
      expect((failure! as ValidationFailure).errors.single.field, 'email');
    });

    test('connectivity DioException -> NetworkFailure', () async {
      final result = await RepositoryErrorHandler.handleApiCall<void>(
        () => throw DioException(
          requestOptions: RequestOptions(path: '/x'),
          type: DioExceptionType.connectionTimeout,
        ),
      );
      expect(result.getLeft().toNullable(), const NetworkFailure());
    });

    test('anything else -> UnknownFailure', () async {
      final result = await RepositoryErrorHandler.handleApiCall<void>(
        () => throw StateError('boom'),
      );
      expect(result.getLeft().toNullable(), const UnknownFailure());
    });
  });

  group('isConnectivityError', () {
    test('true for timeouts and connection errors', () {
      for (final type in [
        DioExceptionType.connectionError,
        DioExceptionType.connectionTimeout,
        DioExceptionType.sendTimeout,
        DioExceptionType.receiveTimeout,
      ]) {
        final e = DioException(
          requestOptions: RequestOptions(path: '/x'),
          type: type,
        );
        expect(RepositoryErrorHandler.isConnectivityError(e), isTrue);
      }
    });

    test('true for unknown wrapping a SocketException', () {
      final e = DioException(
        requestOptions: RequestOptions(path: '/x'),
        error: const SocketException('down'),
      );
      expect(RepositoryErrorHandler.isConnectivityError(e), isTrue);
    });

    test('false for bad responses', () {
      final e = DioException(
        requestOptions: RequestOptions(path: '/x'),
        type: DioExceptionType.badResponse,
      );
      expect(RepositoryErrorHandler.isConnectivityError(e), isFalse);
    });
  });

  group('mapFailureToException', () {
    test('is exhaustive over every failure variant', () {
      const failures = <Failure>[
        Failure.serverError('m'),
        Failure.networkError(),
        Failure.cacheError('m'),
        Failure.syncError('m'),
        Failure.validationError('m', errors: []),
        Failure.fileTooLarge(),
        Failure.unauthorizedError(),
        Failure.unknownError(),
        Failure.badRequest(error: 'm'),
        Failure.none(),
        Failure.notFound(),
        Failure.duplicate('m'),
        Failure.cancel(),
      ];
      for (final failure in failures) {
        expect(
          RepositoryErrorHandler.mapFailureToException(failure),
          isA<ApiException>(),
        );
      }
    });
  });
}
