import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import '../services/analysis_service.dart';

class AnalysisViewModel extends ChangeNotifier {
  final AnalysisService _service = AnalysisService();

  bool _isLoading = false;
  String? _errorMessage;
  Map<String, dynamic>? _resultado;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  Map<String, dynamic>? get resultado => _resultado;

  Future<bool> analizarImagen({
    required Uint8List bytes,
    required String filename,
  }) async {
    if (_isLoading) return false;

    _isLoading = true;
    _errorMessage = null;
    _resultado = null;
    notifyListeners();

    try {
      _resultado = await _service.analizarImagen(
        bytes: bytes,
        filename: filename,
      );

      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst(
        'Exception: ',
        '',
      );

      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void limpiarResultado() {
    _resultado = null;
    _errorMessage = null;
    notifyListeners();
  }
}
