import 'package:flutter/foundation.dart';

import '../core/network/api_exception.dart';
import '../services/analysis_service.dart';

class AnalysisViewModel extends ChangeNotifier {
  final AnalysisService _service = AnalysisService();

  bool _isLoading = false;

  String? _errorMessage;

  bool _sessionExpired = false;

  Map<String, dynamic>? _resultado;

  bool get isLoading => _isLoading;

  String? get errorMessage => _errorMessage;

  bool get sessionExpired => _sessionExpired;

  Map<String, dynamic>? get resultado => _resultado;

  Future<bool> analizarImagen({
    required Uint8List bytes,
    required String filename,
  }) async {
    if (_isLoading) {
      return false;
    }

    _isLoading = true;

    _errorMessage = null;
    _resultado = null;
    _sessionExpired = false;

    notifyListeners();

    try {
      _resultado = await _service.analizarImagen(
        bytes: bytes,
        filename: filename,
      );

      return true;
    } on ApiException catch (e) {
      _errorMessage = e.message;

      _sessionExpired = e.sessionExpired;

      return false;
    } catch (_) {
      _errorMessage = 'No se pudo analizar la imagen. '
          'Inténtalo nuevamente.';

      return false;
    } finally {
      _isLoading = false;

      notifyListeners();
    }
  }

  void limpiarResultado() {
    _resultado = null;
    _errorMessage = null;
    _sessionExpired = false;

    notifyListeners();
  }
}
