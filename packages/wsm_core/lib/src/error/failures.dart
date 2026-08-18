import 'package:equatable/equatable.dart';

import 'field_error.dart';

/// Domain-level failure returned by repositories as `Either<Failure, T>`.
///
/// A sealed hierarchy: exhaustively pattern-match with `switch`. The named
/// factory constructors mirror trakli's freezed API so existing call sites
/// (`Failure.serverError(...)`, `const Failure.none()`, …) keep working.
///
/// User-facing messages are deliberately NOT part of this class — map
/// failures to localized strings in the app layer.
sealed class Failure extends Equatable {
  const Failure();

  const factory Failure.serverError(String message) = ServerFailure;
  const factory Failure.networkError() = NetworkFailure;
  const factory Failure.cacheError(String message) = CacheFailure;
  const factory Failure.syncError(String message) = SyncFailure;
  const factory Failure.validationError(
    String message, {
    required List<FieldError> errors,
  }) = ValidationFailure;
  const factory Failure.fileTooLarge() = FileTooLargeFailure;
  const factory Failure.unauthorizedError() = UnauthorizedFailure;
  const factory Failure.unknownError() = UnknownFailure;
  const factory Failure.badRequest({List<FieldError>? errors, String? error}) =
      BadRequestFailure;
  const factory Failure.none() = NoneFailure;
  const factory Failure.notFound() = NotFoundFailure;
  const factory Failure.duplicate(String message) = DuplicateFailure;
  const factory Failure.cancel() = CancelFailure;

  /// True unless this is the [NoneFailure] sentinel.
  bool get hasError => this is! NoneFailure;

  @override
  List<Object?> get props => const [];
}

class ServerFailure extends Failure {
  const ServerFailure(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}

class NetworkFailure extends Failure {
  const NetworkFailure();
}

class CacheFailure extends Failure {
  const CacheFailure(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}

class SyncFailure extends Failure {
  const SyncFailure(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}

class ValidationFailure extends Failure {
  const ValidationFailure(this.message, {required this.errors});

  final String message;
  final List<FieldError> errors;

  @override
  List<Object?> get props => [message, errors];
}

class FileTooLargeFailure extends Failure {
  const FileTooLargeFailure();
}

class UnauthorizedFailure extends Failure {
  const UnauthorizedFailure();
}

class UnknownFailure extends Failure {
  const UnknownFailure();
}

class BadRequestFailure extends Failure {
  const BadRequestFailure({this.errors, this.error});

  final List<FieldError>? errors;
  final String? error;

  @override
  List<Object?> get props => [errors, error];
}

/// Sentinel meaning "no failure", used by bloc states that keep a non-null
/// `Failure` field (`failure: const Failure.none()`).
class NoneFailure extends Failure {
  const NoneFailure();
}

class NotFoundFailure extends Failure {
  const NotFoundFailure();
}

class DuplicateFailure extends Failure {
  const DuplicateFailure(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}

class CancelFailure extends Failure {
  const CancelFailure();
}
