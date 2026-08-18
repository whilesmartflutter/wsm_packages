import 'package:fpdart/fpdart.dart';
import 'package:test/test.dart';
import 'package:wsm_core/wsm_core.dart';

void main() {
  group('AsyncState', () {
    test('initial holds no value and no failure', () {
      const state = AsyncState<int>.initial();

      expect(state.isInitial, isTrue);
      expect(state.valueOrNull, isNull);
      expect(state.failureOrNull, isNull);
      expect(state.hasValue, isFalse);
    });

    test('data exposes its value', () {
      const state = AsyncState.data(42);

      expect(state.valueOrNull, 42);
      expect(state.hasValue, isTrue);
      expect(state.isLoading, isFalse);
    });

    test('loading carries the previous value through a refresh', () {
      const loaded = AsyncState.data([1, 2, 3]);
      final refreshing = loaded.toLoading();

      expect(refreshing.isLoading, isTrue);
      expect(refreshing.valueOrNull, [1, 2, 3]);
    });

    test('failure carries the previous value so stale data stays visible', () {
      const loaded = AsyncState.data([1, 2, 3]);
      final failed = loaded.toFailure(const Failure.networkError());

      expect(failed.hasFailure, isTrue);
      expect(failed.failureOrNull, const Failure.networkError());
      expect(failed.valueOrNull, [1, 2, 3]);
    });

    test('toLoading from initial keeps previous null', () {
      const state = AsyncState<int>.initial();

      expect(state.toLoading().valueOrNull, isNull);
    });

    test('fromEither maps right to data', () {
      final state = AsyncState<int>.fromEither(const Right(7));

      expect(state, const AsyncData(7));
    });

    test('fromEither maps left to failure and keeps previous', () {
      final state = AsyncState<int>.fromEither(
        const Left(Failure.notFound()),
        previous: 3,
      );

      expect(state, const AsyncFailure(Failure.notFound(), previous: 3));
      expect(state.valueOrNull, 3);
    });

    test('mapValue transforms the value and preserves the case', () {
      expect(
        const AsyncState.data(2).mapValue((v) => v * 2),
        const AsyncData(4),
      );
      expect(
        const AsyncState.loading(previous: 2).mapValue((v) => v * 2),
        const AsyncLoading(previous: 4),
      );
      expect(
        const AsyncState<int>.initial().mapValue((v) => v * 2),
        const AsyncInitial<int>(),
      );
      expect(
        const AsyncState.failure(Failure.none(), previous: 2)
            .mapValue((v) => v * 2),
        const AsyncFailure(Failure.none(), previous: 4),
      );
    });

    test('states with equal contents are equal', () {
      expect(const AsyncData(1), const AsyncData(1));
      expect(const AsyncData(1), isNot(const AsyncData(2)));
      expect(
        const AsyncLoading<int>(previous: 1),
        const AsyncLoading<int>(previous: 1),
      );
      expect(const AsyncInitial<int>(), const AsyncInitial<int>());
    });

    test('switch over the sealed type is exhaustive', () {
      String describe(AsyncState<int> state) => switch (state) {
            AsyncInitial<int>() => 'initial',
            AsyncLoading<int>() => 'loading',
            AsyncData<int>(:final value) => 'data:$value',
            AsyncFailure<int>() => 'failure',
          };

      expect(describe(const AsyncState.data(1)), 'data:1');
      expect(describe(const AsyncState<int>.initial()), 'initial');
    });
  });

  group('MutationState', () {
    test('idle is the resting state', () {
      const state = MutationState.idle();

      expect(state.isIdle, isTrue);
      expect(state.isInProgress, isFalse);
      expect(state.failureOrNull, isNull);
    });

    test('fromEither maps right to success and left to failure', () {
      expect(
        MutationState.fromEither(const Right<Failure, int>(1)),
        const MutationSuccess(),
      );
      expect(
        MutationState.fromEither(const Left<Failure, int>(Failure.cancel())),
        const MutationFailure(Failure.cancel()),
      );
    });

    test('failure exposes its failure', () {
      const state = MutationState.failure(Failure.unauthorizedError());

      expect(state.failureOrNull, const Failure.unauthorizedError());
    });
  });
}
