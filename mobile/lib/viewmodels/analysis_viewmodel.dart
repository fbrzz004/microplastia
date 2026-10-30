import 'package:flutter/foundation.dart';

import '../services/analysis_service.dart';
import '../services/annotation_service.dart';
import '../services/tflite_inference_service.dart';

class AnalysisViewModel extends ChangeNotifier {
  final AnalysisService _analysisService =
  AnalysisService();

  final TfliteInferenceService _tfliteService =
  TfliteInferenceService();

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
    if (_isLoading) {
      return false;
    }

    _isLoading = true;
    _errorMessage = null;
    _resultado = null;

    notifyListeners();

    try {
      // ================================================
      // 1. CARGAR TFLITE
      // ================================================

      await _tfliteService.loadModel();

      // ================================================
      // 2. INFERENCIA LOCAL
      // ================================================

      final resultadoLocal =
      await _tfliteService.analyzeImage(
        bytes,
      );

      debugPrint(
        '✅ Inferencia local: '
            '${resultadoLocal.totalParticles} detecciones',
      );

      // ================================================
      // 3. GENERAR IMAGEN ANOTADA
      // ================================================

      final annotatedBytes =
      AnnotationService.generateAnnotatedImage(
        originalBytes: bytes,
        result: resultadoLocal,
      );

      debugPrint(
        '✅ Imagen anotada generada: '
            '${annotatedBytes.length} bytes',
      );

      // ================================================
      // 4. GUARDAR EN BACKEND
      // ================================================

      _resultado =
      await _analysisService.guardarAnalisisMovil(
        resultado: resultadoLocal,
        annotatedBytes: annotatedBytes,
      );

      debugPrint(
        '✅ Resultado guardado en backend',
      );

      return true;
    } catch (e) {
      debugPrint(
        '❌ Error durante análisis móvil: $e',
      );

      _errorMessage = e
          .toString()
          .replaceFirst(
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

  @override
  void dispose() {
    _tfliteService.close();

    super.dispose();
  }
}