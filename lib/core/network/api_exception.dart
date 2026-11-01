class ApiException implements Exception {
  final int? statusCode;
  final String code;
  final String message;

  const ApiException({
    this.statusCode,
    required this.code,
    required this.message,
  });

  @override
  String toString() => message;
}