import 'package:flutter/foundation.dart';

class ApiConfig {
  static const String _ngrokApi = 'https://pointed-bring-dried.ngrok-free.dev';

  static String get baseUrl {
    const envValue = String.fromEnvironment('API_BASE_URL', defaultValue: '');
    if (envValue.isNotEmpty) return envValue;

    if (kIsWeb) {
      final hostname = Uri.base.host;
      if (hostname == 'localhost' ||
          hostname == '127.0.0.1' ||
          hostname == '::1') {
        return _ngrokApi;
      }

      return Uri.base.origin;
    }

    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return _ngrokApi;
      case TargetPlatform.iOS:
        return _ngrokApi;
      case TargetPlatform.fuchsia:
      case TargetPlatform.linux:
      case TargetPlatform.macOS:
      case TargetPlatform.windows:
        return _ngrokApi;
    }
  }

  static const int requestTimeoutSeconds = int.fromEnvironment(
    'API_TIMEOUT_SECONDS',
    defaultValue: 15,
  );

  static String get aiBaseUrl {
    const envValue = String.fromEnvironment('AI_BASE_URL', defaultValue: '');
    if (envValue.isNotEmpty) return envValue;

    if (kIsWeb) {
      final hostname = Uri.base.host;
      if (hostname == '10.0.2.2') return 'http://10.0.2.2:8000';
      if (hostname == 'localhost' ||
          hostname == '127.0.0.1' ||
          hostname == '::1') {
        return 'http://localhost:8000';
      }

      return Uri.base.origin;
    }

    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return 'http://192.168.1.24:8000';
      case TargetPlatform.iOS:
        return 'http://192.168.1.24:8000';
      case TargetPlatform.fuchsia:
      case TargetPlatform.linux:
      case TargetPlatform.macOS:
      case TargetPlatform.windows:
        return 'http://localhost:8000';
    }
  }

  static const String aiSuggest = '/ai/suggest';
  static const String aiPriceScrape = '/price/scrape';
  static Duration get requestTimeout =>
      Duration(seconds: requestTimeoutSeconds);

  static String get normalizedBaseUrl => _trimTrailingSlash(baseUrl);

  static String _trimTrailingSlash(String value) {
    if (value.endsWith('/')) return value.substring(0, value.length - 1);
    return value;
  }
}
