import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../core/config/app_config.dart';
import '../core/network/api_error_mapper.dart';
import '../core/network/api_exception.dart';
import '../models/app_notification.dart';
import 'session_service.dart';

class NotificationResult {
  const NotificationResult({
    required this.items,
    required this.total,
    required this.unreadCount,
  });

  final List<AppNotification> items;
  final int total;
  final int unreadCount;
}

class NotificationService {
  NotificationService({
    http.Client? client,
  }) : _client = client ?? http.Client();

  final http.Client _client;

  Future<NotificationResult> load({
    int limit = 20,
    int offset = 0,
  }) async {
    final uri = Uri.parse(
      AppConfig.notificationsEndpoint,
    ).replace(
      queryParameters: {
        'limit': '$limit',
        'offset': '$offset',
      },
    );

    final data = await _request(
      'GET',
      uri,
    );

    final items = (data['items'] as List? ?? const [])
        .whereType<Map>()
        .map(
          (item) => AppNotification.fromJson(
            Map<String, dynamic>.from(item),
          ),
        )
        .toList();

    return NotificationResult(
      items: items,
      total: _toInt(data['total']),
      unreadCount: _toInt(
        data['unread_count'],
      ),
    );
  }

  Future<void> markAsRead(int notificationId) async {
    await _request(
      'POST',
      Uri.parse(
        '${AppConfig.notificationsEndpoint}/$notificationId/read',
      ),
    );
  }

  Future<void> markAllAsRead() async {
    await _request(
      'POST',
      Uri.parse(
        '${AppConfig.notificationsEndpoint}/read-all',
      ),
    );
  }

  Future<Map<String, dynamic>> _request(
    String method,
    Uri uri,
  ) async {
    final token = await SessionService.getValidToken();

    if (token == null) {
      throw const ApiException(
        statusCode: 401,
        sessionExpired: true,
        message: 'Tu sesión expiró. '
            'Inicia sesión nuevamente.',
      );
    }

    late final http.Response response;

    try {
      switch (method) {
        case 'GET':
          response = await _client.get(
            uri,
            headers: {
              'Accept': 'application/json',
              'Authorization': 'Bearer $token',
            },
          ).timeout(
            AppConfig.requestTimeout,
          );
          break;

        case 'POST':
          response = await _client.post(
            uri,
            headers: {
              'Accept': 'application/json',
              'Authorization': 'Bearer $token',
            },
          ).timeout(
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

    if (decoded is! Map<String, dynamic>) {
      throw const ApiException(
        message: 'El servidor devolvió '
            'una respuesta no válida.',
      );
    }

    final data = decoded['data'];

    if (data is! Map) {
      throw const ApiException(
        message: 'No se pudo interpretar '
            'la respuesta del servidor.',
      );
    }

    return Map<String, dynamic>.from(data);
  }

  dynamic _decode(String body) {
    if (body.trim().isEmpty) {
      return null;
    }

    try {
      return jsonDecode(body);
    } on FormatException {
      return null;
    }
  }

  String? _extractMessage(dynamic decoded) {
    if (decoded is! Map) return null;

    final detail = decoded['detail'];

    if (detail is String && detail.trim().isNotEmpty) {
      return detail;
    }

    final message = decoded['message'];

    if (message is String && message.trim().isNotEmpty) {
      return message;
    }

    return null;
  }

  static int _toInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.round();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  void dispose() {
    _client.close();
  }
}
