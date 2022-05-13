// Copyright (C) 2020-2022 Jason C.H
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

import 'dart:async';
import 'dart:io';

import 'package:tuple/tuple.dart';

import 'packet.dart';
import 'utils.dart';

/// MiIO LAN protocol.
class MiIO {
  static final instance = MiIO._();

  /// Cached stamps.
  final _stamps = <int, DateTime>{};

  MiIO._();

  /// Cache boot time of device from response packet.
  void _cacheStamp(MiIOPacket packet) {
    _stamps[packet.deviceId] =
        DateTime.now().subtract(Duration(seconds: packet.stamp));
  }

  /// Get current stamp of device from cache if existed.
  int? stampOf(int deviceId) {
    final bootTime = _stamps[deviceId];
    if (bootTime == null) return null;
    return DateTime.now().difference(bootTime).inSeconds;
  }

  /// Send discovery packet to broadcast [address].
  Stream<Tuple2<InternetAddress, MiIOPacket>> discover(
    InternetAddress address, {
    Duration timeout = const Duration(seconds: 3),
  }) async* {
    final socket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0);
    Timer(timeout, socket.close);

    socket.send(MiIOPacket.hello.binary, address, 54321);

    await for (final event in socket) {
      if (event != RawSocketEvent.read) continue;
      final datagram = socket.receive();
      if (datagram == null) continue;

      var resp = await MiIOPacket.parse(datagram.data);
      _cacheStamp(resp);
      yield Tuple2(datagram.address, resp);
    }
  }

  /// Send a hello packet to [address].
  Future<MiIOPacket> hello(
    InternetAddress address, {
    Duration timeout = const Duration(seconds: 3),
  }) =>
      send(address, MiIOPacket.hello, timeout: timeout);

  /// Send a [packet] to [address].
  Future<MiIOPacket> send(
    InternetAddress address,
    MiIOPacket packet, {
    Duration timeout = const Duration(seconds: 3),
  }) async {
    final completer = Completer<MiIOPacket>();
    final socket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0);

    late final StreamSubscription<RawSocketEvent> subscription;
    final timer = Timer(timeout, () {
      if (completer.isCompleted) return;
      completer.completeError(
        TimeoutException('Timeout while receving response from $address.'),
      );
      socket.close();
      subscription.cancel();
    });

    subscription =
        socket.where((e) => e == RawSocketEvent.read).listen((e) async {
      var datagram = socket.receive();
      if (datagram == null) return;

      logger.v('Receiving binary packet:\n' '${datagram.data.prettyString}');

      final resp = await MiIOPacket.parse(datagram.data, token: packet.token);

      logger.d(
        'Receiving packet ${resp.length == 32 ? '(hello) ' : ''}'
        'from ${datagram.address.address}:\n'
        '$resp\n'
        '${jsonEncoder.convert(resp.payload)}',
      );

      _cacheStamp(resp);
      completer.complete(resp);

      timer.cancel();
      socket.close();
      subscription.cancel();
    });

    logger.d(
      'Sending packet ${packet.length == 32 ? '(hello) ' : ''}'
      'to ${address.address}:\n'
      '$packet\n'
      '${jsonEncoder.convert(packet.payload)}',
    );
    logger.v('Sending binary packet:\n' '${packet.binary.prettyString}');

    socket.send(packet.binary, address, 54321);

    return completer.future;
  }
}
