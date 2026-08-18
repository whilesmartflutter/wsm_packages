import 'package:equatable/equatable.dart';
import 'package:fpdart/fpdart.dart';

import '../error/failures.dart';

/// One-shot use case returning `Either<Failure, T>`.
abstract class UseCase<T, Params> {
  Future<Either<Failure, T>> call(Params params);
}

/// Reactive use case emitting `Either<Failure, T>` values.
abstract class StreamUseCase<T, Params> {
  Stream<Either<Failure, T>> call(Params params);
}

/// Reactive use case for infallible local streams (e.g. watching a local
/// database) where a `Failure` channel would only add noise.
abstract class NoEitherStreamUseCase<T, Params> {
  Stream<T> call(Params params);
}

/// Parameter object for use cases that take no input.
class NoParams extends Equatable {
  const NoParams();

  @override
  List<Object> get props => const [];
}
