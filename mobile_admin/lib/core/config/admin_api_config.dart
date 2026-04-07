import 'package:flutter/foundation.dart';

class AdminApiConfig {
  static const String _baseUrlOverride = String.fromEnvironment(
    'ADMIN_API_BASE_URL',
  );
  static const String _defineAccessToken = String.fromEnvironment(
    'ADMIN_ACCESS_TOKEN',
  );
  static String? _runtimeAccessToken;

  static String get baseUrl {
    if (_baseUrlOverride.isNotEmpty) {
      return _baseUrlOverride;
    }

    return defaultTargetPlatform == TargetPlatform.android
        ? 'http://10.0.2.2:3000'
        : 'http://localhost:3000';
  }

  static String get accessToken => _runtimeAccessToken ?? _defineAccessToken;

  static bool get hasAccessToken => accessToken.isNotEmpty;

  static void setAccessToken(String? token) {
    _runtimeAccessToken = token?.trim() ?? '';
  }

  static void clearAccessToken() {
    _runtimeAccessToken = '';
  }

  static Uri adminUri(String path, {Map<String, String>? queryParameters}) {
    final sanitizedQuery = <String, String>{};
    queryParameters?.forEach((key, value) {
      if (value.trim().isNotEmpty) {
        sanitizedQuery[key] = value;
      }
    });

    return Uri.parse(
      '$baseUrl$path',
    ).replace(queryParameters: sanitizedQuery.isEmpty ? null : sanitizedQuery);
  }
}
