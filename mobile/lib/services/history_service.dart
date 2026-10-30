import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../core/config/app_config.dart';
import '../core/network/api_error_mapper.dart';
import '../core/network/api_exception.dart';
import '../models/analysis_result.dart';
import 'session_service.dart';

class HistoryService {
  HistoryService({
    http.Client? client,
  }) : _client = client ?? http.Client();

  final http.Client _client;

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
      '${AppConfig.apiBaseUrl}'
      '${AppConfig.apiPrefix}'
      '/history',
    ).replace(
      queryParameters: parametros,
    );

    final data = await _get(uri);

    final items = data['items'] as List? ?? const [];

    return items
        .whereType<Map>()
        .map(
          (item) => AnalysisSummary.fromJson(
            Map<String, dynamic>.from(
              item,
            ),
          ),
        )
        .toList();
  }

  Future<AnalysisDetail> obtener(
    int id,
  ) async {
    final uri = Uri.parse(
      '${AppConfig.apiBaseUrl}'
      '${AppConfig.apiPrefix}'
      '/results/$id',
    );

    final data = await _get(uri);

    return AnalysisDetail.fromJson(
      data,
    );
  }

  Future<Map<String, dynamic>> _get(
    Uri uri,
  ) async {
    final token = await SessionService.getValidToken();

    if (token == null) {
      throw const ApiException(
        statusCode: 401,
        sessionExpired: true,
        message: 'Tu sesión expiró. '
            'Inicia sesión nuevamente.',
      );
    }

    late final http.Response response;

    try {
      response = await _client.get(
        uri,
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(
        AppConfig.requestTimeout,
      );
    } on TimeoutException {
      throw const ApiException(
        message: 'El servidor está tardando '
            'demasiado. Inténtalo nuevamente.',
      );
    } on http.ClientException {
      throw const ApiException(
        message: 'No se pudo conectar con '
            'el servidor.',
      );
    }

    final decoded = _decode(response.body);

    if (response.statusCode == 401) {
      await SessionService.clearToken();

      throw ApiErrorMapper.fromStatusCode(401);
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ApiErrorMapper.fromStatusCode(
        response.statusCode,
        serverMessage: _extractMessage(decoded),
      );
    }

    if (decoded is! Map<String, dynamic>) {
      throw const ApiException(
        message: 'El servidor devolvió '
            'una respuesta no válida.',
      );
    }

    final data = decoded['data'];

    if (data is! Map) {
      throw const ApiException(
        message: 'No se pudo interpretar '
            'la respuesta del servidor.',
      );
    }

    return Map<String, dynamic>.from(
      data,
    );
  }

  dynamic _decode(
    String body,
  ) {
    if (body.trim().isEmpty) {
      return null;
    }

    try {
      return jsonDecode(body);
    } on FormatException {
      return null;
    }
  }

  String? _extractMessage(
    dynamic decoded,
  ) {
    if (decoded is! Map) {
      return null;
    }

    final detail = decoded['detail'];

    if (detail is String && detail.trim().isNotEmpty) {
      return detail;
    }

    final message = decoded['message'];

    if (message is String && message.trim().isNotEmpty) {
      return message;
    }

    return null;
  }

  void dispose() {
    _client.close();
  }
}
