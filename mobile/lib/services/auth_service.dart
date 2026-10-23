import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/config/app_config.dart';
import 'session_service.dart';

class AuthService {
  static const Duration _timeout = Duration(seconds: 10);

  Future<Map<String, dynamic>> login({
    required String correo,
    required String password,
  }) async {
    final url = Uri.parse(
      '${AppConfig.apiBaseUrl}${AppConfig.apiPrefix}/auth/login',
    );

    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'accept': 'application/json',
      },
      body: jsonEncode({
        'correo': correo,
        'password': password,
      }),
    ).timeout(_timeout);

    final data = _decodeResponse(response.body);

    if (response.statusCode == 200) {
      final token = data['access_token'];

      if (token is! String || token.isEmpty) {
        throw const FormatException(
          'La respuesta del servidor no contiene un token válido.',
        );
      }

      await SessionService.saveToken(token);

      return {
        'success': true,
        'data': data,
      };
    }

    return {
      'success': false,
      'message': _getErrorMessage(
        data,
        'Error al iniciar sesión',
      ),
    };
  }

  Future<Map<String, dynamic>> register({
    required String nombre,
    String? apellido,
    required String correo,
    required String password,
  }) async {
    final url = Uri.parse(
      '${AppConfig.apiBaseUrl}${AppConfig.apiPrefix}/auth/register',
    );

    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'accept': 'application/json',
      },
      body: jsonEncode({
        'nombre': nombre,
        'apellido': apellido,
        'correo': correo,
        'password': password,
      }),
    ).timeout(_timeout);

    final data = _decodeResponse(response.body);

    if (response.statusCode == 201) {
      return {
        'success': true,
        'data': data,
      };
    }

    return {
      'success': false,
      'message': _getErrorMessage(
        data,
        'Error al registrar usuario',
      ),
    };
  }

  Future<void> logout() async {
    await SessionService.clearToken();
  }

  Future<bool> isLoggedIn() async {
    return SessionService.hasToken();
  }

  Map<String, dynamic> _decodeResponse(String body) {
    if (body.trim().isEmpty) {
      throw const FormatException(
        'El servidor devolvió una respuesta vacía.',
      );
    }

    final decoded = jsonDecode(body);

    if (decoded is! Map<String, dynamic>) {
      throw const FormatException(
        'El formato de respuesta del servidor no es válido.',
      );
    }

    return decoded;
  }

  String _getErrorMessage(
    Map<String, dynamic> data,
    String defaultMessage,
  ) {
    final detail = data['detail'] ?? data['message'];

    if (detail is String && detail.isNotEmpty) {
      return detail;
    }

    return defaultMessage;
  }
}
