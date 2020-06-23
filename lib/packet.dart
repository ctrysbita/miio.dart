part of 'miio.dart';

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

  /// 128 bits checksum.
  Uint8List _checksum;
  Uint8List get checksum => _checksum;

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

  MiioPacket(this.deviceId, this._token, {int stamp})
      : unknown = 0x00000000,
        stamp = stamp ?? DateTime.now().millisecondsSinceEpoch ~/ 1000 {
    assert(_token.bitLength <= 128);
  }

  /// Client hello packet.
  MiioPacket.hello()
      : unknown = 0xFFFFFFFF,
        deviceId = 0xFFFFFFFF,
        stamp = 0xFFFFFFFF,
        _token = BigInt.zero;

  /// Parse packet from response.
  factory MiioPacket.parse(Uint8List bytes, {BigInt token}) {
    var length = bytes[2] << 8 | bytes[3];

    var unknown = 0;
    for (var i = 4; i <= 7; ++i) {
      unknown <<= 8;
      unknown |= bytes[i];
    }

    var deviceId = 0;
    for (var i = 8; i <= 11; ++i) {
      deviceId <<= 8;
      deviceId |= bytes[i];
    }

    var stamp = 0;
    for (var i = 12; i <= 15; ++i) {
      stamp <<= 8;
      stamp |= bytes[i];
    }

    var checksum = bytes.sublist(16, 32);

    var packet = MiioPacket._raw(
      length,
      unknown,
      deviceId,
      stamp,
      token,
      checksum,
    ).._binaryPayload = bytes.sublist(32);

    if (token != null) {
      var decrypted = packet._decrypt(packet._binaryPayload);
      packet._payload = jsonDecode(utf8.decode(decrypted));
    }

    return packet;
  }

  MiioPacket._raw(
    this._length,
    this.unknown,
    this.deviceId,
    this.stamp,
    this._token,
    this._checksum,
  );

  /// Construct binary for packet.
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
    for (var i = 15; i >= 12; --i, stamp >>= 8) bytes[i] = stamp & 0xFF;

    // Variable sized payload.
    if (_binaryPayload != null) bytes.setAll(32, _binaryPayload);

    // Initialize checksum field with token.
    bytes.setAll(16, _token.toBytes(16));

    if (this.unknown == 0xFFFFFFFF)
      // "Hello" packet.
      for (var i = 31; i >= 16; --i) bytes[i] = 0xFF;
    else
      // 16 bytes MD5.
      bytes.setAll(16, md5.convert(bytes).bytes);

    return bytes;
  }

  Uint8List _encrypt(Uint8List bytes) {
    var tokenBytes = _token.toBytes(16);

    // Key = MD5(token)
    var tokenMd5 = md5.convert(tokenBytes);
    var key = Key(tokenMd5.bytes);

    // IV  = MD5(MD5(Key) + token)
    var iv = IV(md5.convert(tokenMd5.bytes + tokenBytes).bytes);

    var encrypted = AES(key, mode: AESMode.cbc).encrypt(bytes, iv: iv);

    return encrypted.bytes;
  }

  Uint8List _decrypt(Uint8List bytes) {
    var tokenBytes = _token.toBytes(16);

    // Key = MD5(token)
    var tokenMd5 = md5.convert(tokenBytes);
    var key = Key(tokenMd5.bytes);

    // IV  = MD5(MD5(Key) + token)
    var iv = IV(md5.convert(tokenMd5.bytes + tokenBytes).bytes);

    var decrypted =
        AES(key, mode: AESMode.cbc).decrypt(Encrypted(bytes), iv: iv);

    return decrypted;
  }

  @override
  String toString() => 'MiioPacket(len: $length, '
      'device: ${deviceId.toRadixString(16).padLeft(8, '0')}, '
      'unknown: ${unknown.toRadixString(16).padLeft(8, '0')}, '
      'stamp: ${stamp.toRadixString(16).padLeft(8, '0')} '
      'token: ${_token?.toRadixString(16)?.padLeft(32, '0')} '
      'checksum: ${checksum?.hexString})';
}
