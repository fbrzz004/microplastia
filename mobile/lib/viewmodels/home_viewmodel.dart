import 'package:flutter/foundation.dart';
import '../models/analysis_result.dart';
import '../services/history_service.dart';

class HomeViewModel extends ChangeNotifier {
  final HistoryService _historyService;

  HomeViewModel({HistoryService? historyService})
      : _historyService = historyService ?? HistoryService();

  bool isLoading = false;
  String? errorMessage;

  List<AnalysisSummary> analisis = [];

  int get totalAnalisis => analisis.length;

  int get analisisEstaSemana {
    final ahora = DateTime.now();
    final inicioSemana = DateTime(
      ahora.year,
      ahora.month,
      ahora.day,
    ).subtract(Duration(days: ahora.weekday - 1));

    return analisis.where((item) {
      final fecha = item.createdAt?.toLocal();
      return fecha != null &&
          !fecha.isBefore(inicioSemana) &&
          !fecha.isAfter(ahora);
    }).length;
  }

  AnalysisSummary? get ultimoAnalisis =>
      analisis.isEmpty ? null : analisis.first;

  Future<void> cargarDatos() async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      // El endpoint del historial ya filtra por usuario autenticado.
      analisis = await _historyService.listar(
        limit: 100,
        offset: 0,
      );
    } catch (e) {
      errorMessage = e.toString().replaceFirst('Exception: ', '');
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _historyService.dispose();
    super.dispose();
  }
}
