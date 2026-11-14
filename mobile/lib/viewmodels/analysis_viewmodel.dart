
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

import '../models/pending_sample.dart';
import '../services/analysis_service.dart';
import '../services/image_storage_service.dart';
import '../services/local_database_service.dart';

class AnalysisViewModel extends ChangeNotifier {
  final AnalysisService _service = AnalysisService();

  final LocalDatabaseService _database =
      LocalDatabaseService.instance;

  final ImageStorageService _imageStorage =
      ImageStorageService.instance;

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
    if (_isLoading) return false;

    _isLoading = true;
    _isOfflinePending = false;
    _errorMessage = null;
    _resultado = null;
    _localSampleUuid = null;

    notifyListeners();

    String? savedImagePath;
    String? generatedUuid;

    try {
      // 1. Generar identificadores únicos.
      generatedUuid = const Uuid().v4();

      final sampleId =
          'MUESTRA-${generatedUuid.substring(0, 8).toUpperCase()}';

      _localSampleUuid = generatedUuid;

      // 2. Guardar la fotografía permanentemente.
      savedImagePath = await _imageStorage.saveImage(
        bytes: bytes,
        clientUuid: generatedUuid,
        filename: filename,
      );

      // 3. Registrar la muestra localmente ANTES de enviarla.
      final now = DateTime.now();

      final sample = PendingSample(
        clientUuid: generatedUuid,
        sampleId: sampleId,
        imagePath: savedImagePath,
        filename: filename,
        status: PendingSample.pending,
        createdAt: now,
        updatedAt: now,
      );

      await _database.insertSample(sample);

      // 4. Comprobar si existe una conexión de red.
      final connectivityResults =
          await _connectivity.checkConnectivity();

      final hasNetwork = connectivityResults.any(
        (result) => result != ConnectivityResult.none,
      );

      if (!hasNetwork) {
        _isOfflinePending = true;
        _errorMessage =
            'La muestra se guardó en el dispositivo. '
            'Se enviará cuando recuperes la conexión.';

        return true;
      }

      // 5. Marcar como enviándose.
      await _database.markAsSyncing(generatedUuid);

      try {
        // 6. Enviar la imagen al backend.
        final imageBytes = await _imageStorage.readImage(
          savedImagePath,
        );

        final response = await _service.analizarImagen(
          bytes: imageBytes,
          filename: filename,
          sampleId: sampleId,
          clientUuid: generatedUuid,
          isOfflineSync: false,
        );

        // 7. Guardar la respuesta y confirmar sincronización.
        await _database.markAsSynced(
          clientUuid: generatedUuid,
          resultJson: jsonEncode(response),
        );

        _resultado = response;
        _isOfflinePending = false;

        return true;
      } catch (e) {
        // La imagen y el registro permanecen guardados.
        await _database.markAsError(
          clientUuid: generatedUuid,
          error: _cleanError(e),
        );

        _isOfflinePending = true;
        _errorMessage =
            'La muestra quedó guardada y pendiente de envío. '
            '${_cleanError(e)}';

        return true;
      }
    } catch (e) {
      // Si se guardó la imagen pero falló el registro,
      // intentamos eliminar el archivo para no dejarlo huérfano.
      if (savedImagePath != null && generatedUuid != null) {
        final sample = await _database.getSampleByUuid(generatedUuid);

        if (sample == null) {
          await _imageStorage.deleteImage(savedImagePath);
        }
      }

      _errorMessage = _cleanError(e);
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  String _cleanError(Object error) {
    return error.toString().replaceFirst('Exception: ', '');
  }

  void limpiarResultado() {
    _resultado = null;
    _errorMessage = null;
    _isOfflinePending = false;
    _localSampleUuid = null;

    notifyListeners();
  }
}

