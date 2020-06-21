library miio;

import 'dart:convert';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:encrypt/encrypt.dart';

part 'utils.dart';
part 'packet.dart';

class Miio {
  static void discover() {
    var packet = MiioPacket.hello();
  }
}
