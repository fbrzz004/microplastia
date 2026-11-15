import 'dart:convert';

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

  Future<void> recuperarSincronizacionesInterrumpidas() {
    return _database.recoverInterruptedSyncs();
  }

  Future<void> sincronizarPendientes() async {
    if (_isSyncing) {
      return;
    }

    _isSyncing = true;

    try {
      final pendingSamples = await _database.getPendingSamples();

      for (final sample in pendingSamples) {
        try {
          if (!await _imageStorage.imageExists(sample.imagePath)) {
            await _database.markAsError(
              clientUuid: sample.clientUuid,
              error: 'No se encontró la imagen anotada.',
            );
            continue;
          }

          final decoded = jsonDecode(sample.resultJson ?? '');

          if (decoded is! Map || decoded['data'] is! Map) {
            throw Exception('No se encontró el resultado TFLite local.');
          }

          final payload = Map<String, dynamic>.from(decoded['data'] as Map);

          await _database.markAsSyncing(sample.clientUuid);

          final bytes = await _imageStorage.readImage(sample.imagePath);

          final response = await _analysisService.guardarPayloadMovil(
            payload: payload,
            annotatedBytes: bytes,
            sampleId: sample.sampleId,
            clientUuid: sample.clientUuid,
            isOfflineSync: true,
          );

          await _database.markAsSynced(
            clientUuid: sample.clientUuid,
            resultJson: jsonEncode(response),
          );
        } catch (e) {
          await _database.markAsError(
            clientUuid: sample.clientUuid,
            error: e.toString().replaceFirst('Exception: ', ''),
          );
        }
      }
    } finally {
      _isSyncing = false;
    }
  }
}
