/// Represent an error received from MiIO device.
class MiIOError implements Exception {
  final int code;
  final String message;

  MiIOError({
    required this.code,
    required this.message,
  });

  @override
  String toString() => 'MiIOError(code: $code, message: $message)';
}
