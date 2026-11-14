
import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

import '../core/config/app_config.dart';
import 'session_service.dart';

class AnalysisService {
  static const Duration _timeout = Duration(seconds: 60);

  static MediaType _contentTypeFor(String filename) {
    final extension = filename.split('.').last.toLowerCase();

    switch (extension) {
      case 'png':
        return MediaType('image', 'png');
      case 'webp':
        return MediaType('image', 'webp');
      case 'heic':
        return MediaType('image', 'heic');
      case 'heif':
        return MediaType('image', 'heif');
      default:
        return MediaType('image', 'jpeg');
    }
  }

  Future<Map<String, dynamic>> analizarImagen({
    required Uint8List bytes,
    required String filename,
    String? sampleId,
    String? clientUuid,
    bool isOfflineSync = false,
  }) async {
    final token = await SessionService.getToken();

    if (token == null || token.isEmpty) {
      throw Exception('Tu sesión expiró. Inicia sesión de nuevo.');
    }

    final request = http.MultipartRequest(
      'POST',
      Uri.parse(AppConfig.analyzeEndpoint),
    );

    request.headers['Authorization'] = 'Bearer $token';

    // Datos de identificación de la muestra.
    if (sampleId != null) {
      request.fields['sample_id'] = sampleId;
    }

    if (clientUuid != null) {
      request.fields['client_uuid'] = clientUuid;
    }

    request.fields['is_offline_sync'] = isOfflineSync.toString();

    request.files.add(
      http.MultipartFile.fromBytes(
        'file',
        bytes,
        filename: filename,
        contentType: _contentTypeFor(filename),
      ),
    );

    final http.StreamedResponse response;

    try {
      response = await request.send().timeout(_timeout);
    } on TimeoutException {
      throw Exception(
        'El servidor no respondió. La muestra se conservará para reintentar.',
      );
    } catch (e) {
      throw Exception(
        'No fue posible conectar con el servidor. '
        'La muestra se conservará para reintentar.',
      );
    }

    final String body;

    try {
      body = await response.stream.bytesToString().timeout(_timeout);
    } on TimeoutException {
      throw Exception(
        'Se agotó el tiempo de espera al recibir el resultado.',
      );
    }

    dynamic decoded;

    try {
      decoded = jsonDecode(body);
    } on FormatException {
      throw Exception('El servidor devolvió una respuesta no válida.');
    }

    if (decoded is! Map<String, dynamic>) {
      throw Exception('Formato de respuesta inesperado.');
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        'Error ${response.statusCode}: '
        '${decoded['detail'] ?? decoded['message'] ?? body}',
      );
    }

    if (decoded['success'] == false) {
      throw Exception(
        decoded['message'] ?? 'No se pudo analizar la imagen.',
      );
    }

    return decoded;
  }
}
