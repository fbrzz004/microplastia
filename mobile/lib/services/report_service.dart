import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../core/config/app_config.dart';
import '../core/network/api_error_mapper.dart';
import '../core/network/api_exception.dart';
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
  ReportService({
    http.Client? client,
  }) : _client = client ?? http.Client();

  final http.Client _client;

  Future<ReportResult> generate(
    List<int> resultIds,
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
      response = await _client.post(
        Uri.parse(
          AppConfig.reportsEndpoint,
        ),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'result_ids': resultIds,
        }),
      ).timeout(
        AppConfig.requestTimeout * 2,
      );
    } on TimeoutException {
      throw const ApiException(
        message: 'El reporte está tardando '
            'demasiado. Inténtalo nuevamente.',
      );
    } on http.ClientException {
      throw const ApiException(
        message: 'No se pudo conectar con '
            'el servidor.',
      );
    }

    final decoded = _decode(
      response.body,
    );

    if (response.statusCode == 401) {
      await SessionService.clearToken();

      throw ApiErrorMapper.fromStatusCode(401);
    }

    if (response.statusCode == 404) {
      throw const ApiException(
        statusCode: 404,
        message: 'Uno o más análisis ya no '
            'están disponibles. Actualiza '
            'el historial.',
      );
    }

    if (response.statusCode < 200 ||
        response.statusCode >= 300) {
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

    return ReportResult.fromJson(
      Map<String, dynamic>.from(
        data,
      ),
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

int _toInt(dynamic value) {
  if (value is int) {
    return value;
  }

  if (value is num) {
    return value.round();
  }

  return int.tryParse(
        value?.toString() ?? '',
      ) ??
      0;
}
