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

import 'package:args/command_runner.dart';
import 'package:logging/logging.dart';

import 'command/device.dart';
import 'command/discover.dart';
import 'command/packet.dart';
import 'command/send.dart';

class MiIOCommandRunner extends CommandRunner<void> {
  MiIOCommandRunner() : super('miio', 'Cli for handling MiIO protocol.') {
    argParser.addOption(
      'level',
      abbr: 'l',
      help: 'Log level.',
      allowed: ['v', 'verbose', 'f', 'fine', 'i', 'info', 'a', 'all'],
      defaultsTo: 'info',
      callback: (level) {
        Logger.root.level = const <String, Level>{
              'v': Level.FINEST,
              'verbose': Level.FINEST,
              'f': Level.FINE,
              'fine': Level.FINE,
              'i': Level.INFO,
              'info': Level.INFO,
              'a': Level.ALL,
              'all': Level.ALL,
            }[level] ??
            Level.INFO;
      },
    );

    addCommand(DiscoverCommand());
    addCommand(SendCommand());
    addCommand(PacketCommand());
    addCommand(DeviceCommand());
  }
}
