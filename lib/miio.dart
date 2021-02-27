// Copyright (C) 2020-2021 Jason C.H
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

library miio;

import 'dart:async';
import 'dart:io';

import 'package:tuple/tuple.dart';

import 'src/packet.dart';

export 'src/packet.dart';

/// MIIO LAN protocol.
class Miio {
  static final instance = Miio._();

  /// Cached stamps.
  final _stamps = <int, DateTime>{};

  Miio._();

  /// Cache boot time of device from response packet.
  void _cacheStamp(MiioPacket packet) {
    _stamps[packet.deviceId] =
        DateTime.now().subtract(Duration(seconds: packet.stamp));
  }

  /// Get current stamp of device from cache if existed.
  int? stampOf(int deviceId) {
    final bootTime = _stamps[deviceId];
    // ignore: avoid_returning_null
    if (bootTime == null) return null;

    return DateTime.now().difference(bootTime).inSeconds;
  }

  /// Send discovery packet to [address].
  Stream<Tuple2<InternetAddress, MiioPacket>> discover(
    InternetAddress address, {
    Duration timeout = const Duration(seconds: 3),
  }) async* {
    final socket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0);
    Timer(timeout, socket.close);

    socket.send(MiioPacket.hello.binary, address, 54321);

    await for (var _ in socket.where((e) => e == RawSocketEvent.read)) {
      var datagram = socket.receive();
      if (datagram == null) continue;

      var resp = await MiioPacket.parse(datagram.data);
      _cacheStamp(resp);
      yield Tuple2(datagram.address, resp);
    }
  }

  /// Send a hello packet to [address].
  Future<MiioPacket> hello(
    InternetAddress address, {
    Duration timeout = const Duration(seconds: 3),
  }) =>
      send(address, MiioPacket.hello, timeout: timeout);

  /// Send a [packet] to [address].
  Future<MiioPacket> send(
    InternetAddress address,
    MiioPacket packet, {
    Duration timeout = const Duration(seconds: 3),
  }) async {
    final completer = Completer<MiioPacket>();
    final socket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0);

    late final StreamSubscription<RawSocketEvent> subscription;
    final timer = Timer(timeout, () {
      if (completer.isCompleted) return;
      completer.complete();
      subscription.cancel();
      socket.close();
    });

    subscription =
        socket.where((e) => e == RawSocketEvent.read).listen((e) async {
      var datagram = socket.receive();
      if (datagram == null) return;

      var resp = await MiioPacket.parse(datagram.data, token: packet.token);
      _cacheStamp(resp);

      completer.complete(resp);
      subscription.cancel();
      timer.cancel();
      socket.close();
    });

    socket.send(packet.binary, address, 54321);

    return completer.future;
  }
}
