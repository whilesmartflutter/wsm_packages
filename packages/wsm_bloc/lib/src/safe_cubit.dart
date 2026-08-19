import 'package:bloc/bloc.dart';
import 'package:meta/meta.dart';

/// A [Cubit] whose [emit] is a no-op once the cubit is closed.
///
/// Emitting after `close()` throws a `StateError`, which is easy to hit: an
/// in-flight request completes after the screen holding the cubit is popped.
/// Guarding every call site by hand does not scale — trakli has several
/// hundred unguarded emits — so the guard lives in the base class instead.
///
/// This is a safety net, not a licence to ignore lifecycles: cancel
/// subscriptions and timers in [close] as usual.
abstract class SafeCubit<S> extends Cubit<S> {
  SafeCubit(super.initialState);

  /// Emits [state] unless this cubit has already been closed.
  @override
  @protected
  void emit(S state) {
    if (isClosed) return;
    super.emit(state);
  }
}
