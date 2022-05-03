// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'device.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Map<String, dynamic> _$GetPropertyReqToJson(GetPropertyReq instance) {
  final val = <String, dynamic>{};

  void writeNotNull(String key, dynamic value) {
    if (value != null) {
      val[key] = value;
    }
  }

  writeNotNull('did', instance.did);
  val['siid'] = instance.siid;
  val['piid'] = instance.piid;
  return val;
}

GetPropertyResp _$GetPropertyRespFromJson(Map<String, dynamic> json) =>
    GetPropertyResp(
      code: json['code'] as int,
      did: json['did'] as String,
      siid: json['siid'] as int,
      piid: json['piid'] as int,
      value: json['value'],
    );

Map<String, dynamic> _$SetPropertyReqToJson<T>(
  SetPropertyReq<T> instance,
  Object? Function(T value) toJsonT,
) {
  final val = <String, dynamic>{};

  void writeNotNull(String key, dynamic value) {
    if (value != null) {
      val[key] = value;
    }
  }

  writeNotNull('did', instance.did);
  val['siid'] = instance.siid;
  val['piid'] = instance.piid;
  val['value'] = toJsonT(instance.value);
  return val;
}

SetPropertyResp _$SetPropertyRespFromJson(Map<String, dynamic> json) =>
    SetPropertyResp(
      code: json['code'] as int,
      did: json['did'] as String,
      siid: json['siid'] as int,
      piid: json['piid'] as int,
    );
