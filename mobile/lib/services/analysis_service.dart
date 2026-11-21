import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

import '../core/config/app_config.dart';
import 'session_service.dart';
import 'tflite_inference_service.dart';

class AnalysisService {
  static const Duration _timeout = Duration(seconds: 30);

  Map<String, dynamic> crearPayload(
    TfliteAnalysisResult resultado,
  ) {
    return {
      'total_particles': resultado.totalParticles,
      'confidence': resultado.averageConfidence,
      'breakdown': resultado.breakdown,
      'detections': resultado.detections
          .map(
            (detection) => detection.toJson(),
          )
          .toList(),
      'processing_time_ms': resultado.inferenceTimeMs,
      'modelo_nombre': resultado.modelName,
      'modelo_version': resultado.modelVersion,
      'modelo_origen': resultado.modelSource,
    };
  }

  Future<Map<String, dynamic>> guardarAnalisisMovil({
    required TfliteAnalysisResult resultado,
    required Uint8List annotatedBytes,
    Uint8List? originalBytes,
    String? sampleId,
    String? clientUuid,
    bool isOfflineSync = false,
  }) {
    return guardarPayloadMovil(
      payload: crearPayload(resultado),
      annotatedBytes: annotatedBytes,
      originalBytes: originalBytes,
      sampleId: sampleId,
      clientUuid: clientUuid,
      isOfflineSync: isOfflineSync,
    );
  }

  Future<Map<String, dynamic>> guardarPayloadMovil({
    required Map<String, dynamic> payload,
    required Uint8List annotatedBytes,
    Uint8List? originalBytes,
    String? sampleId,
    String? clientUuid,
    bool isOfflineSync = false,
  }) async {
    final token = await SessionService.getValidToken();

    if (token == null || token.isEmpty) {
      throw Exception(
        'Tu sesión expiró. Inicia sesión de nuevo.',
      );
    }

    final requestPayload = Map<String, dynamic>.from(payload);

    if (sampleId != null) {
      requestPayload['sample_id'] = sampleId;
    }

    if (clientUuid != null) {
      requestPayload['client_uuid'] = clientUuid;
    }

    requestPayload['is_offline_sync'] = isOfflineSync;

    final request = http.MultipartRequest(
      'POST',
      Uri.parse(
        '${AppConfig.apiBaseUrl}'
        '/api/v1/analyze/mobile',
      ),
    );

    request.headers['Authorization'] = 'Bearer $token';

    request.fields['payload'] = jsonEncode(requestPayload);

    request.files.add(
      http.MultipartFile.fromBytes(
        'annotated_file',
        annotatedBytes,
        filename: 'annotated.jpg',
        contentType: MediaType('image', 'jpeg'),
      ),
    );

    if (originalBytes != null && originalBytes.isNotEmpty) {
      request.files.add(
        http.MultipartFile.fromBytes(
          'original_file',
          originalBytes,
          filename: 'original.jpg',
          contentType: MediaType('image', 'jpeg'),
        ),
      );
    }

    late http.StreamedResponse response;

    try {
      response = await request.send().timeout(_timeout);
    } on TimeoutException {
      throw Exception(
        'El servidor no respondió. '
        'La muestra quedó guardada.',
      );
    } catch (_) {
      throw Exception(
        'No se pudo conectar con el servidor. '
        'La muestra quedó guardada.',
      );
    }

    final body = await response.stream.bytesToString().timeout(_timeout);

    final decoded = jsonDecode(body);

    if (decoded is! Map<String, dynamic>) {
      throw Exception(
        'Formato de respuesta inesperado.',
      );
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        'Error ${response.statusCode}: '
        '${decoded['detail'] ?? decoded['message'] ?? body}',
      );
    }

    return decoded;
  }
}
