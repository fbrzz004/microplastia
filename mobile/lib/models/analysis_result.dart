
import 'dart:convert';

import 'pending_sample.dart';

class AnalysisDetection {
  final int classId;
  final String className;
  final double confidence;
  final List<double> box;

  const AnalysisDetection({
    required this.classId,
    required this.className,
    required this.confidence,
    required this.box,
  });

  factory AnalysisDetection.fromJson(Map<String, dynamic> json) {
    return AnalysisDetection(
      classId: _toInt(json['class_id']),
      className: json['class_name']?.toString() ?? '',
      confidence: _toDouble(json['confidence']),
      box: (json['box'] as List? ?? const [])
          .map((value) => _toDouble(value))
          .toList(),
    );
  }
}

class AnalysisSummary {
  final int id;
  final String sampleId;
  final DateTime? createdAt;
  final int totalParticles;
  final double confidence;
  final String? annotatedImageUrl;

  // Información adicional para muestras locales.
  final bool isLocal;
  final String? clientUuid;
  final String? localImagePath;
  final String? syncStatus;

  const AnalysisSummary({
    required this.id,
    required this.sampleId,
    required this.createdAt,
    required this.totalParticles,
    required this.confidence,
    required this.annotatedImageUrl,
    this.isLocal = false,
    this.clientUuid,
    this.localImagePath,
    this.syncStatus,
  });

  factory AnalysisSummary.fromJson(Map<String, dynamic> json) {
    return AnalysisSummary(
      id: _toInt(json['id']),
      sampleId: json['sample_id']?.toString() ?? '',
      createdAt: DateTime.tryParse(
        json['created_at']?.toString() ?? '',
      ),
      totalParticles: _toInt(json['total_particles']),
      confidence: _toDouble(json['confidence']),
      annotatedImageUrl: json['annotated_image_url']?.toString(),
    );
  }

  factory AnalysisSummary.fromPendingSample(PendingSample sample) {
    final resultData = _extractResultData(sample.resultJson);

    final serverId = _toInt(resultData['result_id']);

    return AnalysisSummary(
      id: sample.status == PendingSample.synced && serverId > 0
          ? serverId
          : -(sample.id ?? 1),
      sampleId: sample.sampleId,
      createdAt: sample.createdAt,
      totalParticles: _toInt(resultData['total_particles']),
      confidence: _toDouble(resultData['confidence']),
      annotatedImageUrl: resultData['annotated_image_url']?.toString(),
      isLocal: true,
      clientUuid: sample.clientUuid,
      localImagePath: sample.imagePath,
      syncStatus: sample.status,
    );
  }

  int get confidencePercent => (confidence * 100).round();

  bool get isSynced => syncStatus == PendingSample.synced;

  // Las muestras locales también pueden abrirse.
  bool get canOpenDetail => isLocal
      ? clientUuid != null
      : id > 0;

  // Solo los resultados disponibles en el servidor
  // pueden seleccionarse para operaciones que requieren un ID remoto.
  bool get canSelectForReport => !isLocal || (isSynced && id > 0);
}

class AnalysisDetail extends AnalysisSummary {
  final Map<String, int> breakdown;
  final List<AnalysisDetection> detections;
  final double processingTimeMs;

  const AnalysisDetail({
    required super.id,
    required super.sampleId,
    required super.createdAt,
    required super.totalParticles,
    required super.confidence,
    required super.annotatedImageUrl,
    super.isLocal,
    super.clientUuid,
    super.localImagePath,
    super.syncStatus,
    required this.breakdown,
    required this.detections,
    required this.processingTimeMs,
  });

  factory AnalysisDetail.fromJson(Map<String, dynamic> json) {
    final summary = AnalysisSummary.fromJson(json);

    return AnalysisDetail(
      id: summary.id,
      sampleId: summary.sampleId,
      createdAt: summary.createdAt,
      totalParticles: summary.totalParticles,
      confidence: summary.confidence,
      annotatedImageUrl: summary.annotatedImageUrl,
      breakdown: (json['breakdown'] as Map? ?? const {}).map(
        (key, value) => MapEntry(key.toString(), _toInt(value)),
      ),
      detections: (json['detections'] as List? ?? const [])
          .whereType<Map>()
          .map(
            (item) => AnalysisDetection.fromJson(
              Map<String, dynamic>.from(item),
            ),
          )
          .toList(),
      processingTimeMs: _toDouble(json['processing_time_ms']),
    );
  }

  /// Construye el detalle desde una muestra almacenada en SQLite.
  factory AnalysisDetail.fromPendingSample(PendingSample sample) {
    final resultData = _extractResultData(sample.resultJson);
    final summary = AnalysisSummary.fromPendingSample(sample);

    return AnalysisDetail(
      id: summary.id,
      sampleId: summary.sampleId,
      createdAt: summary.createdAt,
      totalParticles: summary.totalParticles,
      confidence: summary.confidence,
      annotatedImageUrl: summary.annotatedImageUrl,
      isLocal: true,
      clientUuid: summary.clientUuid,
      localImagePath: summary.localImagePath,
      syncStatus: summary.syncStatus,
      breakdown: (resultData['breakdown'] as Map? ?? const {}).map(
        (key, value) => MapEntry(key.toString(), _toInt(value)),
      ),
      detections: (resultData['detections'] as List? ?? const [])
          .whereType<Map>()
          .map(
            (item) => AnalysisDetection.fromJson(
              Map<String, dynamic>.from(item),
            ),
          )
          .toList(),
      processingTimeMs: _toDouble(resultData['processing_time_ms']),
    );
  }
}

Map<String, dynamic> _extractResultData(String? resultJson) {
  if (resultJson == null || resultJson.isEmpty) {
    return {};
  }

  try {
    final decoded = jsonDecode(resultJson);

    if (decoded is Map) {
      final data = decoded['data'];

      if (data is Map) {
        return Map<String, dynamic>.from(data);
      }
    }
  } catch (_) {
    // Se conservan los datos básicos de la muestra local.
  }

  return {};
}

int _toInt(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.round();
  return int.tryParse(value?.toString() ?? '') ?? 0;
}

double _toDouble(dynamic value) {
  if (value is double) return value;
  if (value is num) return value.toDouble();
  return double.tryParse(value?.toString() ?? '') ?? 0;
}
