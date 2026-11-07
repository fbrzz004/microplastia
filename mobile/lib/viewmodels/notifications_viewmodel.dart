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
  int unreadCount = 0;
  int total = 0;

  Future<void> load() async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      final result = await _service.load();

      items = result.items;
      unreadCount = result.unreadCount;
      total = result.total;
    } catch (error) {
      errorMessage = error.toString().replaceFirst('Exception: ', '');
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> markAllAsRead() async {
    if (items.isEmpty) return;

    try {
      await _service.markAllAsRead();

      items = items.map((item) => item.copyWith(read: true)).toList();

      unreadCount = 0;
      notifyListeners();
    } catch (error) {
      errorMessage = error.toString().replaceFirst('Exception: ', '');

      notifyListeners();
    }
  }

  Future<void> markAsRead(AppNotification item) async {
    if (item.read) return;

    try {
      await _service.markAsRead(item.id);

      items = items
          .map(
            (current) =>
                current.id == item.id ? current.copyWith(read: true) : current,
          )
          .toList();

      if (unreadCount > 0) {
        unreadCount--;
      }

      notifyListeners();
    } catch (error) {
      errorMessage = error.toString().replaceFirst('Exception: ', '');

      notifyListeners();
    }
  }

  @override
  void dispose() {
    _service.dispose();
    super.dispose();
  }
}
