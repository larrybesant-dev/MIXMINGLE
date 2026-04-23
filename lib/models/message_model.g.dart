// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'message_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_MessageModel _$MessageModelFromJson(Map<String, dynamic> json) =>
    _MessageModel(
      id: json['id'] as String,
      senderId: json['senderId'] as String,
      roomId: json['roomId'] as String,
      content: json['content'] as String,
      sentAt: DateTime.parse(json['sentAt'] as String),
      type: json['type'] as String? ?? 'normal',
      richText: json['richText'] as String? ?? '',
    );

Map<String, dynamic> _$MessageModelToJson(_MessageModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'senderId': instance.senderId,
      'roomId': instance.roomId,
      'content': instance.content,
      'sentAt': instance.sentAt.toIso8601String(),
      'type': instance.type,
      'richText': instance.richText,
    };
