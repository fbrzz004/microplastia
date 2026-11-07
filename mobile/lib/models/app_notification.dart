class AppNotification {
  const AppNotification({
    required this.id,
    required this.title,
    required this.message,
    required this.createdAt,
    required this.read,
    this.analysisId,
  });

  final String id;
  final String title;
  final String message;
  final DateTime? createdAt;
  final bool read;
  final int? analysisId;

  AppNotification copyWith({
    bool? read,
  }) {
    return AppNotification(
      id: id,
      title: title,
      message: message,
      createdAt: createdAt,
      read: read ?? this.read,
      analysisId: analysisId,
    );
  }
}
