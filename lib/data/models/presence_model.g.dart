// GENERATED CODE - DO NOT MODIFY BY HAND
part of 'presence_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$PresenceModelImpl _$$PresenceModelImplFromJson(Map<String, dynamic> json) =>
    _$PresenceModelImpl(
      id: json['id'] as String?,
      userId: json['userId'] as String?,
      isOnline: json['isOnline'] as bool?,
      lastSeen: json['lastSeen'] == null
          ? null
          : DateTime.parse(json['lastSeen'] as String),
    );

Map<String, dynamic> _$$PresenceModelImplToJson(_$PresenceModelImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'userId': instance.userId,
      'isOnline': instance.isOnline,
      'lastSeen': instance.lastSeen?.toIso8601String(),
    };
