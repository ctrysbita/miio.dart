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
