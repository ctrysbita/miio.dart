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
import 'package:convert/convert.dart';
import 'package:logging/logging.dart';
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
    addSubcommand(GetPropsCommand());
    addSubcommand(PropertyCommand());
    addSubcommand(ActionCommand());
  }

  Future<MiIODevice?> get device async {
    if (ip == null || token == null) {
      Logger.root.severe('Option ip and token are required.');
      printUsage();
      return null;
    }

    final address = InternetAddress.tryParse(ip!);
    if (address == null) {
      Logger.root.severe('Invalid IP address: $ip');
      printUsage();
      return null;
    }

    late final List<int> binaryToken;
    try {
      binaryToken = hex.decode(token!);
    } on FormatException catch (e) {
      Logger.root.severe('$e\nwhile parsing token.');
      printUsage();
      return null;
    }

    if (binaryToken.length != 16) {
      Logger.root.warning(
        '${binaryToken.length} bytes token is abnormal.\n'
        'This may cause undefined behavior.',
      );
    }

    final hello = await MiIO.instance.hello(address);
    final device = MiIODevice(
      address: address,
      token: binaryToken,
      id: hello.deviceId,
    );

    Logger.root.fine('Using $device');
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
      Logger.root.severe('Option method is required.');
      printUsage();
      return;
    }

    final device = await (parent as DeviceCommand).device;
    if (device == null) return;

    print(await device.call(
      method!,
      params.map((e) => int.tryParse(e) ?? e).toList(),
    ));
  }
}

class GetPropsCommand extends Command<void> {
  @override
  final String name = 'props';

  @override
  final String description = 'Get props from device using legacy MiIO profile.';

  late final List<String> props;

  GetPropsCommand() {
    argParser.addMultiOption(
      'prop',
      abbr: 'p',
      help: 'The prop to get.',
      valueHelp: 'power',
      callback: (s) => props = s,
    );
  }

  @override
  Future<void> run() async {
    if (props.isEmpty) {
      Logger.root.severe('Option props is required.');
      printUsage();
      return;
    }

    final device = await (parent as DeviceCommand).device;
    if (device == null) return;

    final results = await device.getProps(props);
    print(jsonEncoder.convert(
      Map<String, dynamic>.fromIterables(
        props,
        results,
      ),
    ));
  }
}

class PropertyCommand extends Command<void> {
  @override
  final String name = 'property';

  @override
  final String description = 'Get / Set property using MIoT spec.';

  late final String? did;
  late final int? siid;
  late final int? piid;
  late final dynamic value;

  PropertyCommand() {
    argParser
      ..addOption(
        'did',
        abbr: 'd',
        help: 'Device ID.',
        callback: (s) => did = s,
      )
      ..addOption(
        'siid',
        abbr: 's',
        help: 'Serice ID.',
        callback: (s) => siid = s == null ? null : int.tryParse(s),
      )
      ..addOption(
        'piid',
        abbr: 'p',
        help: 'Property ID.',
        callback: (s) => piid = s == null ? null : int.tryParse(s),
      )
      ..addOption(
        'value',
        abbr: 'v',
        help: 'Value to set.',
        callback: (s) => value = parseValue(s),
      );
  }

  dynamic parseValue(String? value) {
    if (value == null) return null;
    if (value == 'true') return true;
    if (value == 'false') return false;

    return int.tryParse(value) ?? double.tryParse(value) ?? value;
  }

  @override
  Future<void> run() async {
    if (siid == null || piid == null) {
      Logger.root.severe('Option siid and piid are required.');
      printUsage();
      return;
    }

    final device = await (parent as DeviceCommand).device;
    if (device == null) return;

    if (value == null) {
      Logger.root.info(
        'Getting service $siid property $piid from device ${device.id}.',
      );
      print(await device.getProperty<dynamic>(siid!, piid!, did));
    } else {
      Logger.root.info(
        'Setting service $siid property $piid of device ${device.id} to $value.',
      );
      final result =
          await device.setProperty<dynamic>(siid!, piid!, value, did);
      print(result ? 'Done' : 'Failed');
    }
  }
}

class ActionCommand extends Command<void> {
  @override
  final String name = 'action';

  @override
  final String description = 'Trigger action on device.';

  late final String? did;
  late final int? siid;
  late final int? aiid;

  ActionCommand() {
    argParser
      ..addOption(
        'did',
        abbr: 'd',
        help: 'Device ID.',
        callback: (s) => did = s,
      )
      ..addOption(
        'siid',
        abbr: 's',
        help: 'Serice ID.',
        callback: (s) => siid = s == null ? null : int.tryParse(s),
      )
      ..addOption(
        'aiid',
        abbr: 'a',
        help: 'Action ID.',
        callback: (s) => aiid = s == null ? null : int.tryParse(s),
      );
  }

  @override
  Future<void> run() async {
    if (siid == null || aiid == null) {
      Logger.root.severe('Option siid and aiid are required.');
      printUsage();
      return;
    }

    final device = await (parent as DeviceCommand).device;
    if (device == null) return;

    Logger.root.info(
      'Trigger service $siid action $aiid for device ${device.id}.',
    );
    final resp = await device.action(siid!, aiid!, did: did);
    print(resp ? 'Done' : 'Failed');
  }
}
