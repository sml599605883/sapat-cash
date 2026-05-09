class BusinessException implements Exception {
  const BusinessException(this.message, {this.code});

  final String message;
  final int? code;

  @override
  String toString() => 'BusinessException(code: $code, message: $message)';
}
