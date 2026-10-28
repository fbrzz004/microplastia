import 'package:flutter/foundation.dart';
import '../models/analysis_result.dart';
import '../services/history_service.dart';

class HistoryDetailViewModel extends ChangeNotifier {
  HistoryDetailViewModel({HistoryService? historyService})
      : _historyService = historyService ?? HistoryService();

  final HistoryService _historyService;

  AnalysisDetail? detalle;
  bool isLoading = false;
  String? errorMessage;

  Future<void> cargar(int resultId) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      detalle = await _historyService.obtener(resultId);
    } catch (e) {
      detalle = null;
      errorMessage = e.toString().replaceFirst('Exception: ', '');
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> reintentar(int resultId) => cargar(resultId);

  @override
  void dispose() {
    _historyService.dispose();
    super.dispose();
  }
}
