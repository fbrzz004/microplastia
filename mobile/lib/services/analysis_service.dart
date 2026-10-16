
import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

class AnalysisService {
  static const String baseUrl = 'http://127.0.0.1:8000';

  Future<Map<String, dynamic>> analizarImagen({
    required Uint8List bytes,
    required String filename,
  }) async {
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('$baseUrl/api/v1/analyze'),
    );

    request.files.add(
      http.MultipartFile.fromBytes(
        'file',
        bytes,
        filename: filename,
      ),
    );

    final response = await request.send();
    final body = await response.stream.bytesToString();

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
