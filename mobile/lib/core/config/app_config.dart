import 'package:flutter/foundation.dart';

class AppConfig {
  static String get apiBaseUrl {
    if (kIsWeb) {
      return 'http://127.0.0.1:8000';
    }

    return 'http://10.0.2.2:8000';
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
}