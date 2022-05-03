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

import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:convert/convert.dart';
import 'package:miio/miio.dart';
import 'package:miio/src/utils.dart';

class PacketCommand extends Command<void> {
  @override
  final String name = 'packet';

  @override
  final String description = 'Parse packet from binary / file.';

  late final String? token;
  late final String? filePath;

  PacketCommand() {
    argParser
      ..addOption(
        'token',
        help: 'The token to decrypt packet.',
        valueHelp: 'ffffffffffffffffffffffffffffffff',
        callback: (s) => token = s,
      )
      ..addOption(
        'file',
        help: 'Load binary packet from file.',
        callback: (s) => filePath = s,
      );
  }

  @override
  Future<void> run() async {
    if (filePath == null) {
      logger.e('Option file is required.');
      printUsage();
      return;
    }

    late final List<int>? binaryToken;
    try {
      binaryToken = token == null ? null : hex.decode(token!);
    } on FormatException catch (e) {
      logger.e('$e\nwhile parsing token.');
      printUsage();
      return;
    }

    final binary = await File(filePath!).readAsBytes();

    logger.v('Decoding binary packet:\n' '${binary.prettyString}');

    final packet = await MiIOPacket.parse(binary, token: binaryToken);

    logger.d(
      'Decoded packet ${packet.length == 32 ? '(hello)' : ''}\n'
      '$packet\n'
      '${jsonEncoder.convert(packet.payload)}',
    );

    print(jsonEncoder.convert(packet.payload));
  }
}
