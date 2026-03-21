// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'coin_transaction_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$CoinTransactionModelImpl _$$CoinTransactionModelImplFromJson(
	Map<String, dynamic> json,
) => _$CoinTransactionModelImpl(
	id: json['id'] as String?,
	userId: json['userId'] as String?,
	amount: (json['amount'] as num?)?.toInt(),
	type: json['type'] as String?,
	createdAt: json['createdAt'] == null
			? null
			: DateTime.parse(json['createdAt'] as String),
);

Map<String, dynamic> _$$CoinTransactionModelImplToJson(
	_$CoinTransactionModelImpl instance,
) => <String, dynamic>{
	'id': instance.id,
	'userId': instance.userId,
	'amount': instance.amount,
	'type': instance.type,
	'createdAt': instance.createdAt?.toIso8601String(),
};
