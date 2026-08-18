import 'dart:async';

import 'package:dio/dio.dart';

/// Supplies the current auth token, or null when signed out.
typedef TokenSupplier = FutureOr<String?> Function();

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
    this.onUnauthorized,
    this.isAuthEndpoint = defaultIsAuthEndpoint,
    this.headerName = 'Authorization',
    this.scheme = 'Bearer',
  });

  final TokenSupplier getToken;

  /// Invoked once per 401 on an authenticated, non-auth-endpoint request.
  /// Wire this to the app's sign-out so the UI reacts immediately instead of
  /// silently holding a dead token until the next restart.
  final UnauthorizedCallback? onUnauthorized;

  /// Identifies endpoints where a 401 is an expected credential rejection.
  final bool Function(String path) isAuthEndpoint;

  final String headerName;
  final String scheme;

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
      await onUnauthorized?.call();
    }
    handler.next(err);
  }
}
