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

import 'package:json_annotation/json_annotation.dart';
import 'package:quiver/iterables.dart';

import 'error.dart';
import 'packet.dart';
import 'protocol.dart';
import 'utils.dart';

part 'device.g.dart';

/// Device based API that handles MIIO protocol easier.
class MiIoDevice {
  final InternetAddress address;
  final List<int> token;

  int? _id;
  int? get id => _id;

  /// Get device ID from hello packet if no ID provided yet.
  Future<int> get did async {
    if (_id == null) {
      final hello = await MiIo.instance.hello(address);
      _id = hello.deviceId;
    }
    return _id!;
  }

  MiIoDevice({
    required this.address,
    required this.token,
    int? id,
  }) : _id = id;

  @override
  String toString() =>
      'MiIoDevice(address: $address, id: ${_id?.toHexString(8)})';

  /// Get MIIO info.
  Future<Map<String, dynamic>?> get info async {
    final resp = await MiIo.instance.send(
      address,
      await MiIoPacket.build(
        await did,
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
        await did,
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

  /// Get a property using MIoT spec.
  Future<T> getProperty<T>(int siid, int piid, [String? did]) async {
    final resp = await getProperties([
      GetPropertyReq(siid: siid, piid: piid, did: did),
    ]);

    return resp.first.value as T;
  }

  /// Get a set of properties using MIoT spec.
  Future<List<GetPropertyResp>> getProperties(
      List<GetPropertyReq> properties) async {
    // Request with chunks to prevent user ack timeout.
    var resp = <dynamic>[];
    for (var chunk in partition(properties, 10)) {
      resp.addAll(await call('get_properties', chunk));
    }
    return resp
        .map((dynamic e) => GetPropertyResp.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Set a property using MIoT spec.
  Future<bool> setProperty<T>(
    int siid,
    int piid,
    T value, [
    String? did,
  ]) async {
    final resp = await setProperties([
      SetPropertyReq<T>(siid: siid, piid: piid, value: value, did: did),
    ]);

    return resp.first.isOk;
  }

  /// Set a set of properties using MIoT spec.
  Future<List<SetPropertyResp>> setProperties(
    List<SetPropertyReq> properties,
  ) async {
    final resp = await call('set_properties', properties);

    return resp
        .map((dynamic e) => SetPropertyResp.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}

@JsonSerializable(createFactory: false)
class GetPropertyReq {
  final int siid;
  final int piid;

  @JsonKey(includeIfNull: false)
  final String? did;

  const GetPropertyReq({
    required this.siid,
    required this.piid,
    this.did,
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
  final int siid;
  final int piid;
  final T value;

  @JsonKey(includeIfNull: false)
  final String? did;

  const SetPropertyReq({
    required this.siid,
    required this.piid,
    required this.value,
    this.did,
  });

  Map<String, dynamic> toJson() =>
      _$SetPropertyReqToJson<T>(this, (value) => value as Object);
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
