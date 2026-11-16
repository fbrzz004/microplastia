import 'package:flutter/foundation.dart';

import '../core/network/api_exception.dart';
import '../models/analysis_result.dart';
import '../services/history_service.dart';

class HistoryDetailViewModel extends ChangeNotifier {
  HistoryDetailViewModel({
    HistoryService? historyService,
  }) : _historyService = historyService ?? HistoryService();

  final HistoryService _historyService;

  AnalysisDetail? detalle;

  bool isLoading = false;
  String? errorMessage;
  bool sessionExpired = false;

  int? selectedClassId;

  bool get canFilter =>
      detalle?.originalImageUrl != null &&
      detalle!.originalImageUrl!.trim().isNotEmpty;

  List<AnalysisDetection> get deteccionesFiltradas {
    final actual = detalle;

    if (actual == null) {
      return const [];
    }

    if (selectedClassId == null) {
      return actual.detections;
    }

    return actual.detections
        .where(
          (detection) => detection.classId == selectedClassId,
        )
        .toList();
  }

  void seleccionarClase(
    int? classId,
  ) {
    if (!canFilter && classId != null) {
      return;
    }

    selectedClassId = classId;

    notifyListeners();
  }

  int contarClase(int classId) {
    return detalle?.detections
            .where(
              (detection) => detection.classId == classId,
            )
            .length ??
        0;
  }

  Future<void> cargar(
    int resultId,
  ) async {
    isLoading = true;
    errorMessage = null;
    sessionExpired = false;
    selectedClassId = null;

    notifyListeners();

    try {
      detalle = await _historyService.obtener(resultId);
    } on ApiException catch (e) {
      detalle = null;

      errorMessage = e.message;

      sessionExpired = e.sessionExpired;
    } catch (_) {
      detalle = null;

      errorMessage = 'No se pudo cargar '
          'el detalle del análisis.';
    } finally {
      isLoading = false;

      notifyListeners();
    }
  }

  Future<void> reintentar(
    int resultId,
  ) =>
      cargar(resultId);

  @override
  void dispose() {
    _historyService.dispose();

    super.dispose();
  }
}
