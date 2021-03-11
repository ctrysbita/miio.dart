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
import 'dart:math';

import 'error.dart';
import 'packet.dart';
import 'protocol.dart';
import 'utils.dart';

/// Device based API that handles MIIO protocol easier.
class MiIoDevice {
  final InternetAddress address;
  final int id;
  final List<int> token;

  MiIoDevice({
    required this.address,
    required this.token,
    required this.id,
  });

  @override
  String toString() =>
      'MiIoDevice(address: $address, id: ${id.toHexString(8)})';

  /// Get MIIO info.
  Future<Map<String, dynamic>?> get info async {
    final resp = await MiIo.instance.send(
      address,
      await MiIoPacket.build(
        id,
        token,
        payload: <String, dynamic>{
          'id': Random().nextInt(32768),
          'method': 'miIO.info',
          'params': <void>[],
        },
      ),
    );
    return resp.payload;
  }

  /// Call method on device.
  Future<List<dynamic>> call(
    String method, [
    List<dynamic> params = const <dynamic>[],
  ]) async {
    final resp = await MiIo.instance.send(
      address,
      await MiIoPacket.build(
        id,
        token,
        payload: <String, dynamic>{
          'id': Random().nextInt(32768),
          'method': method,
          'params': params,
        },
      ),
    );

    final payload = resp.payload;
    if (payload == null) {
      throw MiIoError(code: -1, message: 'No payload available.');
    }
    if (payload.containsKey('error')) {
      throw MiIoError(
        code: payload['error']['code'] as int,
        message: payload['error']['message'] as String,
      );
    }

    return payload['result'] as List<dynamic>;
  }

  /// Get a property using legacy MIIO profile.
  Future<String> getProp(String prop) async => (await getProps([prop])).first;

  /// Get a set of properties using legacy MIIO profile.
  Future<List<String>> getProps(List<String> props) async {
    final resp = await call('get_prop', props);

    return resp.cast();
  }

  /// Get property using MIoT spec.
  Future<T> getProperty<T>(int siid, int piid) async {
    final resp = await call('get_properties', <Map<String, dynamic>>[
      <String, dynamic>{
        'siid': siid,
        'piid': piid,
      }
    ]);

    return resp.first['value'] as T;
  }

  /// Set property using MIoT spec.
  Future<void> setProperty<T>(int siid, int piid, dynamic value) async {
    await call('set_properties', <Map<String, dynamic>>[
      <String, dynamic>{
        'siid': siid,
        'piid': piid,
        'value': value,
      }
    ]);
  }
}
