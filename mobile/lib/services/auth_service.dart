import 'dart:convert';

import 'package:http/http.dart' as http;

import '../core/config/app_config.dart';
import 'session_service.dart';


class AuthService {
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
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 200) {
      final token = data['access_token'] as String;

      await SessionService.saveToken(token);

      return {
        'success': true,
        'data': data,
      };
    }

    return {
      'success': false,
      'message': data['detail'] ?? 'Error al iniciar sesión',
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
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 201) {
      return {
        'success': true,
        'data': data,
      };
    }

    return {
      'success': false,
      'message': data['detail'] ?? 'Error al registrar usuario',
    };
  }

  Future<void> logout() async {
    await SessionService.clearToken();
  }

  Future<bool> isLoggedIn() async {
    return SessionService.hasToken();
  }
}