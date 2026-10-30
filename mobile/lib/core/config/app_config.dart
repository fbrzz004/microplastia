import 'package:flutter/foundation.dart';

class AppConfig {
  /// Permite definir la URL del backend al compilar/ejecutar.
  ///
  /// Desarrollo:
  /// flutter run -d chrome
  ///
  /// Backend remoto:
  /// flutter run -d chrome \
  ///   --dart-define=API_BASE_URL=https://tu-api.onrender.com
  ///
  /// Producción:
  /// flutter build web \
  ///   --dart-define=API_BASE_URL=https://tu-api.onrender.com

  static const String _apiBaseUrlOverride = String.fromEnvironment(
    'API_BASE_URL',
  );

  static String get apiBaseUrl {
    if (_apiBaseUrlOverride.trim().isNotEmpty) {
      return _normalizeBaseUrl(
        _apiBaseUrlOverride,
      );
    }

    // Flutter Web local.
    if (kIsWeb) {
      return 'http://127.0.0.1:8000';
    }

    // Android Emulator.
    if (defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:8000';
    }

    // Windows / Linux / macOS / iOS simulator local.
    return 'http://127.0.0.1:8000';
  }

  static const String apiPrefix = '/api/v1';

  static const Duration requestTimeout = Duration(seconds: 15);

  static String get analyzeEndpoint => '$apiBaseUrl$apiPrefix/analyze';

  static String get loginEndpoint => '$apiBaseUrl$apiPrefix/auth/login';

  static String get registerEndpoint => '$apiBaseUrl$apiPrefix/auth/register';

  static String get authProfileEndpoint => '$apiBaseUrl$apiPrefix/auth/me';

  static String get profileEndpoint => '$apiBaseUrl$apiPrefix/users/me';

  static String get changePasswordEndpoint =>
      '$apiBaseUrl$apiPrefix/users/me/password';

  // Este endpoint NO tiene /api/v1.
  static String get healthEndpoint => '$apiBaseUrl/health';

  static String _normalizeBaseUrl(
    String value,
  ) {
    final trimmed = value.trim();

    if (trimmed.endsWith('/')) {
      return trimmed.substring(
        0,
        trimmed.length - 1,
      );
    }

    return trimmed;
  }
}
