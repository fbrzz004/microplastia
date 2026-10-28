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

  const AnalysisSummary({
    required this.id,
    required this.sampleId,
    required this.createdAt,
    required this.totalParticles,
    required this.confidence,
    required this.annotatedImageUrl,
  });

  factory AnalysisSummary.fromJson(Map<String, dynamic> json) {
    return AnalysisSummary(
      id: _toInt(json['id']),
      sampleId: json['sample_id']?.toString() ?? '',
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? ''),
      totalParticles: _toInt(json['total_particles']),
      confidence: _toDouble(json['confidence']),
      annotatedImageUrl: json['annotated_image_url']?.toString(),
    );
  }

  /// Confianza expresada como porcentaje entero (0–100).
  int get confidencePercent => (confidence * 100).round();
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
          .map((item) => AnalysisDetection.fromJson(
                Map<String, dynamic>.from(item),
              ))
          .toList(),
      processingTimeMs: _toDouble(json['processing_time_ms']),
    );
  }
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
