class AppConfig {
  static const String apiBaseUrl = 'http://10.0.2.2:8000';
  static const String apiPrefix = '/api/v1';

  static const String analyzeEndpoint =
      '$apiBaseUrl$apiPrefix/analyze';

  static const String healthEndpoint =
      '$apiBaseUrl/health';
}