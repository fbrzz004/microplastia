import 'dart:convert';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../models/pending_sample.dart';
import '../services/analysis_service.dart';
import '../services/annotation_service.dart';
import '../services/image_storage_service.dart';
import '../services/local_database_service.dart';
import '../services/tflite_inference_service.dart';

class AnalysisViewModel extends ChangeNotifier {
  final AnalysisService _analysisService = AnalysisService();
  final TfliteInferenceService _tfliteService = TfliteInferenceService();
  final LocalDatabaseService _database = LocalDatabaseService.instance;
  final ImageStorageService _imageStorage = ImageStorageService.instance;
  final Connectivity _connectivity = Connectivity();

  bool _isLoading = false;
  bool _isOfflinePending = false;
  String? _errorMessage;
  String? _localSampleUuid;
  Map<String, dynamic>? _resultado;

  bool get isLoading => _isLoading;
  bool get isOfflinePending => _isOfflinePending;
  String? get errorMessage => _errorMessage;
  String? get localSampleUuid => _localSampleUuid;
  Map<String, dynamic>? get resultado => _resultado;

  Future<bool> analizarImagen({
    required Uint8List bytes,
    required String filename,
  }) async {
    if (_isLoading) {
      return false;
    }

    _isLoading = true;
    _isOfflinePending = false;
    _errorMessage = null;
    _resultado = null;
    notifyListeners();

    try {
      await _tfliteService.loadModel();

      final resultadoLocal = await _tfliteService.analyzeImage(bytes);

      final annotatedBytes = AnnotationService.generateAnnotatedImage(
        originalBytes: bytes,
        result: resultadoLocal,
      );

      final uuid = const Uuid().v4();
      final sampleId = 'MUESTRA-${uuid.substring(0, 8).toUpperCase()}';
      final payload = _analysisService.crearPayload(resultadoLocal);

      _localSampleUuid = uuid;

      final imagePath = await _imageStorage.saveImage(
        bytes: annotatedBytes,
        clientUuid: uuid,
        filename: 'annotated.jpg',
      );

      final now = DateTime.now();

      await _database.insertSample(
        PendingSample(
          clientUuid: uuid,
          sampleId: sampleId,
          imagePath: imagePath,
          filename: 'annotated.jpg',
          status: PendingSample.pending,
          createdAt: now,
          updatedAt: now,
          resultJson: jsonEncode({'data': payload}),
        ),
      );

      final connectivity = await _connectivity.checkConnectivity();
      final online = connectivity.any(
        (result) => result != ConnectivityResult.none,
      );

      if (!online) {
        _isOfflinePending = true;
        _errorMessage =
            'Análisis realizado localmente. Quedó pendiente de sincronización.';
        return true;
      }

      await _database.markAsSyncing(uuid);

      try {
        final response = await _analysisService.guardarAnalisisMovil(
          resultado: resultadoLocal,
          annotatedBytes: annotatedBytes,
          sampleId: sampleId,
          clientUuid: uuid,
        );

        await _database.markAsSynced(
          clientUuid: uuid,
          resultJson: jsonEncode(response),
        );

        _resultado = response;
        return true;
      } catch (_) {
        await _database.markAsError(
          clientUuid: uuid,
          error: 'Pendiente de sincronización automática.',
        );

        _isOfflinePending = true;
        _errorMessage =
            'Análisis realizado localmente. Quedó pendiente de sincronización.';
        return true;
      }
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void limpiarResultado() {
    _resultado = null;
    _errorMessage = null;
    _isOfflinePending = false;
    _localSampleUuid = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _tfliteService.close();
    super.dispose();
  }
}
