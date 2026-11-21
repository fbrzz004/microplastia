class PendingSample {
  final int? id;
  final String clientUuid;
  final String sampleId;
  final String imagePath;
  final String? originalImagePath;
  final String filename;
  final String status;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int attempts;
  final String? lastError;
  final String? resultJson;

  const PendingSample({
    this.id,
    required this.clientUuid,
    required this.sampleId,
    required this.imagePath,
    this.originalImagePath,
    required this.filename,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.attempts = 0,
    this.lastError,
    this.resultJson,
  });

  static const String pending = 'pending';
  static const String syncing = 'syncing';
  static const String synced = 'synced';
  static const String error = 'error';

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'client_uuid': clientUuid,
      'sample_id': sampleId,
      'image_path': imagePath,
      'original_image_path': originalImagePath,
      'filename': filename,
      'status': status,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'attempts': attempts,
      'last_error': lastError,
      'result_json': resultJson,
    };
  }

  factory PendingSample.fromMap(Map<String, dynamic> map) {
    return PendingSample(
      id: map['id'] as int?,
      clientUuid: map['client_uuid'] as String,
      sampleId: map['sample_id'] as String,
      imagePath: map['image_path'] as String,
      originalImagePath: map['original_image_path'] as String?,
      filename: map['filename'] as String,
      status: map['status'] as String,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
      attempts: (map['attempts'] as int?) ?? 0,
      lastError: map['last_error'] as String?,
      resultJson: map['result_json'] as String?,
    );
  }
}
