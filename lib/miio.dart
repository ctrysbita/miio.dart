library miio;

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:encrypt/encrypt.dart';
import 'package:tuple/tuple.dart';

part 'utils.dart';
part 'packet.dart';

class Miio {
  /// Send discovery packet to [ip].
  /// [callback] will be invoked while receiving a response.
  static void discover(
    String ip,
    Function(Tuple2<InternetAddress, MiioPacket>) callback, {
    Duration timeout = const Duration(seconds: 3),
  }) async {
    var udpSocket =
        await RawDatagramSocket.bind(InternetAddress.anyIPv4, 54321);
    var broadcast = udpSocket.asBroadcastStream();

    var subscription = broadcast.listen((event) {
      if (event != RawSocketEvent.read) return;
      Datagram dg = udpSocket.receive();
      callback(Tuple2(dg.address, MiioPacket.parse(dg.data)));
    });
    Timer(timeout, () {
      subscription.cancel();
      udpSocket.close();
    });

    udpSocket.send(
        MiioPacket.hello().binary, InternetAddress.tryParse(ip), 54321);
  }
}
