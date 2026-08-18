import 'package:equatable/equatable.dart';
import 'package:fpdart/fpdart.dart';

import '../error/failures.dart';

/// The state of a user-triggered action (save, delete, submit) — the second
/// axis alongside [AsyncState], which models *loading* data.
///
/// A screen can legitimately be showing loaded data while a save is in
/// flight, so the two must not share one status field. Collapses the
/// `isSaving` / `isDeleting` / `isSubmitting` booleans into one value that
/// cannot represent two actions at once.
sealed class MutationState extends Equatable {
  const MutationState();

  /// No action in flight.
  const factory MutationState.idle() = MutationIdle;

  /// An action is in flight.
  const factory MutationState.inProgress() = MutationInProgress;

  /// The last action succeeded.
  const factory MutationState.success() = MutationSuccess;

  /// The last action failed.
  const factory MutationState.failure(Failure failure) = MutationFailure;

  /// Folds an `Either<Failure, void>` into a terminal state.
  static MutationState fromEither<T>(Either<Failure, T> either) => either.match(
        MutationFailure.new,
        (_) => const MutationSuccess(),
      );

  bool get isIdle => this is MutationIdle;
  bool get isInProgress => this is MutationInProgress;
  bool get isSuccess => this is MutationSuccess;

  Failure? get failureOrNull =>
      this is MutationFailure ? (this as MutationFailure).failure : null;

  @override
  List<Object?> get props => const [];
}

/// No action in flight.
final class MutationIdle extends MutationState {
  const MutationIdle();
}

/// An action is in flight.
final class MutationInProgress extends MutationState {
  const MutationInProgress();
}

/// The last action succeeded.
final class MutationSuccess extends MutationState {
  const MutationSuccess();
}

/// The last action failed.
final class MutationFailure extends MutationState {
  const MutationFailure(this.failure);

  final Failure failure;

  @override
  List<Object?> get props => [failure];
}
