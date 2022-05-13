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

import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:miio/miio.dart';
import 'package:miio/src/utils.dart';

class DiscoverCommand extends Command<void> {
  @override
  final String name = 'discover';

  @override
  final String description = 'Discover devices under LAN.';

  late final String? ip;
  late final bool table;

  DiscoverCommand() {
    argParser
      ..addOption(
        'ip',
        help: 'The IP address to send discovery packet.'
            ' Usually broadcast address of your subnet.',
        valueHelp: '192.168.1.255',
        callback: (s) => ip = s,
      )
      ..addFlag(
        'table',
        help: 'Print a table instead of messages.',
        defaultsTo: false,
        callback: (t) => table = t,
      );
  }

  @override
  Future<void> run() async {
    if (ip == null) {
      logger.e('Option ip is required.');
      printUsage();
      return;
    }

    final address = InternetAddress.tryParse(ip!);
    if (address == null) {
      logger.e('Invalid IP address: $ip');
      printUsage();
      return;
    }

    if (table) print('Address\t\tID\t\tID (hex)\tStamp\t\tToken');
    await for (var resp in MiIO.instance.discover(address)) {
      final address = resp.item1;
      final packet = resp.item2;
      if (!table) {
        logger.i('Found MiIO device from ${address.address}:\n'
            'ID: ${packet.deviceId} (0x${packet.deviceId.toHexString(8)})\n'
            'Stamp: ${packet.stamp}\n'
            'Startup Date: '
            '${DateTime.now().subtract(Duration(seconds: packet.stamp))}\n'
            'Token: ${packet.checksum.hexString.padLeft(32, '0')}');
      } else {
        print('${address.address}\t'
            '${packet.deviceId}\t'
            '${packet.deviceId.toHexString(8)}\t'
            '${packet.stamp.toHexString(8)}\t'
            '${packet.checksum.hexString.padLeft(32, '0')}');
      }
    }
  }
}
