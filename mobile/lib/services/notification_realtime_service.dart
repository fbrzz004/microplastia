import 'dart:async';

import 'package:web_socket_channel/web_socket_channel.dart';

import '../core/config/app_config.dart';
import 'session_service.dart';

class NotificationRealtimeService {
  WebSocketChannel? _channel;
  StreamSubscription<dynamic>? _subscription;

  Future<void> connect({
    required void Function() onNotification,
  }) async {
    final token = await SessionService.getValidToken();

    if (token == null) return;

    final uri = Uri.parse(
      AppConfig.notificationsWebSocketEndpoint,
    ).replace(
      queryParameters: {
        'token': token,
      },
    );

    try {
      final channel = WebSocketChannel.connect(uri);

      await channel.ready;

      _channel = channel;

      _subscription = channel.stream.listen(
        (_) => onNotification(),
        onError: (_) {},
        onDone: () {},
        cancelOnError: false,
      );
    } catch (_) {
      // El polling de Inicio sigue funcionando como respaldo.
    }
  }

  void dispose() {
    _subscription?.cancel();
    _channel?.sink.close();
    _subscription = null;
    _channel = null;
  }
}
