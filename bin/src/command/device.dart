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

class DeviceCommand extends Command<void> {
  @override
  final String name = 'device';

  @override
  final String description = 'Control device.';

  late final String? ip;
  late final String? token;

  DeviceCommand() {
    argParser
      ..addOption(
        'ip',
        help: 'The IP address to send packet.',
        valueHelp: '192.168.1.100',
        callback: (s) => ip = s,
      )
      ..addOption(
        'token',
        help: 'The token of device.',
        valueHelp: 'ffffffffffffffffffffffffffffffff',
        callback: (s) => token = s,
      );

    addSubcommand(InfoCommand());
    addSubcommand(CallCommand());
    addSubcommand(GetPropCommand());
  }

  Future<MiioDevice?> get device async {
    if (ip == null || token == null) {
      logger.e('Option ip and token are required.');
      printUsage();
      return null;
    }

    final address = InternetAddress.tryParse(ip!);
    if (address == null) {
      logger.e('Invalid IP address: $ip');
      printUsage();
      return null;
    }

    late final List<int> binaryToken;
    try {
      binaryToken = hex.decode(token!);
    } on FormatException catch (e) {
      logger.e('$e\nwhile parsing token.');
      printUsage();
      return null;
    }

    if (binaryToken.length != 16) {
      logger.w('${binaryToken.length} bytes token is abnormal.\n'
          'This may cause undefined behavior.');
    }

    final hello = await Miio.instance.hello(address);
    final device = MiioDevice(
      address: address,
      token: binaryToken,
      id: hello.deviceId,
    );

    logger.d('Using $device');
    return device;
  }
}

class InfoCommand extends Command<void> {
  @override
  final String name = 'info';

  @override
  final String description = 'Get info from device.';

  @override
  Future<void> run() async {
    final device = await (parent as DeviceCommand).device;
    if (device == null) return;

    print(jsonEncoder.convert(await device.info));
  }
}

class CallCommand extends Command<void> {
  @override
  final String name = 'call';

  @override
  final String description = 'Call method on device.';

  late final String? method;
  late final List<String> params;

  CallCommand() {
    argParser
      ..addOption(
        'method',
        abbr: 'm',
        help: 'The method to call.',
        valueHelp: 'set_power',
        callback: (s) => method = s,
      )
      ..addMultiOption(
        'params',
        abbr: 'p',
        help: 'Parameters of method call.',
        callback: (l) => params = l,
      );
  }

  @override
  Future<void> run() async {
    if (method == null) {
      logger.e('Option method is required.');
      printUsage();
      return null;
    }

    final device = await (parent as DeviceCommand).device;
    if (device == null) return;

    print(await device.call(method!, params));
  }
}

class GetPropCommand extends Command<void> {
  @override
  final String name = 'prop';

  @override
  final String description = 'Get prop from device using legacy MIIO profile.';

  late final String? prop;

  GetPropCommand() {
    argParser
      ..addOption(
        'prop',
        help: 'The prop to get.',
        valueHelp: 'power',
        callback: (s) => prop = s,
      );
  }

  @override
  Future<void> run() async {
    if (prop == null) {
      logger.e('Option prop is required.');
      printUsage();
      return null;
    }

    final device = await (parent as DeviceCommand).device;
    if (device == null) return;

    print(await device.getProp(prop!));
  }
}
