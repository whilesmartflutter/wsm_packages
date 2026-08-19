/// WhileSmart mobile shared Bloc glue.
///
/// Deliberately separate from `wsm_core`, which is pure Dart and has no
/// Flutter dependency — these helpers need `ChangeNotifier` and `Cubit`.
library;

export 'src/cubit_listenable.dart';
export 'src/safe_cubit.dart';
