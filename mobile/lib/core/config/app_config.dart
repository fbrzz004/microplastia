import 'package:flutter/foundation.dart';

class AppConfig {
  /// URL de producción del backend desplegado en Render.
  static const String _productionBaseUrl =
      'https://microplastia-api.onrender.com';

  /// Permite sobrescribir la URL del backend al ejecutar o compilar.
  ///
  /// Ejemplos:
  ///
  /// Producción normal:
  /// flutter run
  ///
  /// Android Emulator + backend local:
  /// flutter run \
  ///   --dart-define=API_BASE_URL=http://10.0.2.2:8000
  ///
  /// Flutter Web + backend local:
  /// flutter run -d chrome \
  ///   --dart-define=API_BASE_URL=http://127.0.0.1:8000
  ///
  /// Backend local en puerto 8001:
  /// flutter run \
  ///   --dart-define=API_BASE_URL=http://10.0.2.2:8001
  ///
  /// APK de producción:
  /// flutter build apk --release
  static const String _apiBaseUrlOverride = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: '',
  );

  /// URL principal que utilizará toda la aplicación.
  ///
  /// Si se proporciona API_BASE_URL mediante --dart-define,
  /// esa URL tendrá prioridad.
  ///
  /// Si no se proporciona ninguna URL, se utilizará automáticamente
  /// el backend de producción desplegado en Render.
  static String get apiBaseUrl {
    if (_apiBaseUrlOverride.trim().isNotEmpty) {
      return _normalizeBaseUrl(_apiBaseUrlOverride);
    }

    return _productionBaseUrl;
  }

  /// URL local sugerida según la plataforma.
  ///
  /// Esta propiedad no se utiliza automáticamente en producción,
  /// pero puede ser útil para depuración o futuras configuraciones.
  static String get localBaseUrl {
    // Flutter Web.
    if (kIsWeb) {
      return 'http://127.0.0.1:8000';
    }

    // Android Emulator.
    if (defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:8000';
    }

    // Windows / Linux / macOS / iOS Simulator.
    return 'http://127.0.0.1:8000';
  }

  /// Prefijo general utilizado por los endpoints de la API.
  static const String apiPrefix = '/api/v1';

  /// Tiempo máximo de espera para las solicitudes HTTP.
  ///
  /// Se usa un tiempo un poco mayor porque Render puede tardar
  /// en responder cuando el servicio está iniciando.
  static const Duration requestTimeout = Duration(seconds: 30);

  // ---------------------------------------------------------------------------
  // ANÁLISIS
  // ---------------------------------------------------------------------------

  static String get analyzeEndpoint => '$apiBaseUrl$apiPrefix/analyze';

  // ---------------------------------------------------------------------------
  // AUTENTICACIÓN
  // ---------------------------------------------------------------------------

  static String get loginEndpoint => '$apiBaseUrl$apiPrefix/auth/login';

  static String get registerEndpoint => '$apiBaseUrl$apiPrefix/auth/register';

  static String get authProfileEndpoint => '$apiBaseUrl$apiPrefix/auth/me';

  // ---------------------------------------------------------------------------
  // USUARIO / PERFIL
  // ---------------------------------------------------------------------------

  static String get profileEndpoint => '$apiBaseUrl$apiPrefix/users/me';

  static String get changePasswordEndpoint =>
      '$apiBaseUrl$apiPrefix/users/me/password';

  // ---------------------------------------------------------------------------
  // HEALTH CHECK
  // ---------------------------------------------------------------------------

  /// Este endpoint pertenece a la raíz del backend y NO utiliza /api/v1.
  static String get healthEndpoint => '$apiBaseUrl/health';

  // ---------------------------------------------------------------------------
  // UTILIDADES
  // ---------------------------------------------------------------------------

  /// Elimina "/" al final de la URL para evitar rutas como:
  ///
  /// https://api.com//api/v1/auth/login
  static String _normalizeBaseUrl(String value) {
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
