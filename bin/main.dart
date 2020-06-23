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

import 'dart:io';

import 'package:args/args.dart';
import 'package:miio/miio.dart';

void main(List<String> args) {
  var argsParser = ArgParser()
    ..addFlag('help', abbr: 'h', negatable: false, help: 'Print usage.');

  var commands = {
    'discover': argsParser.addCommand('discover')
      ..addOption('ip',
          help: 'The IP address to send discovery packet.'
              ' Usually broadcast address of your subnet.',
          valueHelp: '192.168.1.255')
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

  switch (commandResult.name) {
    case 'discover':
      handleDiscover(commandResult);
      break;
  }
}

void handleDiscover(ArgResults args) async => await Miio.discover(
    args['ip'], (resp) => print('Found ${resp.item2} from ${resp.item1}'));
