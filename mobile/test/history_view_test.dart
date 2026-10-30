import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:mobile/models/analysis_result.dart';
import 'package:mobile/services/history_service.dart';
import 'package:mobile/services/report_service.dart';
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

class _FakeReportService extends ReportService {
  List<int>? receivedIds;

  @override
  Future<ReportResult> generate(List<int> resultIds) async {
    receivedIds = resultIds;

    return const ReportResult(
      filename: 'reporte_1.pdf',
      reportUrl: '/static/reports/reporte_1.pdf',
      totalAnalyses: 1,
    );
  }
}

Widget _buildView(
  HistoryService service, {
  ReportService? reportService,
}) {
  return ChangeNotifierProvider(
    create: (_) => HistoryViewModel(
      service: service,
      reportService: reportService,
    ),
    child: const MaterialApp(
      home: HistoryView(),
    ),
  );
}

List<AnalysisSummary> _items() {
  return [
    AnalysisSummary(
      id: 12,
      sampleId: 'MUESTRA-AB12CD34',
      createdAt: DateTime(2026, 10, 22, 14, 30),
      totalParticles: 14,
      confidence: 0.87,
      annotatedImageUrl: '/static/detections/annotated.jpg',
    ),
  ];
}

void main() {
  testWidgets('El historial muestra el estado vacío', (tester) async {
    await tester.pumpWidget(_buildView(_FakeHistoryService(const [])));
    await tester.pumpAndSettle();

    expect(find.textContaining('Todavía no hay análisis'), findsOneWidget);
  });

  testWidgets('El historial lista los análisis guardados', (tester) async {
    await tester.pumpWidget(_buildView(_FakeHistoryService(_items())));
    await tester.pumpAndSettle();

    expect(find.text('MUESTRA-AB12CD34'), findsOneWidget);
    expect(find.textContaining('14 partículas'), findsOneWidget);
    expect(find.text('87%'), findsOneWidget);
  });

  testWidgets('El botón de reporte envía los análisis seleccionados',
      (tester) async {
    final reportService = _FakeReportService();

    await tester.pumpWidget(
      _buildView(
        _FakeHistoryService(_items()),
        reportService: reportService,
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byType(Checkbox));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Generar reporte (1)'));
    await tester.pumpAndSettle();

    expect(reportService.receivedIds, [12]);
    expect(find.text('Reporte generado'), findsOneWidget);
  });
}
