import 'dart:async';
import 'dart:convert';
<<<<<<< Updated upstream

import 'package:http/http.dart' as http;

=======
import 'package:http/http.dart' as http;
>>>>>>> Stashed changes
import '../core/config/app_config.dart';
import '../models/analysis_result.dart';
import 'session_service.dart';

class HistoryService {
  HistoryService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  static const Duration _timeout = Duration(seconds: 15);

  Future<List<AnalysisSummary>> listar({
    String? query,
    int limit = 50,
    int offset = 0,
  }) async {
    final parametros = <String, String>{
      'limit': '$limit',
      'offset': '$offset',
    };

    if (query != null && query.trim().isNotEmpty) {
      parametros['q'] = query.trim();
    }

    final uri = Uri.parse(
      '${AppConfig.apiBaseUrl}${AppConfig.apiPrefix}/history',
    ).replace(queryParameters: parametros);

    final data = await _get(uri);
    final items = data['items'] as List? ?? const [];

    return items
        .whereType<Map>()
        .map(
          (item) => AnalysisSummary.fromJson(
            Map<String, dynamic>.from(item),
          ),
        )
        .toList();
  }

  Future<AnalysisDetail> obtener(int id) async {
    final uri = Uri.parse(
      '${AppConfig.apiBaseUrl}${AppConfig.apiPrefix}/results/$id',
    );

    final data = await _get(uri);

    return AnalysisDetail.fromJson(data);
  }

  Future<Map<String, dynamic>> _get(Uri uri) async {
    final token = await SessionService.getToken();

    if (token == null || token.isEmpty) {
      throw Exception('Tu sesión expiró. Inicia sesión de nuevo.');
    }

    final http.Response response;

    try {
      response = await _client
          .get(
            uri,
            headers: {
              'Accept': 'application/json',
              'Authorization': 'Bearer $token',
            },
          )
          .timeout(_timeout);
    } on TimeoutException {
      throw Exception(
        'El servidor no respondió. Verifica la conexión e inténtalo de nuevo.',
      );
    }

    dynamic decoded;

    try {
      decoded = jsonDecode(response.body);
    } on FormatException {
      // Un 500 de FastAPI responde texto plano, no JSON: se informa el código.
      decoded = null;
    }

    if (response.statusCode == 401) {
      throw Exception('Tu sesión expiró. Inicia sesión de nuevo.');
    }

    if (response.statusCode == 404) {
      throw Exception('El análisis solicitado no existe.');
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      final detalle = decoded is Map
          ? decoded['detail'] ?? decoded['message']
          : null;

      throw Exception(
        detalle?.toString() ??
            'El servidor respondió ${response.statusCode}. '
                'Inténtalo de nuevo.',
      );
    }

    if (decoded is! Map<String, dynamic>) {
      throw Exception('El servidor devolvió una respuesta no válida.');
    }

    final data = decoded['data'];

    if (data is! Map) {
      throw Exception('Formato de respuesta inesperado.');
    }

    return Map<String, dynamic>.from(data);
  }
<<<<<<< Updated upstream
=======
  
  void dispose() {
    _client.close();
  }
>>>>>>> Stashed changes
}
