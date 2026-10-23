
import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

import '../core/config/app_config.dart';

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
  }) async {
    final request = http.MultipartRequest(
      'POST',
      Uri.parse(AppConfig.analyzeEndpoint),
    );

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
        'El servidor no respondió. Verifica la conexión e inténtalo de nuevo.',
      );
    }

    final body = await response.stream
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
      throw Exception('Formato de respuesta inesperado.');
    }

    if (response.statusCode < 200 ||
        response.statusCode >= 300) {
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
