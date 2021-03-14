// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'device.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Map<String, dynamic> _$GetPropertyReqToJson(GetPropertyReq instance) {
  final val = <String, dynamic>{
    'siid': instance.siid,
    'piid': instance.piid,
  };

  void writeNotNull(String key, dynamic value) {
    if (value != null) {
      val[key] = value;
    }
  }

  writeNotNull('did', instance.did);
  return val;
}

GetPropertyResp _$GetPropertyRespFromJson(Map<String, dynamic> json) {
  return GetPropertyResp(
    code: json['code'] as int,
    siid: json['siid'] as int,
    piid: json['piid'] as int,
    value: json['value'],
  );
}

Map<String, dynamic> _$SetPropertyReqToJson<T>(
  SetPropertyReq<T> instance,
  Object Function(T value) toJsonT,
) {
  final val = <String, dynamic>{
    'siid': instance.siid,
    'piid': instance.piid,
    'value': toJsonT(instance.value),
  };

  void writeNotNull(String key, dynamic value) {
    if (value != null) {
      val[key] = value;
    }
  }

  writeNotNull('did', instance.did);
  return val;
}

SetPropertyResp _$SetPropertyRespFromJson(Map<String, dynamic> json) {
  return SetPropertyResp(
    code: json['code'] as int,
    siid: json['siid'] as int,
    piid: json['piid'] as int,
  );
}
