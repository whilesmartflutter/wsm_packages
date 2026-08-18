import 'dart:io';

import 'package:dio/dio.dart';
import 'package:fpdart/fpdart.dart';

import '../logging/logger.dart';
import 'exceptions.dart';
import 'failures.dart';

/// Stage 2 of the error flow: wraps repository calls and converts the typed
/// [ApiException]s thrown by `ErrorHandler` into `Either<Failure, T>`.
class RepositoryErrorHandler {
  static Future<Either<Failure, T>> handleApiCall<T>(
    Future<T> Function() apiCall,
  ) async {
    try {
      final result = await apiCall();
      return right(result);
    } on UnauthorizedException catch (e) {
      wsmLogger.e('UnauthorizedException', error: e);
      return left(const UnauthorizedFailure());
    } on ValidationException catch (e) {
      return left(ValidationFailure(e.message, errors: e.errors));
    } on FileTooLargeException {
      return left(const FileTooLargeFailure());
    } on BadRequestException catch (e) {
      // Kept from trakli: bad requests surface as ServerFailure, not
      // BadRequestFailure. Changing this is a breaking behavioral change for
      // adopters — do it as a versioned decision, not in passing.
      return left(ServerFailure(e.message));
    } on ServerException catch (e) {
      return left(ServerFailure(e.message));
    } on NetworkException {
      return left(const NetworkFailure());
    } on CancelException {
      return left(const CancelFailure());
    } on UnknownException {
      return left(const UnknownFailure());
    } on DuplicateException catch (e) {
      return left(DuplicateFailure(e.message));
    } on NotFoundException {
      return left(const NotFoundFailure());
    } on DioException catch (e, stackTrace) {
      if (isConnectivityError(e)) {
        return left(const NetworkFailure());
      }
      wsmLogger.e('UnknownFailure', error: e, stackTrace: stackTrace);
      return left(const UnknownFailure());
    } catch (e, stackTrace) {
      wsmLogger.e('UnknownFailure', error: e, stackTrace: stackTrace);
      return left(const UnknownFailure());
    }
  }

  /// True when the request never reached the server (offline, DNS, timeout).
  static bool isConnectivityError(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionError:
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return true;
      case DioExceptionType.unknown:
        return e.error is SocketException;
      // ignore: unreachable_switch_default -- future-proof against new types
      default:
        return false;
    }
  }

  /// Maps a [Failure] back to an [ApiException], for the rare paths that
  /// need to re-throw across a repository boundary.
  static ApiException mapFailureToException(Failure failure) {
    return switch (failure) {
      ServerFailure(:final message) => ServerException(message),
      NetworkFailure() => NetworkException('Network error occurred'),
      CacheFailure(:final message) => ServerException(message),
      SyncFailure(:final message) => ServerException(message),
      ValidationFailure(:final message, :final errors) =>
        ValidationException(message, errors: errors),
      FileTooLargeFailure() => FileTooLargeException('File too large'),
      UnauthorizedFailure() => UnauthorizedException('Unauthorized'),
      UnknownFailure() => UnknownException('Unknown error occurred'),
      BadRequestFailure(:final error) =>
        BadRequestException(error ?? 'Bad request'),
      NoneFailure() => ServerException('No error'),
      NotFoundFailure() => NotFoundException('Resource not found'),
      DuplicateFailure(:final message) => DuplicateException(message),
      CancelFailure() => CancelException('Operation cancelled'),
    };
  }
}
