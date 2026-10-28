import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/config/app_config.dart';
import 'session_service.dart';

class ProfileService {
  final http.Client _client;

  ProfileService({http.Client? client})
      : _client = client ?? http.Client();

  Future<Map<String, dynamic>> _request(
    String method,
    String endpoint, {
    Map<String, dynamic>? body,
  }) async {
    final token = await SessionService.getToken();

    if (token == null || token.isEmpty) {
      throw Exception(
        'No se encontró una sesión activa. Inicia sesión nuevamente.',
      );
    }

    final uri = Uri.parse('${AppConfig.apiBaseUrl}${AppConfig.apiPrefix}$endpoint');

    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };

    late final http.Response response;

    switch (method) {
      case 'GET':
        response = await _client.get(uri, headers: headers);
        break;
      case 'PUT':
        response = await _client.put(
          uri,
          headers: headers,
          body: jsonEncode(body ?? {}),
        );
        break;
      default:
        throw UnsupportedError('Método HTTP no soportado: $method');
    }

    final dynamic decoded;

    try {
      decoded = response.body.isEmpty ? <String, dynamic>{} : jsonDecode(response.body);
    } on FormatException {
      throw Exception('El servidor devolvió una respuesta no válida.');
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      final message = decoded is Map
          ? decoded['detail']?.toString() ?? 'Error en la solicitud.'
          : 'Error en la solicitud.';

      throw Exception(message);
    }

    if (decoded is Map<String, dynamic>) {
      return decoded;
    }

    throw Exception('Formato de respuesta inesperado.');
  }

  Future<Map<String, dynamic>> getMyProfile() {
    return _request('GET', '/auth/me');
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
        'apellido': (apellido ?? '').trim(),
        'correo': correo.trim(),
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

  void dispose() {
    _client.close();
  }
}
