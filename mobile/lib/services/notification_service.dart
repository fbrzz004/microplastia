import 'package:shared_preferences/shared_preferences.dart';

import '../models/analysis_result.dart';
import '../models/app_notification.dart';
import 'history_service.dart';

class NotificationService {
  NotificationService({
    HistoryService? historyService,
  }) : _historyService = historyService ?? HistoryService();

  static const String _readIdsKey = 'notification_read_ids';
  static const int _maxNotifications = 20;

  final HistoryService _historyService;

  Future<List<AppNotification>> load({
    int limit = _maxNotifications,
  }) async {
    final analyses = await _historyService.listar(
      limit: limit,
      offset: 0,
    );

    final readIds = await _readIds();

    return build(analyses)
        .map(
          (item) => item.copyWith(
            read: readIds.contains(item.id),
          ),
        )
        .toList();
  }

  Future<void> markAllAsRead(
    Iterable<AppNotification> items,
  ) async {
    final readIds = await _readIds();

    readIds.addAll(
      items.map((item) => item.id),
    );

    await _saveReadIds(readIds);
  }

  Future<void> markAsRead(
    AppNotification item,
  ) async {
    final readIds = await _readIds();

    readIds.add(item.id);

    await _saveReadIds(readIds);
  }

  static List<AppNotification> build(
    List<AnalysisSummary> analyses,
  ) {
    final ordered = [...analyses]..sort((a, b) {
        final dateA = a.createdAt?.millisecondsSinceEpoch ?? 0;
        final dateB = b.createdAt?.millisecondsSinceEpoch ?? 0;

        return dateB.compareTo(dateA);
      });

    return ordered
        .take(_maxNotifications)
        .map(
          (analysis) => AppNotification(
            id: 'analysis-${analysis.id}',
            title: 'Análisis completado',
            message: 'Muestra ${analysis.sampleId} · '
                '${analysis.totalParticles} partículas · '
                '${analysis.confidencePercent}% de confianza',
            createdAt: analysis.createdAt,
            read: false,
            analysisId: analysis.id,
          ),
        )
        .toList();
  }

  static int unreadCount(List<AppNotification> items) {
    return items.where((item) => !item.read).length;
  }

  Future<Set<String>> _readIds() async {
    final prefs = await SharedPreferences.getInstance();

    return prefs.getStringList(_readIdsKey)?.toSet() ?? <String>{};
  }

  Future<void> _saveReadIds(
    Set<String> ids,
  ) async {
    final prefs = await SharedPreferences.getInstance();

    final ordered = ids.toList()..sort();

    await prefs.setStringList(
      _readIdsKey,
      ordered,
    );
  }

  void dispose() {
    _historyService.dispose();
  }
}
