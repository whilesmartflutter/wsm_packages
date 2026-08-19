import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:flutter/foundation.dart';

/// Bridges a [Cubit] into go_router's `refreshListenable` slot so a redirect
/// guard re-runs whenever the cubit emits.
///
/// go_router wants a [Listenable]; a cubit exposes a [Stream]. Without this
/// adapter the router's `redirect` evaluates once and then goes stale — a
/// session can expire and leave the user sitting on a screen they are no
/// longer allowed to see.
///
/// ```dart
/// GoRouter(
///   refreshListenable: CubitListenable(authCubit),
///   redirect: (context, state) { ... },
/// );
/// ```
///
/// Dispose it with the router; it holds a stream subscription.
class CubitListenable<S> extends ChangeNotifier {
  CubitListenable(Cubit<S> cubit) {
    _subscription = cubit.stream.listen((_) => notifyListeners());
  }

  late final StreamSubscription<S> _subscription;

  @override
  void dispose() {
    unawaited(_subscription.cancel());
    super.dispose();
  }
}
