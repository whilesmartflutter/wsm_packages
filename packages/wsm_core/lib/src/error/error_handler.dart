import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';

import '../logging/logger.dart';
import 'exceptions.dart';
import 'field_error.dart';

/// Signature for reporting a non-fatal error to a crash reporter.
/// Matches `wsm_crash`'s `CrashReportingService.recordError`.
typedef RecordError = Future<void> Function(
  Object error, {
  StackTrace? stackTrace,
  String? reason,
  Map<String, dynamic>? information,
});

/// Signature for reporting an API error to a crash reporter.
/// Matches `wsm_crash`'s `CrashReportingService.recordApiError`.
typedef RecordApiError = Future<void> Function(
  String endpoint,
  int? statusCode,
  String message, {
  Map<String, dynamic>? requestData,
  Map<String, dynamic>? responseData,
});

/// Stage 1 of the error flow: wraps datasource calls and converts raw
/// [DioException]s (and anything else thrown) into typed [ApiException]s.
class ErrorHandler {
  static RecordError? _recordError;
  static RecordApiError? _recordApiError;

  /// Optionally wire in a crash reporter. Tear-offs from `wsm_crash`'s
  /// `CrashReportingService` fit both parameters:
  ///
  /// ```dart
  /// ErrorHandler.setReporter(
  ///   recordError: crashReportingService.recordError,
  ///   recordApiError: crashReportingService.recordApiError,
  /// );
  /// ```
  static void setReporter({
    RecordError? recordError,
    RecordApiError? recordApiError,
  }) {
    _recordError = recordError;
    _recordApiError = recordApiError;
  }

  static Future<T> handleApiCall<T>(Future<T> Function() apiCall) async {
    try {
      return await apiCall();
    } on DioException catch (err) {
      throw handleDioException(err);
    } catch (error, stacktrace) {
      throw handleUnknownException(error, stacktrace);
    }
  }

  static ApiException handleDioException(DioException err) {
    if (err.type == DioExceptionType.cancel) {
      return CancelException('Request cancelled');
    }

    if (err.type == DioExceptionType.connectionError) {
      return NetworkException('No internet connection');
    }

    if (err.type == DioExceptionType.unknown) {
      _reportApiError(err);
      return UnknownException('Unknown error');
    }

    final statusCode = err.response?.statusCode;
    final data = decodeBody(err.response?.data);
    final message = data is Map
        ? (data['message'] as String?) ?? 'Unknown error'
        : 'Unknown error';

    switch (statusCode) {
      case 400:
        return BadRequestException(message, statusCode: statusCode, data: data);
      case 401:
        return UnauthorizedException(
          message,
          statusCode: statusCode,
          data: data,
        );
      case 403:
        return ForbiddenException(message, statusCode: statusCode, data: data);
      case 404:
        return NotFoundException(message, statusCode: statusCode, data: data);
      case 409:
        return DuplicateException(message, statusCode: statusCode, data: data);
      case 413:
        return FileTooLargeException(
          message,
          statusCode: statusCode,
          data: data,
        );
      case 422:
        return ValidationException(message, errors: FieldError.getErrors(data));
      case 500:
        _reportApiError(err);
        wsmLogger.e('Server error on ${err.requestOptions.uri.path}');
        return ServerException(
          'Internal server error',
          statusCode: statusCode,
          data: data,
        );
      default:
        _reportApiError(err);
        if (err.type == DioExceptionType.badResponse) {
          return BadRequestException(
            message,
            statusCode: statusCode,
            data: data,
          );
        }
        return ServerException(message, statusCode: statusCode, data: data);
    }
  }

  static ApiException handleUnknownException(
    Object error,
    StackTrace stacktrace,
  ) {
    if (error is PathNotFoundException || error is FileSystemException) {
      wsmLogger.w('Local file error: $error');
      return LocalFileException(error.toString());
    }

    wsmLogger.e('Unknown error', error: error, stackTrace: stacktrace);
    _recordError?.call(error, stackTrace: stacktrace, reason: 'Unknown Error');
    return UnknownException(error.toString());
  }

  /// A failed file download still carries a JSON body, but it arrives as
  /// bytes because the request asked for bytes. Decode it so the server's
  /// message is not lost behind a generic error.
  static dynamic decodeBody(dynamic data) {
    if (data is! List<int>) return data;
    try {
      return jsonDecode(utf8.decode(data));
    } catch (_) {
      return null;
    }
  }

  static void _reportApiError(DioException err) {
    final recordApiError = _recordApiError;
    if (recordApiError == null) return;

    recordApiError(
      err.requestOptions.path,
      err.response?.statusCode,
      err.message ?? 'Unknown error',
      requestData: _asMap(err.requestOptions.data),
      responseData: _asMap(err.response?.data),
    );
  }

  static Map<String, dynamic>? _asMap(dynamic data) {
    if (data == null) return null;
    if (data is Map<String, dynamic>) return data;
    if (data is Map) return Map<String, dynamic>.from(data);
    return {'data': data};
  }
}
