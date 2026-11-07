import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:mobile/services/notification_service.dart';
import 'package:mobile/views/notifications_view.dart';

String _base64Url(Map<String, dynamic> value) {
  return base64Url.encode(utf8.encode(jsonEncode(value))).replaceAll('=', '');
}

String _validToken() {
  final header = _base64Url({
    'alg': 'HS256',
    'typ': 'JWT',
  });

  final payload = _base64Url({
    'sub': '1',
    'type': 'access',
    'exp':
        DateTime.now().add(const Duration(hours: 1)).millisecondsSinceEpoch ~/
            1000,
  });

  return '$header.$payload.signature';
}

Map<String, dynamic> _notification({
  int id = 1,
  String title = 'Análisis completado',
  String message = 'Muestra MUESTRA-1 · 10 partículas · 90% de confianza',
  bool read = false,
}) {
  return {
    'id': id,
    'type': 'analysis',
    'title': title,
    'message': message,
    'result_id': 10 + id,
    'is_read': read,
    'created_at': '2026-11-07T10:00:00Z',
  };
}

http.Response _jsonResponse(Object body, {int status = 200}) {
  return http.Response(
    jsonEncode(body),
    status,
    headers: {'content-type': 'application/json'},
  );
}

NotificationService _service({
  bool empty = false,
}) {
  var read = false;

  final client = MockClient((request) async {
    if (request.url.path.endsWith('/read-all')) {
      read = true;

      return _jsonResponse({
        'success': true,
        'data': {'updated': 1, 'unread_count': 0},
      });
    }

    if (request.url.path.endsWith('/read')) {
      read = true;

      return _jsonResponse({
        'success': true,
        'data': _notification(read: true),
      });
    }

    return _jsonResponse({
      'success': true,
      'data': {
        'items': empty
            ? []
            : [
                _notification(read: read),
              ],
        'total': empty ? 0 : 1,
        'unread_count': empty || read ? 0 : 1,
        'limit': 20,
        'offset': 0,
      },
    });
  });

  return NotificationService(client: client);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({
      'access_token': _validToken(),
    });
  });

  test('carga notificaciones desde el endpoint del servidor', () async {
    final service = _service();

    final result = await service.load();

    expect(result.items.length, 1);
    expect(result.items.first.id, 1);
    expect(result.items.first.resultId, 11);
    expect(result.items.first.read, isFalse);
    expect(result.unreadCount, 1);
  });

  test('marca una notificación como leída en el servidor', () async {
    final service = _service();

    await service.markAsRead(1);

    final result = await service.load();

    expect(result.unreadCount, 0);
    expect(result.items.first.read, isTrue);
  });

  test('marca todas las notificaciones como leídas', () async {
    final service = _service();

    await service.markAllAsRead();

    final result = await service.load();

    expect(result.unreadCount, 0);
    expect(result.items.first.read, isTrue);
  });

  testWidgets('la vista lista las notificaciones', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: NotificationsView(
          notificationService: _service(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Notificaciones'), findsOneWidget);
    expect(find.text('Análisis completado'), findsOneWidget);
    expect(find.textContaining('MUESTRA-1'), findsOneWidget);
  });

  testWidgets('la vista muestra el estado vacío', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: NotificationsView(
          notificationService: _service(empty: true),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('No tienes notificaciones'), findsOneWidget);
  });
}
