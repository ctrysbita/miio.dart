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
import 'dart:math';

import 'package:json_annotation/json_annotation.dart';
import 'package:quiver/iterables.dart';

import 'error.dart';
import 'packet.dart';
import 'protocol.dart';
import 'utils.dart';

part 'device.g.dart';

/// Device based API that handles MiIO protocol easier.
class MiIODevice {
  final InternetAddress address;
  final List<int> token;

  /// Get device ID.
  int? get id => _id;
  int? _id;

  /// Get device ID from hello packet if not existed.
  Future<int> get did async {
    if (_id == null) {
      final hello = await MiIO.instance.hello(address);
      _id = hello.deviceId;
    }
    return _id!;
  }

  MiIODevice({
    required this.address,
    required this.token,
    int? id,
  })  : _id = id,
        assert(token.length == 16);

  /// Call method on device.
  Future<T> call<T>(
    String method, [
    List<dynamic> params = const <dynamic>[],
  ]) async {
    final id = Random().nextInt(32768);
    final resp = await MiIO.instance.send(
      address,
      await MiIOPacket.build(
        await did,
        token,
        payload: <String, dynamic>{
          'id': id,
          'method': method,
          'params': params,
        },
      ),
    );

    final payload = resp.payload;
    if (payload == null) {
      throw MiIOError(code: -1, message: 'No payload available.');
    }
    if (payload.containsKey('error')) {
      throw MiIOError(
        code: payload['error']['code'] as int,
        message: payload['error']['message'] as String,
      );
    }

    return payload['result'] as T;
  }

  /// Get MiIO info.
  Future<Map<String, dynamic>> get info =>
      call<Map<String, dynamic>>('miIO.info');

  /// Get a property using legacy MiIO profile.
  Future<T> getProp<T>(String prop) async => (await getProps([prop])).first;

  /// Get a set of properties using legacy MiIO profile.
  Future<List<dynamic>> getProps(List<String> props) async =>
      call<List<dynamic>>('get_prop', props);

  /// Get a property using MIoT spec.
  Future<T> getProperty<T>(int siid, int piid, [String? did]) async {
    final resp = await getProperties([
      GetPropertyReq(did: did, siid: siid, piid: piid),
    ]);

    return resp.first.value as T;
  }

  /// Get a set of properties using MIoT spec.
  Future<List<GetPropertyResp>> getProperties(
    List<GetPropertyReq> properties,
  ) async {
    // Request with chunks to prevent user ack timeout.
    var resp = <dynamic>[];
    for (final chunk in partition(properties, 12)) {
      resp.addAll(await call<List<dynamic>>('get_properties', chunk));
    }
    return resp.map((e) => GetPropertyResp.fromJson(e)).toList();
  }

  /// Set a property using MIoT spec.
  Future<bool> setProperty<T>(
    int siid,
    int piid,
    T value, [
    String? did,
  ]) async {
    final resp = await setProperties([
      SetPropertyReq<T>(did: did, siid: siid, piid: piid, value: value),
    ]);

    return resp.first.isOk;
  }

  /// Set a set of properties using MIoT spec.
  Future<List<SetPropertyResp>> setProperties(
    List<SetPropertyReq> properties,
  ) async {
    final resp = await call<List<dynamic>>('set_properties', properties);

    return resp.map((e) => SetPropertyResp.fromJson(e)).toList();
  }

  @override
  String toString() =>
      'MiIODevice(address: $address, id: ${_id?.toHexString(8)})';
}

@JsonSerializable(createFactory: false)
class GetPropertyReq {
  @JsonKey(includeIfNull: false)
  final String? did;
  final int siid;
  final int piid;

  const GetPropertyReq({
    this.did,
    required this.siid,
    required this.piid,
  });

  Map<String, dynamic> toJson() => _$GetPropertyReqToJson(this);
}

@JsonSerializable(createToJson: false)
class GetPropertyResp {
  final int code;
  final String did;
  final int siid;
  final int piid;
  final dynamic value;

  const GetPropertyResp({
    required this.code,
    required this.did,
    required this.siid,
    required this.piid,
    required this.value,
  });

  factory GetPropertyResp.fromJson(Map<String, dynamic> json) =>
      _$GetPropertyRespFromJson(json);

  bool get isOk => code == 0;
}

@JsonSerializable(createFactory: false, genericArgumentFactories: true)
class SetPropertyReq<T> {
  @JsonKey(includeIfNull: false)
  final String? did;
  final int siid;
  final int piid;
  final T value;

  const SetPropertyReq({
    this.did,
    required this.siid,
    required this.piid,
    required this.value,
  });

  Map<String, dynamic> toJson() =>
      _$SetPropertyReqToJson<T>(this, (value) => value);
}

@JsonSerializable(createToJson: false)
class SetPropertyResp {
  final int code;
  final String did;
  final int siid;
  final int piid;

  const SetPropertyResp({
    required this.code,
    required this.did,
    required this.siid,
    required this.piid,
  });

  factory SetPropertyResp.fromJson(Map<String, dynamic> json) =>
      _$SetPropertyRespFromJson(json);

  bool get isOk => code == 0;
}
