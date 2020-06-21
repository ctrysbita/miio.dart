library miio;

import 'dart:convert';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:encrypt/encrypt.dart';

part 'utils.dart';

/// Represent a packet of MIIO LAN protocol.
class MiioPacket {
  /// 16 bits magic.
  static const magic = 0x2131;

  /// 16 bits length.
  int _length = 0x20;
  int get length => _length;

  /// 32 bits unknown field.
  final int unknown;

  /// 32 bits device ID.
  final int deviceId;

  /// Use unix timestamp in 32 bits stamp field.
  final int stamp;

  /// 128 bits device token.
  final BigInt _token;

  /// Variable sized payload.
  Map<String, dynamic> _payload = null;
  Uint8List _binaryPayload = null;

  /// The encrypted binary payload will be calculated while setting payload.
  Map<String, dynamic> get payload => _payload;
  set payload(Map<String, dynamic> payload) {
    _payload = payload;
    _binaryPayload = payload == null
        ? Uint8List(0)
        : _encrypt(utf8.encode(jsonEncode(_payload)));
    _length = _binaryPayload.length + 0x20;
  }

  MiioPacket(this.deviceId, this._token)
      : unknown = 0x00000000,
        stamp = DateTime.now().millisecondsSinceEpoch ~/ 1000 {
    assert(_token.bitLength <= 128);
  }

  MiioPacket.hello()
      : unknown = 0xFFFFFFFF,
        deviceId = 0xFFFFFFFF,
        stamp = DateTime.now().millisecondsSinceEpoch ~/ 1000,
        _token = BigInt.zero;

  Uint8List get binary {
    var bytes = Uint8List(length);

    // 2 bytes magic.
    bytes[0] = magic >> 8;
    bytes[1] = magic & 0xFF;

    // 2 bytes length.
    bytes[2] = length >> 8;
    bytes[3] = length & 0xFF;

    // 4 bytes unknown.
    var unknown = this.unknown;
    for (var i = 7; i >= 4; --i, unknown >>= 8) bytes[i] = unknown & 0xFF;

    // 4 bytes device ID.
    var deviceId = this.deviceId;
    for (var i = 11; i >= 8; --i, deviceId >>= 8) bytes[i] = deviceId & 0xFF;

    // 4 bytes stamp.
    var stamp = this.stamp;
    for (var i = 15; i >= 12; --i, stamp >>= 8) bytes[i] = 0xFF;

    // 16 bytes MD5.
    bytes.setAll(16, md5.convert(bytes).bytes);

    return bytes;
  }

  Uint8List _encrypt(List<int> bytes) {
    var tokenBytes = _token.toBytes(16);

    // Key = MD5(token)
    var tokenMd5 = md5.convert(tokenBytes);
    var key = Key(tokenMd5.bytes);

    // IV  = MD5(MD5(Key) + token)
    var iv = IV(md5
        .convert(
            (BigInt.parse(tokenMd5.toString(), radix: 16) + _token).toBytes())
        .bytes);

    var encrypted = AES(key, mode: AESMode.cbc).encrypt(bytes, iv: iv);

    return encrypted.bytes;
  }
}
