# wsm_bloc

Shared Bloc glue for WhileSmart mobile apps.

Separate from [`wsm_core`](../wsm_core) because that package is pure Dart with
no Flutter dependency — these helpers need `ChangeNotifier` and `Cubit`.

## `CubitListenable`

Bridges a `Cubit` into go_router's `refreshListenable` slot, so the redirect
guard re-runs when auth state changes. go_router wants a `Listenable`; a cubit
exposes a `Stream`.

```dart
GoRouter(
  refreshListenable: CubitListenable(authCubit),
  redirect: (context, state) => ...,
);
```

Without it the guard evaluates once and goes stale — a session expires and the
user stays on a screen they should have been redirected off.

## `SafeCubit`

A `Cubit` whose `emit` is a no-op after `close()`, instead of throwing a
`StateError`. The failure it prevents is ordinary: an in-flight request
completes after the screen holding the cubit was popped.

```dart
class MailCubit extends SafeCubit<MailState> { ... }
```

Guarding every call site by hand does not scale — trakli has several hundred
unguarded emits. It is a safety net, not a licence to skip lifecycle work:
cancel subscriptions and timers in `close()` as usual.
