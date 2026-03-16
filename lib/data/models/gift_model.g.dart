// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'gift_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$GiftModelImpl _$$GiftModelImplFromJson(Map<String, dynamic> json) =>
    _$GiftModelImpl(
      id: json['id'] as String?,
      senderId: json['senderId'] as String?,
      receiverId: json['receiverId'] as String?,
      amount: (json['amount'] as num?)?.toInt(),
      type: json['type'] as String?,
      sentAt: json['sentAt'] == null
          ? null
          : DateTime.parse(json['sentAt'] as String),
    );

Map<String, dynamic> _$$GiftModelImplToJson(_$GiftModelImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'senderId': instance.senderId,
      'receiverId': instance.receiverId,
      'amount': instance.amount,
      'type': instance.type,
      'sentAt': instance.sentAt?.toIso8601String(),
    };
