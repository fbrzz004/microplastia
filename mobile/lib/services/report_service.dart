import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../core/config/app_config.dart';
import 'session_service.dart';

class ReportResult {
  final String filename;
  final String reportUrl;
  final int totalAnalyses;

  const ReportResult({
    required this.filename,
    required this.reportUrl,
    required this.totalAnalyses,
  });

  factory ReportResult.fromJson(Map<String, dynamic> json) {
    return ReportResult(
      filename: json['filename']?.toString() ?? '',
      reportUrl: json['report_url']?.toString() ?? '',
      totalAnalyses: _toInt(json['total_analyses']),
    );
  }
}

class ReportService {
  ReportService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  static const Duration _timeout = Duration(seconds: 120);

  Future<ReportResult> generate(List<int> resultIds) async {
    final token = await SessionService.getToken();

    if (token == null || token.isEmpty) {
      throw Exception('Tu sesión expiró. Inicia sesión de nuevo.');
    }

    final http.Response response;

    try {
      response = await _client
          .post(
            Uri.parse(AppConfig.reportsEndpoint),
            headers: {
              'Accept': 'application/json',
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: jsonEncode({'result_ids': resultIds}),
          )
          .timeout(_timeout);
    } on TimeoutException {
      throw Exception(
        'El reporte está tardando demasiado. Inténtalo de nuevo.',
      );
    }

    dynamic decoded;

    try {
      decoded = jsonDecode(response.body);
    } on FormatException {
      decoded = null;
    }

    if (response.statusCode == 401) {
      throw Exception('Tu sesión expiró. Inicia sesión de nuevo.');
    }

    if (response.statusCode == 404) {
      throw Exception(
        'Uno o más análisis ya no están disponibles. '
        'Actualiza el historial e inténtalo de nuevo.',
      );
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      final detalle = decoded is Map
          ? decoded['detail'] ?? decoded['message']
          : null;

      throw Exception(
        detalle?.toString() ??
            'No se pudo generar el reporte '
                '(${response.statusCode}).',
      );
    }

    if (decoded is! Map<String, dynamic>) {
      throw Exception('El servidor devolvió una respuesta no válida.');
    }

    final data = decoded['data'];

    if (data is! Map) {
      throw Exception('Formato de respuesta inesperado.');
    }

    return ReportResult.fromJson(Map<String, dynamic>.from(data));
  }

  void dispose() {
    _client.close();
  }
}

int _toInt(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.round();
  return int.tryParse(value?.toString() ?? '') ?? 0;
}
