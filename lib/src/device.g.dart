// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'device.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Map<String, dynamic> _$GetPropertyReqToJson(GetPropertyReq instance) =>
    <String, dynamic>{
      'siid': instance.siid,
      'piid': instance.piid,
    };

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
) =>
    <String, dynamic>{
      'siid': instance.siid,
      'piid': instance.piid,
      'value': toJsonT(instance.value),
    };

SetPropertyResp _$SetPropertyRespFromJson(Map<String, dynamic> json) {
  return SetPropertyResp(
    code: json['code'] as int,
    siid: json['siid'] as int,
    piid: json['piid'] as int,
  );
}
