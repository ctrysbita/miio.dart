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

import 'dart:convert';
import 'dart:io';

import 'package:args/args.dart';
import 'package:miio/miio.dart';

void main(List<String> args) async {
  var argsParser = ArgParser()
    ..addFlag('help', abbr: 'h', negatable: false, help: 'Print usage.');

  var commands = {
    'discover': argsParser.addCommand('discover')
      ..addOption('ip',
          help: 'The IP address to send discovery packet.'
              ' Usually broadcast address of your subnet.',
          valueHelp: '192.168.1.255')
      ..addFlag('help', abbr: 'h', negatable: false, help: 'Print usage.'),
    'send': argsParser.addCommand('send')
      ..addOption('ip',
          help: 'The IP address to send packet.', valueHelp: '192.168.1.100')
      ..addOption('token',
          help: 'The token for device.',
          valueHelp: 'ffffffffffffffffffffffffffffffff')
      ..addOption('payload', help: 'The payload of packet.')
      ..addFlag('help', abbr: 'h', negatable: false, help: 'Print usage.'),
  };

  var argsResult = argsParser.parse(args);

  if (argsResult.wasParsed('help') || argsResult.command == null) {
    print('MIIO Toolkit\n\n'
        'Usage: miio <command> [arguments]\n\n'
        'Available commands: ${argsParser.commands.keys}\n\n'
        'Available arguments:');
    print(argsParser.usage);
    exit(0);
  }

  var commandResult = argsResult.command;
  if (commandResult.wasParsed('help')) {
    print('MIIO Toolkit\n\n'
        'Usage: miio ${commandResult.name} [arguments]\n\n'
        'Available arguments:');
    print(commands[commandResult.name].usage);
    exit(0);
  }

  await Miio.init();

  switch (commandResult.name) {
    case 'discover':
      await handleDiscover(commandResult);
      break;
    case 'send':
      await handleSend(commandResult);
      break;
  }

  Miio.instance.close();
}

Future<void> handleDiscover(ArgResults args) async =>
    await Miio.instance.discover(
        args['ip'], (resp) => print('Found ${resp.item2} from ${resp.item1}'));

Future<void> handleSend(ArgResults args) async {
  var ip = args['ip'];

  print('$ip <- HELLO');
  var hello = await Miio.instance.hello(ip);
  print('$ip -> $hello');

  var packet = MiioPacket(
    hello.deviceId,
    BigInt.parse(args['token'], radix: 16),
    stamp: hello.stamp + 1,
  );
  packet.payload = jsonDecode(args['payload']);

  print('$ip <- ${packet.payload}');
  var resp = await Miio.instance.send(ip, packet);
  print('$ip -> $resp');

  print('--- PAYLOAD BEGIN ---');
  print(JsonEncoder.withIndent('  ').convert(resp.payload));
  print('--- PAYLOAD END ---');
}
