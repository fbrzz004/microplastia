import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

import '../core/config/app_config.dart';
import 'session_service.dart';
import 'tflite_inference_service.dart';

class AnalysisService {
  static const Duration _timeout = Duration(seconds: 30);

  Future<Map<String, dynamic>> guardarAnalisisMovil({
    required TfliteAnalysisResult resultado,
    required Uint8List annotatedBytes,
  }) async {
    final token = await SessionService.getToken();

    if (token == null || token.isEmpty) {
      throw Exception(
        'Tu sesión expiró. Inicia sesión de nuevo.',
      );
    }

    final uri = Uri.parse(
      '${AppConfig.apiBaseUrl}/api/v1/analyze/mobile',
    );

    final payload = {
      'total_particles': resultado.totalParticles,
      'confidence': resultado.averageConfidence,
      'breakdown': resultado.breakdown,
      'detections': resultado.detections
          .map(
            (detection) => detection.toJson(),
      )
          .toList(),
      'processing_time_ms': resultado.inferenceTimeMs,
    };

    final request = http.MultipartRequest(
      'POST',
      uri,
    );

    request.headers['Authorization'] =
    'Bearer $token';

    request.fields['payload'] =
        jsonEncode(payload);

    request.files.add(
      http.MultipartFile.fromBytes(
        'annotated_file',
        annotatedBytes,
        filename: 'annotated.jpg',
        contentType: MediaType(
          'image',
          'jpeg',
        ),
      ),
    );

    late http.StreamedResponse streamedResponse;

    try {
      streamedResponse = await request
          .send()
          .timeout(_timeout);
    } on TimeoutException {
      throw Exception(
        'El servidor no respondió. '
            'Verifica tu conexión e inténtalo nuevamente.',
      );
    } catch (e) {
      throw Exception(
        'No se pudo conectar con el servidor: $e',
      );
    }

    final body = await streamedResponse.stream
        .bytesToString()
        .timeout(_timeout);

    dynamic decoded;

    try {
      decoded = jsonDecode(body);
    } on FormatException {
      throw Exception(
        'El servidor devolvió una respuesta no válida.',
      );
    }

    if (decoded is! Map<String, dynamic>) {
      throw Exception(
        'Formato de respuesta inesperado.',
      );
    }

    if (
    streamedResponse.statusCode < 200 ||
        streamedResponse.statusCode >= 300) {
      throw Exception(
        'Error ${streamedResponse.statusCode}: '
            '${decoded['detail'] ?? decoded['message'] ?? body}',
      );
    }

    if (decoded['success'] == false) {
      throw Exception(
        decoded['message'] ??
            'No se pudo guardar el análisis.',
      );
    }

    return decoded;
  }
}