import 'dart:developer' as developer;

import 'package:bloc/bloc.dart';
import 'package:flutter/foundation.dart';

import 'crash_reporting_service.dart';

/// [BlocObserver] that forwards every bloc/cubit error to crash reporting.
///
/// Bloc catches exceptions thrown inside handlers and routes them here
/// instead of letting them reach the zone, so without this observer those
/// errors are invisible in production.
///
/// ```dart
/// Bloc.observer = AppBlocObserver(crashReportingService);
/// ```
class AppBlocObserver extends BlocObserver {
  AppBlocObserver(this._crashReporting, {this.logTransitions = kDebugMode});

  final CrashReportingService? _crashReporting;

  /// Log every state change to the developer console. Debug-only by default —
  /// state objects can contain user data.
  final bool logTransitions;

  @override
  void onChange(BlocBase<dynamic> bloc, Change<dynamic> change) {
    super.onChange(bloc, change);
    if (logTransitions) {
      developer.log('${bloc.runtimeType}: $change', name: 'bloc');
    }
  }

  @override
  void onError(BlocBase<dynamic> bloc, Object error, StackTrace stackTrace) {
    _crashReporting?.recordError(
      error,
      stackTrace: stackTrace,
      reason: 'error-in-${bloc.runtimeType}',
    );
    super.onError(bloc, error, stackTrace);
  }
}
