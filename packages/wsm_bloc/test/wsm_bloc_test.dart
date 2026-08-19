import 'package:bloc/bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wsm_bloc/wsm_bloc.dart';

class _CounterCubit extends SafeCubit<int> {
  _CounterCubit() : super(0);

  void increment() => emit(state + 1);
}

class _PlainCubit extends Cubit<int> {
  _PlainCubit() : super(0);

  void increment() => emit(state + 1);
}

void main() {
  group('SafeCubit', () {
    test('emits normally while open', () {
      final cubit = _CounterCubit()
        ..increment()
        ..increment();

      expect(cubit.state, 2);
    });

    test('ignores emits after close instead of throwing', () async {
      final cubit = _CounterCubit();
      await cubit.close();

      expect(cubit.increment, returnsNormally);
      expect(cubit.state, 0);
    });

    test('a plain Cubit throws in the same situation', () async {
      final cubit = _PlainCubit();
      await cubit.close();

      expect(cubit.increment, throwsStateError);
    });
  });

  group('CubitListenable', () {
    test('notifies listeners on every emit', () async {
      final cubit = _CounterCubit();
      final listenable = CubitListenable<int>(cubit);
      var notifications = 0;
      listenable.addListener(() => notifications++);

      cubit
        ..increment()
        ..increment();
      await Future<void>.delayed(Duration.zero);

      expect(notifications, 2);

      listenable.dispose();
      await cubit.close();
    });

    test('stops notifying once disposed', () async {
      final cubit = _CounterCubit();
      final listenable = CubitListenable<int>(cubit);
      var notifications = 0;
      listenable.addListener(() => notifications++);

      cubit.increment();
      await Future<void>.delayed(Duration.zero);
      expect(notifications, 1);

      listenable.dispose();
      cubit.increment();
      await Future<void>.delayed(Duration.zero);

      expect(notifications, 1, reason: 'subscription must be cancelled');
      await cubit.close();
    });
  });
}
