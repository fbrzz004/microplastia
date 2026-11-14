
import 'package:flutter/foundation.dart';

import '../models/analysis_result.dart';
import '../services/history_service.dart';
import '../services/local_database_service.dart';

class HistoryDetailViewModel extends ChangeNotifier {
  HistoryDetailViewModel({
    HistoryService? historyService,
    LocalDatabaseService? localDatabase,
  })  : _historyService = historyService ?? HistoryService(),
        _localDatabase = localDatabase ?? LocalDatabaseService.instance;

  final HistoryService _historyService;
  final LocalDatabaseService _localDatabase;

  AnalysisDetail? detalle;

  bool isLoading = false;
  String? errorMessage;

  // Identifica el tipo de consulta actual para poder reintentarla.
  int? _currentResultId;
  String? _currentClientUuid;

  /// Obtiene el detalle de una muestra almacenada en el servidor.
  Future<void> cargar(int resultId) async {
    _currentResultId = resultId;
    _currentClientUuid = null;

    isLoading = true;
    errorMessage = null;
    detalle = null;
    notifyListeners();

    try {
      detalle = await _historyService.obtener(resultId);
    } catch (e) {
      errorMessage = e.toString().replaceFirst('Exception: ', '');
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  /// Obtiene el detalle de una muestra almacenada localmente.
  Future<void> cargarLocal(String clientUuid) async {
    _currentClientUuid = clientUuid;
    _currentResultId = null;

    isLoading = true;
    errorMessage = null;
    detalle = null;
    notifyListeners();

    try {
      final muestra = await _localDatabase.getSampleByUuid(clientUuid);

      if (muestra == null) {
        throw Exception(
          'No se encontró la muestra almacenada en este dispositivo.',
        );
      }

      detalle = AnalysisDetail.fromPendingSample(muestra);
    } catch (e) {
      errorMessage = e.toString().replaceFirst('Exception: ', '');
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  /// Reintenta la última consulta realizada.
  Future<void> reintentar() async {
    if (_currentClientUuid != null) {
      await cargarLocal(_currentClientUuid!);
      return;
    }

    if (_currentResultId != null) {
      await cargar(_currentResultId!);
    }
  }

  @override
  void dispose() {
    _historyService.dispose();
    super.dispose();
  }
}
