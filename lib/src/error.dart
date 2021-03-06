/// Represent an error received from MIIO device.
class MiioError implements Exception {
  final int code;
  final String message;

  MiioError({
    required this.code,
    required this.message,
  });

  @override
  String toString() => 'MiioError(code: $code, message: $message)';
}
