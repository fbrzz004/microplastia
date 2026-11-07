import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:mobile/models/analysis_result.dart';
import 'package:mobile/services/history_service.dart';
import 'package:mobile/services/notification_service.dart';
import 'package:mobile/views/notifications_view.dart';

class _FakeHistoryService extends HistoryService {
  _FakeHistoryService(this.items);

  final List<AnalysisSummary> items;

  @override
  Future<List<AnalysisSummary>> listar({
    String? query,
    int limit = 50,
    int offset = 0,
  }) async {
    return items;
  }
}

List<AnalysisSummary> _analyses() {
  return [
    AnalysisSummary(
      id: 1,
      sampleId: 'MUESTRA-ANTIGUA',
      createdAt: DateTime(2026, 11, 5, 10),
      totalParticles: 10,
      confidence: 0.9,
      annotatedImageUrl: null,
    ),
    AnalysisSummary(
      id: 2,
      sampleId: 'MUESTRA-RECIENTE',
      createdAt: DateTime(2026, 11, 6, 10),
      totalParticles: 20,
      confidence: 0.8,
      annotatedImageUrl: null,
    ),
  ];
}

NotificationService _service() {
  return NotificationService(
    historyService: _FakeHistoryService(_analyses()),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('crea una notificación por análisis, de más reciente a más antiguo',
      () async {
    final service = _service();

    final items = await service.load();

    expect(items.length, 2);
    expect(items.first.message, contains('MUESTRA-RECIENTE'));
    expect(items.first.message, contains('20 partículas'));
    expect(items.last.message, contains('MUESTRA-ANTIGUA'));
    expect(NotificationService.unreadCount(items), 2);
  });

  test('conserva las notificaciones leídas entre cargas', () async {
    final service = _service();

    final items = await service.load();
    await service.markAllAsRead(items);

    final reloaded = await service.load();

    expect(NotificationService.unreadCount(reloaded), 0);
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
    expect(find.text('Análisis completado'), findsNWidgets(2));
    expect(find.textContaining('MUESTRA-RECIENTE'), findsOneWidget);
  });

  testWidgets('la vista muestra el estado vacío', (tester) async {
    final service = NotificationService(
      historyService: _FakeHistoryService(const []),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: NotificationsView(
          notificationService: service,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('No tienes notificaciones'), findsOneWidget);
  });
}
