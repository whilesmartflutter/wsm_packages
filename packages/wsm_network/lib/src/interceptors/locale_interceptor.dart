import 'package:dio/dio.dart';

/// Returns the language code to send, or null to omit the header.
typedef LocaleSupplier = String? Function();

/// Sets `Accept-Language` from the app's active locale.
///
/// Takes a supplier rather than reading a localization package directly, so
/// the package stays independent of whichever one the app uses
/// (easy_localization, flutter_localizations, …).
class LocaleInterceptor extends Interceptor {
  LocaleInterceptor({
    required this.localeCode,
    this.headerName = 'Accept-Language',
  });

  final LocaleSupplier localeCode;
  final String headerName;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final code = localeCode();
    if (code != null && code.isNotEmpty) {
      options.headers[headerName] = code;
    }
    handler.next(options);
  }
}
