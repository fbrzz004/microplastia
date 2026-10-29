import 'package:flutter/foundation.dart';

class AppConfig {
  /// Permite apuntar al backend en tiempo de compilación:
  /// flutter run --dart-define=API_BASE_URL=http://172.16.58.141:8000
  static const String _apiBaseUrlOverride = String.fromEnvironment(
    'API_BASE_URL',
  );

  static String get apiBaseUrl {
    if (_apiBaseUrlOverride.isNotEmpty) {
      return _apiBaseUrlOverride;
    }

    // En web y escritorio el backend corre en la misma máquina.
    if (kIsWeb) {
      return 'http://127.0.0.1:8000';
    }

    // 10.0.2.2 solo funciona en el emulador de Android.
    if (defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:8000';
    }

    return 'http://127.0.0.1:8000';
  }

  static const String apiPrefix = '/api/v1';

  static String get analyzeEndpoint =>
      '$apiBaseUrl$apiPrefix/analyze';

  static String get healthEndpoint =>
      '$apiBaseUrl$apiPrefix/health';

  static String get loginEndpoint =>
      '$apiBaseUrl$apiPrefix/auth/login';

  static String get registerEndpoint =>
      '$apiBaseUrl$apiPrefix/auth/register';

  static String get profileEndpoint =>
      '$apiBaseUrl$apiPrefix/users/me';

  static String get reportsEndpoint =>
      '$apiBaseUrl$apiPrefix/reports';
}