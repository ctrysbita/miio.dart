/*
Copyright (C) 2020 Jason C.H

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see <http://www.gnu.org/licenses/>.
*/

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

/// MIIO LAN protocol.
class Miio {
  static Miio _instance;
  static Miio get instance {
    assert(_instance != null, 'Miio not initialized yet.');
    return _instance;
  }

  final RawDatagramSocket _socket;
  final Stream<RawSocketEvent> _broadcast;

  Miio._(RawDatagramSocket socket)
      : _socket = socket,
        _broadcast = socket.asBroadcastStream();

  static Future<Miio> init() async {
    if (_instance != null) return _instance;

    _instance =
        Miio._(await RawDatagramSocket.bind(InternetAddress.anyIPv4, 54321));
    return _instance;
  }

  /// Close socket.
  ///
  /// Miio should be re-initialized before next usage.
  void close() {
    _socket.close();
    _instance = null;
  }

  /// Send discovery packet to [ip].
  /// [callback] will be invoked while receiving a response.
  Future<void> discover(
    String ip,
    Function(Tuple2<InternetAddress, MiioPacket>) callback, {
    Duration timeout = const Duration(seconds: 3),
  }) async {
    var subscription = _broadcast.listen((event) {
      if (event != RawSocketEvent.read) return;
      var dg = _socket.receive();
      var resp = MiioPacket.parse(dg.data);
      if (resp.length == 32 && resp.deviceId != 0xFFFFFFFF)
        callback(Tuple2(dg.address, resp));
    });

    var completer = Completer<void>();
    Timer(timeout, () {
      subscription.cancel();
      completer.complete();
    });

    _socket.send(MiioPacket.hello().binary, InternetAddress(ip), 54321);

    return completer.future;
  }

  /// Send a hello packet to [ip].
  Future<MiioPacket> hello(
    String ip, {
    Duration timeout = const Duration(seconds: 3),
  }) async {
    var completer = Completer<MiioPacket>();

    StreamSubscription<RawSocketEvent> subscription;
    subscription = _broadcast.listen((event) {
      if (event != RawSocketEvent.read) return;
      var dg = _socket.receive();
      var resp = MiioPacket.parse(dg.data);
      if (resp.length == 32 &&
          resp.deviceId != 0xFFFFFFFF &&
          dg.address.address == ip) {
        completer.complete(resp);
        subscription.cancel();
      }
    });

    Timer(timeout, () {
      if (completer.isCompleted) return;
      subscription.cancel();
      completer.complete();
    });

    _socket.send(MiioPacket.hello().binary, InternetAddress(ip), 54321);

    return completer.future;
  }

  /// Send a [packet] to [ip].
  Future<MiioPacket> send(
    String ip,
    MiioPacket packet, {
    Duration timeout = const Duration(seconds: 3),
  }) async {
    var completer = Completer<MiioPacket>();

    StreamSubscription<RawSocketEvent> subscription;
    subscription = _broadcast.listen((event) {
      if (event != RawSocketEvent.read) return;
      var dg = _socket.receive();
      var resp = MiioPacket.parse(dg.data, token: packet._token);
      if (dg.address.address == ip &&
          (resp.stamp == packet.stamp || resp.stamp == packet.stamp - 1)) {
        completer.complete(resp);
        subscription.cancel();
      }
    });

    Timer(timeout, () {
      if (completer.isCompleted) return;
      subscription.cancel();
      completer.complete();
    });

    _socket.send(packet.binary, InternetAddress(ip), 54321);

    return completer.future;
  }
}
