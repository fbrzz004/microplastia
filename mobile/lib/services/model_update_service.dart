import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/config/app_config.dart';

class ModelMetadata {
  final int idModelo;

  final String nombre;
  final String version;

  final String? storagePath;
  final String? downloadUrl;

  final String? sha256;

  final int inputSize;
  final List<int> outputShape;

  final Map<int, String> clases;

  final double confidenceThreshold;
  final double iouThreshold;

  final String? minAppVersion;

  const ModelMetadata({
    required this.idModelo,
    required this.nombre,
    required this.version,
    required this.storagePath,
    required this.downloadUrl,
    required this.sha256,
    required this.inputSize,
    required this.outputShape,
    required this.clases,
    required this.confidenceThreshold,
    required this.iouThreshold,
    required this.minAppVersion,
  });

  factory ModelMetadata.fromJson(
    Map<String, dynamic> json,
  ) {
    final rawOutputShape =
        (json['output_shape'] as List<dynamic>? ?? const <dynamic>[]);

    final rawClasses =
        (json['clases'] as Map<String, dynamic>? ?? const <String, dynamic>{});

    return ModelMetadata(
      idModelo: json['id_modelo'] as int,
      nombre: json['nombre'] as String,
      version: json['version'] as String,
      storagePath: json['storage_path'] as String?,
      downloadUrl: json['download_url'] as String?,
      sha256: json['sha256'] as String?,
      inputSize: json['input_size'] as int,
      outputShape: rawOutputShape
          .map(
            (value) => (value as num).toInt(),
          )
          .toList(),
      clases: rawClasses.map(
        (key, value) => MapEntry(
          int.parse(key),
          value.toString(),
        ),
      ),
      confidenceThreshold: (json['confidence_threshold'] as num).toDouble(),
      iouThreshold: (json['iou_threshold'] as num).toDouble(),
      minAppVersion: json['min_app_version'] as String?,
    );
  }
}

class ModelUpdateResult {
  final ModelMetadata metadata;

  final String? localModelPath;

  final bool downloaded;

  const ModelUpdateResult({
    required this.metadata,
    required this.localModelPath,
    required this.downloaded,
  });
}

class ModelUpdateService {
  static const String _versionKey = 'installed_model_version';

  static const String _pathKey = 'installed_model_path';

  static const String _shaKey = 'installed_model_sha256';

  Future<ModelMetadata> fetchLatestModel() async {
    final uri = Uri.parse(
      AppConfig.latestModelEndpoint,
    );

    final response = await http.get(uri).timeout(
          AppConfig.requestTimeout,
        );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        'No se pudo consultar el modelo activo. '
        'HTTP ${response.statusCode}',
      );
    }

    final decoded = jsonDecode(
      response.body,
    );

    if (decoded is! Map<String, dynamic>) {
      throw Exception(
        'Respuesta inválida del servidor.',
      );
    }

    return ModelMetadata.fromJson(
      decoded,
    );
  }

  Future<String?> getInstalledVersion() async {
    final prefs = await SharedPreferences.getInstance();

    return prefs.getString(
      _versionKey,
    );
  }

  Future<String?> getInstalledModelPath() async {
    final prefs = await SharedPreferences.getInstance();

    final path = prefs.getString(
      _pathKey,
    );

    if (path == null || path.trim().isEmpty) {
      return null;
    }

    final file = File(
      path,
    );

    if (!await file.exists()) {
      return null;
    }

    return path;
  }

  Future<ModelUpdateResult> checkForUpdate() async {
    final metadata = await fetchLatestModel();

    final installedVersion = await getInstalledVersion();

    final installedPath = await getInstalledModelPath();

    debugPrint(
      '🤖 Modelo remoto: '
      '${metadata.nombre} '
      'v${metadata.version}',
    );

    debugPrint(
      '🤖 Versión instalada: '
      '${installedVersion ?? "asset base"}',
    );

    // ==========================================
    // YA TENEMOS ESA VERSIÓN DESCARGADA
    // ==========================================

    if (installedVersion == metadata.version && installedPath != null) {
      final valid = await _verifyFile(
        filePath: installedPath,
        expectedSha256: metadata.sha256,
      );

      if (valid) {
        debugPrint(
          '✅ Modelo descargado vigente '
          'y SHA256 válido.',
        );

        return ModelUpdateResult(
          metadata: metadata,
          localModelPath: installedPath,
          downloaded: false,
        );
      }

      debugPrint(
        '⚠️ El modelo local no pasó '
        'la verificación SHA256.',
      );
    }

    // ==========================================
    // TODAVÍA NO HAY URL DE DESCARGA
    // ==========================================

    final downloadUrl = metadata.downloadUrl;

    if (downloadUrl == null || downloadUrl.trim().isEmpty) {
      debugPrint(
        'ℹ️ El servidor no proporcionó '
        'download_url.',
      );

      return ModelUpdateResult(
        metadata: metadata,
        localModelPath: null,
        downloaded: false,
      );
    }

    // ==========================================
    // DESCARGAR MODELO
    // ==========================================

    final localPath = await _downloadModel(
      metadata,
    );

    return ModelUpdateResult(
      metadata: metadata,
      localModelPath: localPath,
      downloaded: true,
    );
  }

  Future<String> _downloadModel(
    ModelMetadata metadata,
  ) async {
    final url = metadata.downloadUrl;

    if (url == null) {
      throw Exception(
        'El modelo no tiene URL '
        'de descarga.',
      );
    }

    debugPrint(
      '⬇️ Descargando modelo '
      'v${metadata.version}...',
    );

    final response = await http
        .get(
          Uri.parse(url),
        )
        .timeout(
          const Duration(
            seconds: 60,
          ),
        );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        'Error al descargar modelo. '
        'HTTP ${response.statusCode}',
      );
    }

    // ==========================================
    // VERIFICAR SHA256 ANTES DE GUARDAR
    // ==========================================

    final receivedHash = sha256
        .convert(
          response.bodyBytes,
        )
        .toString()
        .toUpperCase();

    final expectedHash = (metadata.sha256 ?? '').trim().toUpperCase();

    if (expectedHash.isNotEmpty && receivedHash != expectedHash) {
      throw Exception(
        'El SHA256 del modelo descargado '
        'no coincide con el registrado.',
      );
    }

    // ==========================================
    // ALMACENAMIENTO PRIVADO DE LA APP
    // ==========================================

    final directory = await getApplicationSupportDirectory();

    final modelsDirectory = Directory(
      '${directory.path}'
      '${Platform.pathSeparator}'
      'models',
    );

    if (!await modelsDirectory.exists()) {
      await modelsDirectory.create(
        recursive: true,
      );
    }

    final safeVersion = metadata.version.replaceAll(
      RegExp(
        r'[^a-zA-Z0-9._-]',
      ),
      '_',
    );

    final filePath = '${modelsDirectory.path}'
        '${Platform.pathSeparator}'
        'best_$safeVersion.tflite';

    final file = File(
      filePath,
    );

    await file.writeAsBytes(
      response.bodyBytes,
      flush: true,
    );

    // ==========================================
    // VERIFICAR ARCHIVO GUARDADO
    // ==========================================

    final valid = await _verifyFile(
      filePath: filePath,
      expectedSha256: metadata.sha256,
    );

    if (!valid) {
      if (await file.exists()) {
        await file.delete();
      }

      throw Exception(
        'El archivo TFLite guardado '
        'no superó la verificación.',
      );
    }

    // ==========================================
    // GUARDAR METADATOS LOCALES
    // ==========================================

    final prefs = await SharedPreferences.getInstance();

    await prefs.setString(
      _versionKey,
      metadata.version,
    );

    await prefs.setString(
      _pathKey,
      filePath,
    );

    if (metadata.sha256 != null) {
      await prefs.setString(
        _shaKey,
        metadata.sha256!,
      );
    }

    debugPrint(
      '✅ Modelo v${metadata.version} '
      'guardado en: $filePath',
    );

    return filePath;
  }

  Future<bool> _verifyFile({
    required String filePath,
    required String? expectedSha256,
  }) async {
    if (expectedSha256 == null || expectedSha256.trim().isEmpty) {
      return false;
    }

    final file = File(
      filePath,
    );

    if (!await file.exists()) {
      return false;
    }

    final bytes = await file.readAsBytes();

    final hash = sha256.convert(bytes).toString().toUpperCase();

    return hash == expectedSha256.trim().toUpperCase();
  }
}
