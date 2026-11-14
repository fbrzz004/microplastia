
import 'dart:convert';

import '../models/pending_sample.dart';
import 'analysis_service.dart';
import 'image_storage_service.dart';
import 'local_database_service.dart';

class SyncService {
  SyncService._();

  static final SyncService instance = SyncService._();

  final AnalysisService _analysisService = AnalysisService();
  final LocalDatabaseService _database = LocalDatabaseService.instance;
  final ImageStorageService _imageStorage = ImageStorageService.instance;

  bool _isSyncing = false;

  bool get isSyncing => _isSyncing;

  /// Recupera muestras que quedaron en estado "syncing"
  /// cuando la aplicación se cerró inesperadamente.
  Future<void> recuperarSincronizacionesInterrumpidas() async {
    await _database.recoverInterruptedSyncs();
  }

  /// Envía al servidor todas las muestras pendientes.
  Future<void> sincronizarPendientes() async {
    if (_isSyncing) return;

    _isSyncing = true;

    try {
      final pendingSamples = await _database.getPendingSamples();

      for (final sample in pendingSamples) {
        await _sincronizarMuestra(sample);
      }
    } finally {
      _isSyncing = false;
    }
  }

  Future<void> _sincronizarMuestra(PendingSample sample) async {
    try {
      // Verificar que la imagen todavía exista en el dispositivo.
      final exists = await _imageStorage.imageExists(sample.imagePath);

      if (!exists) {
        await _database.markAsError(
          clientUuid: sample.clientUuid,
          error: 'No se encontró la imagen almacenada en el dispositivo.',
        );
        return;
      }

      // Marcar la muestra como en proceso.
      await _database.markAsSyncing(sample.clientUuid);

      // Leer la imagen guardada localmente.
      final bytes = await _imageStorage.readImage(sample.imagePath);

      // Enviar la muestra a FastAPI.
      final response = await _analysisService.analizarImagen(
        bytes: bytes,
        filename: sample.filename,
        sampleId: sample.sampleId,
        clientUuid: sample.clientUuid,
        isOfflineSync: true,
      );

      // Guardar la respuesta y marcar la muestra como sincronizada.
      await _database.markAsSynced(
        clientUuid: sample.clientUuid,
        resultJson: jsonEncode(response),
      );
    } catch (e) {
      // Si falla el envío, conservar la muestra para otro intento.
      await _database.markAsError(
        clientUuid: sample.clientUuid,
        error: e.toString().replaceFirst('Exception: ', ''),
      );
    }
  }
}
