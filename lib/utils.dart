part of 'miio.dart';

extension ToBytes on BigInt {
  Uint8List toBytes([int length]) {
    if (length == null) length = bitLength ~/ 8;

    var number = this;
    final bytes = ByteData(length);

    for (var i = 1; i <= bytes.lengthInBytes; ++i, number >>= 8)
      bytes.setUint8(bytes.lengthInBytes - i, number.toUnsigned(8).toInt());

    return bytes.buffer.asUint8List();
  }
}
