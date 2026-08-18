import 'package:equatable/equatable.dart';
import 'package:fpdart/fpdart.dart';

import '../error/failures.dart';

/// The state of a piece of asynchronously loaded data: exactly one of
/// *not started*, *loading*, *loaded* or *failed*.
///
/// Replaces the `isLoading` / `data` / `failure` field triplets that let
/// contradictory states be represented (loading *and* failed, empty list
/// that might be "no results" or "not fetched yet"). Because the type is
/// `sealed`, a `switch` over it is exhaustive and the analyzer flags any
/// screen that forgets a case.
///
/// [AsyncLoading] and [AsyncFailure] carry an optional [previous] value so a
/// refresh can keep showing the last good data instead of flashing a spinner
/// over an empty screen.
///
/// ```dart
/// switch (state.categories) {
///   AsyncInitial() || AsyncLoading(previous: null) => const Skeleton(),
///   AsyncFailure(:final failure, previous: null) => ErrorView(failure),
///   AsyncLoading(:final previous?) => CategoryList(previous, refreshing: true),
///   AsyncFailure(:final previous?) => CategoryList(previous, stale: true),
///   AsyncData(:final value) => CategoryList(value),
/// }
/// ```
///
/// This models *loading* a value. Actions the user triggers on it
/// (saving, deleting) are a separate axis — use [MutationState] for those.
sealed class AsyncState<T> extends Equatable {
  const AsyncState();

  /// Nothing has been requested yet.
  const factory AsyncState.initial() = AsyncInitial<T>;

  /// A load is in flight. [previous] is the last known value, if any.
  const factory AsyncState.loading({T? previous}) = AsyncLoading<T>;

  /// A value is available.
  const factory AsyncState.data(T value) = AsyncData<T>;

  /// The load failed. [previous] is the last known value, if any.
  const factory AsyncState.failure(Failure failure, {T? previous}) =
      AsyncFailure<T>;

  /// Folds an `Either<Failure, T>` — as returned by a `UseCase` — into a
  /// terminal state, carrying [previous] into the failure case.
  factory AsyncState.fromEither(Either<Failure, T> either, {T? previous}) {
    return either.match(
      (failure) => AsyncFailure<T>(failure, previous: previous),
      AsyncData<T>.new,
    );
  }

  /// The last known value: the loaded value, or the one carried through a
  /// reload or failure. Null only when no value has ever been loaded.
  T? get valueOrNull => switch (this) {
        AsyncData<T>(:final value) => value,
        AsyncLoading<T>(:final previous) => previous,
        AsyncFailure<T>(:final previous) => previous,
        AsyncInitial<T>() => null,
      };

  /// The failure, if this state is [AsyncFailure].
  Failure? get failureOrNull =>
      this is AsyncFailure<T> ? (this as AsyncFailure<T>).failure : null;

  bool get isInitial => this is AsyncInitial<T>;
  bool get isLoading => this is AsyncLoading<T>;
  bool get hasValue => valueOrNull != null;
  bool get hasFailure => this is AsyncFailure<T>;

  /// A loading state that preserves whatever value this state already holds.
  AsyncState<T> toLoading() => AsyncLoading<T>(previous: valueOrNull);

  /// A failure state that preserves whatever value this state already holds.
  AsyncState<T> toFailure(Failure failure) =>
      AsyncFailure<T>(failure, previous: valueOrNull);

  /// Transforms the contained value, preserving the case.
  AsyncState<R> mapValue<R>(R Function(T value) transform) => switch (this) {
        AsyncInitial<T>() => AsyncInitial<R>(),
        AsyncLoading<T>(:final previous) => AsyncLoading<R>(
            previous: previous == null ? null : transform(previous),
          ),
        AsyncData<T>(:final value) => AsyncData<R>(transform(value)),
        AsyncFailure<T>(:final failure, :final previous) => AsyncFailure<R>(
            failure,
            previous: previous == null ? null : transform(previous),
          ),
      };
}

/// Nothing has been requested yet.
final class AsyncInitial<T> extends AsyncState<T> {
  const AsyncInitial();

  @override
  List<Object?> get props => const [];
}

/// A load is in flight.
final class AsyncLoading<T> extends AsyncState<T> {
  const AsyncLoading({this.previous});

  /// The last known value, kept so the UI can show stale data while
  /// refreshing.
  final T? previous;

  @override
  List<Object?> get props => [previous];
}

/// A value is available.
final class AsyncData<T> extends AsyncState<T> {
  const AsyncData(this.value);

  final T value;

  @override
  List<Object?> get props => [value];
}

/// The load failed.
final class AsyncFailure<T> extends AsyncState<T> {
  const AsyncFailure(this.failure, {this.previous});

  final Failure failure;

  /// The last known value, kept so the UI can show stale data alongside the
  /// error instead of blanking the screen.
  final T? previous;

  @override
  List<Object?> get props => [failure, previous];
}
