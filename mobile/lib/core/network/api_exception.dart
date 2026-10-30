class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final bool sessionExpired;

  const ApiException({
    required this.message,
    this.statusCode,
    this.sessionExpired = false,
  });

  @override
  String toString() => message;
}
