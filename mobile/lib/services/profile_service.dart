import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../core/config/app_config.dart';
import '../core/network/api_error_mapper.dart';
import '../core/network/api_exception.dart';
import 'session_service.dart';

class ProfileService {
  final http.Client _client;

  ProfileService({
    http.Client? client,
  }) : _client = client ?? http.Client();

  Future<Map<String, dynamic>> _request(
    String method,
    String endpoint, {
    Map<String, dynamic>? body,
  }) async {
    final token = await SessionService.getValidToken();

    if (token == null) {
      throw const ApiException(
        statusCode: 401,
        sessionExpired: true,
        message: 'Tu sesión expiró. '
            'Inicia sesión nuevamente.',
      );
    }

    final uri = Uri.parse(
      '${AppConfig.apiBaseUrl}'
      '${AppConfig.apiPrefix}'
      '$endpoint',
    );

    final headers = <String, String>{
      'Accept': 'application/json',
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };

    late final http.Response response;

    try {
      switch (method) {
        case 'GET':
          response = await _client
              .get(
                uri,
                headers: headers,
              )
              .timeout(
                AppConfig.requestTimeout,
              );

          break;

        case 'PUT':
          response = await _client
              .put(
                uri,
                headers: headers,
                body: jsonEncode(
                  body ?? {},
                ),
              )
              .timeout(
                AppConfig.requestTimeout,
              );

          break;

        default:
          throw const ApiException(
            message: 'Operación no disponible.',
          );
      }
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

    if (decoded is Map<String, dynamic>) {
      return decoded;
    }

    throw const ApiException(
      message: 'El servidor devolvió '
          'una respuesta no válida.',
    );
  }

  Future<Map<String, dynamic>> getMyProfile() {
    return _request(
      'GET',
      '/auth/me',
    );
  }

  Future<Map<String, dynamic>> updateProfile({
    required String nombre,
    String? apellido,
    required String correo,
  }) {
    return _request(
      'PUT',
      '/users/me',
      body: {
        'nombre': nombre.trim(),
        'apellido': apellido?.trim().isEmpty == true ? null : apellido?.trim(),
        'correo': correo.trim().toLowerCase(),
      },
    );
  }

  Future<void> changePassword({
    required String passwordActual,
    required String passwordNueva,
    required String confirmarPassword,
  }) async {
    await _request(
      'PUT',
      '/users/me/password',
      body: {
        'password_actual': passwordActual,
        'password_nueva': passwordNueva,
        'confirmar_password': confirmarPassword,
      },
    );
  }

  dynamic _decode(
    String body,
  ) {
    if (body.trim().isEmpty) {
      return <String, dynamic>{};
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

    if (detail is String) {
      return detail;
    }

    if (detail is Map) {
      final errors = detail['errors'];

      if (errors is List && errors.isNotEmpty) {
        return errors
            .map(
              (e) => e.toString(),
            )
            .join('\n');
      }

      final message = detail['message'];

      if (message is String) {
        return message;
      }
    }

    final message = decoded['message'];

    if (message is String) {
      return message;
    }

    return null;
  }

  void dispose() {
    _client.close();
  }
}
