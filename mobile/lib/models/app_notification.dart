class AppNotification {
  const AppNotification({
    required this.id,
    required this.type,
    required this.title,
    required this.message,
    required this.createdAt,
    required this.read,
    this.resultId,
  });

  final int id;
  final String type;
  final String title;
  final String message;
  final DateTime? createdAt;
  final bool read;
  final int? resultId;

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      id: _toInt(json['id']),
      type: json['type']?.toString() ?? 'analysis',
      title: json['title']?.toString() ?? '',
      message: json['message']?.toString() ?? '',
      createdAt: DateTime.tryParse(
        json['created_at']?.toString() ?? '',
      ),
      read: json['is_read'] == true,
      resultId: _toNullableInt(json['result_id']),
    );
  }

  AppNotification copyWith({
    bool? read,
  }) {
    return AppNotification(
      id: id,
      type: type,
      title: title,
      message: message,
      createdAt: createdAt,
      read: read ?? this.read,
      resultId: resultId,
    );
  }
}

int _toInt(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.round();
  return int.tryParse(value?.toString() ?? '') ?? 0;
}

int? _toNullableInt(dynamic value) {
  if (value == null) return null;
  if (value is int) return value;
  if (value is num) return value.round();
  return int.tryParse(value.toString());
}
