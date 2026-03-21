// GENERATED CODE - DO NOT MODIFY BY HAND
part of 'room_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$RoomModelImpl _$$RoomModelImplFromJson(Map<String, dynamic> json) =>
    _$RoomModelImpl(
      id: json['id'] as String?,
      name: json['name'] as String?,
      hostId: json['hostId'] as String?,
      participantIds: (json['participantIds'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      isLive: json['isLive'] as bool?,
      createdAt: json['createdAt'] == null
          ? null
          : DateTime.parse(json['createdAt'] as String),
    );

Map<String, dynamic> _$$RoomModelImplToJson(_$RoomModelImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'hostId': instance.hostId,
      'participantIds': instance.participantIds,
      'isLive': instance.isLive,
      'createdAt': instance.createdAt?.toIso8601String(),
    };
