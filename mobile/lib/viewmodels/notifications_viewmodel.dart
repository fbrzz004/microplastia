import 'package:flutter/foundation.dart';

import '../models/app_notification.dart';
import '../services/notification_service.dart';

class NotificationsViewModel extends ChangeNotifier {
  NotificationsViewModel({
    NotificationService? service,
  }) : _service = service ?? NotificationService();

  final NotificationService _service;

  List<AppNotification> items = [];
  bool isLoading = false;
  String? errorMessage;

  int get unreadCount => NotificationService.unreadCount(items);

  Future<void> load() async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      items = await _service.load();
    } catch (error) {
      errorMessage = error.toString().replaceFirst('Exception: ', '');
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> markAllAsRead() async {
    if (items.isEmpty) return;

    await _service.markAllAsRead(items);

    items = items.map((item) => item.copyWith(read: true)).toList();

    notifyListeners();
  }

  Future<void> markAsRead(AppNotification item) async {
    if (item.read) return;

    await _service.markAsRead(item);

    items = items
        .map(
          (current) =>
              current.id == item.id ? current.copyWith(read: true) : current,
        )
        .toList();

    notifyListeners();
  }

  @override
  void dispose() {
    _service.dispose();
    super.dispose();
  }
}
