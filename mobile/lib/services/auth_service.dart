import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../core/config/app_config.dart';
import '../core/network/api_exception.dart';
import 'session_service.dart';

class AuthService {
  Future<Map<String, dynamic>> login({
    required String correo,
    required String password,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse(
              AppConfig.loginEndpoint,
            ),
            headers: const {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: jsonEncode({
              'correo': correo.trim().toLowerCase(),
              'password': password,
            }),
          )
          .timeout(
            AppConfig.requestTimeout,
          );

      final data = _decodeResponse(
        response.body,
      );

      if (response.statusCode == 200) {
        final token = data['access_token'];

        if (token is! String || token.trim().isEmpty) {
          throw const ApiException(
            message: 'No se pudo iniciar sesión.',
          );
        }

        await SessionService.saveToken(
          token,
        );

        return {
          'success': true,
          'data': data,
        };
      }

      throw _exceptionFromResponse(
        response.statusCode,
        data,
      );
    } on TimeoutException {
      throw const ApiException(
        message: 'El servidor está tardando demasiado. '
            'Inténtalo nuevamente.',
      );
    } on http.ClientException {
      throw const ApiException(
        message: 'No se pudo conectar con el servidor. '
            'Verifica tu conexión a Internet.',
      );
    } on FormatException {
      throw const ApiException(
        message: 'El servidor devolvió una respuesta '
            'no válida.',
      );
    }
  }

  Future<Map<String, dynamic>> register({
    required String nombre,
    String? apellido,
    required String correo,
    required String password,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse(
              AppConfig.registerEndpoint,
            ),
            headers: const {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: jsonEncode({
              'nombre': nombre.trim(),
              'apellido':
                  apellido?.trim().isEmpty == true ? null : apellido?.trim(),
              'correo': correo.trim().toLowerCase(),
              'password': password,
            }),
          )
          .timeout(
            AppConfig.requestTimeout,
          );

      final data = _decodeResponse(
        response.body,
      );

      if (response.statusCode == 201) {
        return {
          'success': true,
          'data': data,
        };
      }

      throw _exceptionFromResponse(
        response.statusCode,
        data,
      );
    } on TimeoutException {
      throw const ApiException(
        message: 'El servidor está tardando demasiado. '
            'Inténtalo nuevamente.',
      );
    } on http.ClientException {
      throw const ApiException(
        message: 'No se pudo conectar con el servidor. '
            'Verifica tu conexión a Internet.',
      );
    } on FormatException {
      throw const ApiException(
        message: 'El servidor devolvió una respuesta '
            'no válida.',
      );
    }
  }

  Future<void> logout() async {
    await SessionService.clearToken();
  }

  Future<bool> isLoggedIn() {
    return SessionService.hasToken();
  }

  Map<String, dynamic> _decodeResponse(
    String body,
  ) {
    if (body.trim().isEmpty) {
      return <String, dynamic>{};
    }

    final decoded = jsonDecode(body);

    if (decoded is Map<String, dynamic>) {
      return decoded;
    }

    throw const FormatException(
      'Invalid JSON response',
    );
  }

  ApiException _exceptionFromResponse(
    int statusCode,
    Map<String, dynamic> data,
  ) {
    switch (statusCode) {
      case 400:
        return ApiException(
          statusCode: statusCode,
          message: _extractMessage(
            data,
            fallback: 'Revisa los datos ingresados.',
          ),
        );

      case 401:
        return const ApiException(
          statusCode: 401,
          message: 'Correo o contraseña incorrectos.',
        );

      case 403:
        return const ApiException(
          statusCode: 403,
          message: 'No se pudo iniciar sesión.',
        );

      case 422:
        return ApiException(
          statusCode: 422,
          message: _extractMessage(
            data,
            fallback: 'Revisa los datos ingresados.',
          ),
        );

      case 429:
        return const ApiException(
          statusCode: 429,
          message: 'Demasiados intentos. '
              'Inténtalo nuevamente más tarde.',
        );

      case 500:
        return const ApiException(
          statusCode: 500,
          message: 'Ocurrió un problema en el servidor. '
              'Inténtalo nuevamente.',
        );

      case 503:
        return const ApiException(
          statusCode: 503,
          message: 'El servicio no está disponible '
              'temporalmente.',
        );

      default:
        return const ApiException(
          message: 'No se pudo completar la operación.',
        );
    }
  }

  String _extractMessage(
    Map<String, dynamic> data, {
    required String fallback,
  }) {
    final detail = data['detail'];

    if (detail is String && detail.trim().isNotEmpty) {
      return detail;
    }

    if (detail is Map<String, dynamic>) {
      final message = detail['message'];

      final errors = detail['errors'];

      if (errors is List && errors.isNotEmpty) {
        return errors.map((e) => e.toString()).join('\n');
      }

      if (message is String && message.trim().isNotEmpty) {
        return message;
      }
    }

    final message = data['message'];

    if (message is String && message.trim().isNotEmpty) {
      return message;
    }

    return fallback;
  }
}
