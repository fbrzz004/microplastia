import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

import '../core/config/app_config.dart';
import '../core/network/api_error_mapper.dart';
import '../core/network/api_exception.dart';
import 'session_service.dart';

class AnalysisService {
  static const int _maxUploadBytes = 10 * 1024 * 1024;

  // La inferencia puede tardar más que una petición normal.
  static const Duration _analysisTimeout = Duration(seconds: 120);

  MediaType _contentTypeFor(
    String filename,
  ) {
    final parts = filename.toLowerCase().split('.');

    if (parts.length < 2) {
      throw const ApiException(
        message: 'No se pudo identificar el formato de la imagen.',
      );
    }

    final extension = parts.last;

    switch (extension) {
      case 'jpg':
      case 'jpeg':
        return MediaType(
          'image',
          'jpeg',
        );

      case 'png':
        return MediaType(
          'image',
          'png',
        );

      case 'webp':
        return MediaType(
          'image',
          'webp',
        );

      case 'heic':
        return MediaType(
          'image',
          'heic',
        );

      case 'heif':
        return MediaType(
          'image',
          'heif',
        );

      default:
        throw const ApiException(
          message: 'Formato no compatible. '
              'Usa JPG, JPEG, PNG, WEBP, HEIC o HEIF.',
        );
    }
  }

  Future<Map<String, dynamic>> analizarImagen({
    required Uint8List bytes,
    required String filename,
  }) async {
    // =====================================================
    // VALIDACIONES LOCALES
    // =====================================================

    if (bytes.isEmpty) {
      throw const ApiException(
        message: 'La imagen seleccionada está vacía.',
      );
    }

    if (bytes.length > _maxUploadBytes) {
      throw const ApiException(
        statusCode: 413,
        message: 'La imagen supera el tamaño máximo '
            'permitido de 10 MB.',
      );
    }

    final contentType = _contentTypeFor(
      filename,
    );

    // =====================================================
    // SESIÓN
    // =====================================================

    final token = await SessionService.getValidToken();

    if (token == null) {
      throw const ApiException(
        statusCode: 401,
        sessionExpired: true,
        message: 'Tu sesión expiró. '
            'Inicia sesión nuevamente.',
      );
    }

    // =====================================================
    // REQUEST
    // =====================================================

    final request = http.MultipartRequest(
      'POST',
      Uri.parse(
        AppConfig.analyzeEndpoint,
      ),
    );

    request.headers['Authorization'] = 'Bearer $token';

    request.headers['Accept'] = 'application/json';

    request.files.add(
      http.MultipartFile.fromBytes(
        'file',
        bytes,
        filename: filename,
        contentType: contentType,
      ),
    );

    // =====================================================
    // ENVÍO
    // =====================================================

    late final http.StreamedResponse response;

    try {
      response = await request.send().timeout(
            _analysisTimeout,
          );
    } on TimeoutException {
      throw const ApiException(
        message: 'El análisis está tardando demasiado. '
            'Inténtalo nuevamente.',
      );
    } on http.ClientException {
      throw const ApiException(
        message: 'No se pudo conectar con el servidor. '
            'Verifica tu conexión.',
      );
    }

    // =====================================================
    // LEER RESPUESTA
    // =====================================================

    late final String body;

    try {
      body = await response.stream.bytesToString().timeout(
            _analysisTimeout,
          );
    } on TimeoutException {
      throw const ApiException(
        message: 'El servidor tardó demasiado '
            'en devolver el resultado.',
      );
    }

    final decoded = _decodeResponse(
      body,
    );

    // =====================================================
    // SESIÓN EXPIRADA
    // =====================================================

    if (response.statusCode == 401) {
      await SessionService.clearToken();

      throw ApiErrorMapper.fromStatusCode(
        401,
      );
    }

    // =====================================================
    // OTROS ERRORES HTTP
    // =====================================================

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ApiErrorMapper.fromStatusCode(
        response.statusCode,
        serverMessage: _extractMessage(
          decoded,
        ),
      );
    }

    // =====================================================
    // RESPUESTA INVÁLIDA
    // =====================================================

    if (decoded is! Map<String, dynamic>) {
      throw const ApiException(
        message: 'El servidor devolvió '
            'una respuesta no válida.',
      );
    }

    if (decoded['success'] == false) {
      throw ApiException(
        message: _extractMessage(
              decoded,
            ) ??
            'No se pudo analizar la imagen.',
      );
    }

    return decoded;
  }

  // =======================================================
  // JSON
  // =======================================================

  dynamic _decodeResponse(
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

  // =======================================================
  // MENSAJES DEL BACKEND
  // =======================================================

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

    if (detail is Map) {
      final message = detail['message'];

      if (message is String && message.trim().isNotEmpty) {
        return message;
      }

      final errors = detail['errors'];

      if (errors is List && errors.isNotEmpty) {
        return errors
            .map(
              (error) => error.toString(),
            )
            .join('\n');
      }
    }

    final message = decoded['message'];

    if (message is String && message.trim().isNotEmpty) {
      return message;
    }

    return null;
  }
}
