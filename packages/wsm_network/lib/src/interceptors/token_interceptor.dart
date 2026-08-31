import 'dart:async';

import 'package:dio/dio.dart';

/// Supplies the current auth token, or null when signed out.
typedef TokenSupplier = FutureOr<String?> Function();

typedef TokenRefresher = Future<String?> Function();

/// Called when an authenticated request comes back 401.
typedef UnauthorizedCallback = FutureOr<void> Function();

/// Attaches the bearer token to outbound requests and reports genuine
/// authentication failures through [onUnauthorized].
///
/// The 401 handling is deliberately narrow: a 401 from the login or
/// password-reset endpoints means "wrong credentials", not "session expired",
/// so those must not sign the user out. Only requests that actually carried a
/// token trigger the callback.
class TokenInterceptor extends Interceptor {
  TokenInterceptor({
    required this.getToken,
    this.refreshToken,
    this.retryClient,
    this.onUnauthorized,
    this.isAuthEndpoint = defaultIsAuthEndpoint,
    this.headerName = 'Authorization',
    this.scheme = 'Bearer',
  });

  final TokenSupplier getToken;
  final TokenRefresher? refreshToken;
  final Dio? retryClient;

  /// Invoked once per 401 on an authenticated, non-auth-endpoint request.
  /// Wire this to the app's sign-out so the UI reacts immediately instead of
  /// silently holding a dead token until the next restart.
  final UnauthorizedCallback? onUnauthorized;

  /// Identifies endpoints where a 401 is an expected credential rejection.
  final bool Function(String path) isAuthEndpoint;

  final String headerName;
  final String scheme;
  Future<String?>? _refreshing;

  static const _retriedKey = 'wsm_network.auth_retried';
  static const _unauthorizedHandledKey = 'wsm_network.unauthorized_handled';

  static final RegExp _authEndpoints = RegExp(
    r'(^|/)(login|register|sign-?in|sign-?up|password-reset|forgot-password|otp|verify|refresh)(/|$)',
  );

  /// Matches the auth endpoints shared by the WhileSmart backends.
  static bool defaultIsAuthEndpoint(String path) =>
      _authEndpoints.hasMatch(path.toLowerCase());

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    if (!options.headers.containsKey(headerName)) {
      final token = await getToken();
      if (token != null && token.isNotEmpty) {
        options.headers[headerName] = '$scheme $token';
      }
    }
    handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final wasAuthenticated = err.requestOptions.headers.containsKey(headerName);
    if (err.response?.statusCode == 401 &&
        wasAuthenticated &&
        !isAuthEndpoint(err.requestOptions.path)) {
      final refreshed = await _refresh(err.requestOptions);
      if (refreshed != null) {
        handler.resolve(refreshed);
        return;
      }
      if (err.requestOptions.extra[_unauthorizedHandledKey] != true) {
        err.requestOptions.extra[_unauthorizedHandledKey] = true;
        await onUnauthorized?.call();
      }
    }
    handler.next(err);
  }

  Future<Response<dynamic>?> _refresh(RequestOptions request) async {
    if (refreshToken == null ||
        retryClient == null ||
        request.extra[_retriedKey] == true) {
      return null;
    }

    try {
      final requestToken = request.headers[headerName];
      var token = await getToken();
      if ('$scheme $token' == requestToken) {
        final refresh = _refreshing ??= refreshToken!();
        try {
          token = await refresh;
        } finally {
          if (identical(_refreshing, refresh)) _refreshing = null;
        }
      }
      if (token == null || token.isEmpty) return null;

      request
        ..headers[headerName] = '$scheme $token'
        ..extra[_retriedKey] = true;
      return retryClient!.fetch<dynamic>(request);
    } on Object {
      return null;
    }
  }
}
