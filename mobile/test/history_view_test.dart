import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:mobile/models/analysis_result.dart';
import 'package:mobile/services/history_service.dart';
import 'package:mobile/viewmodels/history_viewmodel.dart';
import 'package:mobile/views/history_view.dart';

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

Widget _buildView(HistoryService service) {
  return ChangeNotifierProvider(
    create: (_) => HistoryViewModel(service: service),
    child: const MaterialApp(
      home: HistoryView(),
    ),
  );
}

void main() {
  testWidgets('El historial muestra el estado vacío', (tester) async {
    await tester.pumpWidget(_buildView(_FakeHistoryService(const [])));
    await tester.pumpAndSettle();

    expect(find.textContaining('Todavía no hay análisis'), findsOneWidget);
  });

  testWidgets('El historial lista los análisis guardados', (tester) async {
    final items = [
      AnalysisSummary(
        id: 12,
        sampleId: 'MUESTRA-AB12CD34',
        createdAt: DateTime(2026, 10, 22, 14, 30),
        totalParticles: 14,
        confidence: 0.87,
        annotatedImageUrl: '/static/detections/annotated.jpg',
      ),
    ];

    await tester.pumpWidget(_buildView(_FakeHistoryService(items)));
    await tester.pumpAndSettle();

    expect(find.text('MUESTRA-AB12CD34'), findsOneWidget);
    expect(find.textContaining('14 partículas'), findsOneWidget);
    expect(find.text('87%'), findsOneWidget);
  });
}
