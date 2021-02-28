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

import 'package:args/command_runner.dart';
import 'package:logger/logger.dart';

import 'command/discover.dart';
import 'command/send.dart';

class MiioCommandRunner extends CommandRunner<void> {
  MiioCommandRunner() : super('miio', 'Cli for handling MIIO protocol.') {
    argParser.addOption(
      'level',
      abbr: 'l',
      help: 'Log level.',
      allowed: ['verbose', 'debug', 'info'],
      defaultsTo: 'info',
      callback: (level) {
        Logger.level = const <String, Level>{
              'verbose': Level.verbose,
              'debug': Level.debug,
              'info': Level.info,
            }[level] ??
            Level.info;
      },
    );

    addCommand(DiscoverCommand());
    addCommand(SendCommand());
  }
}
