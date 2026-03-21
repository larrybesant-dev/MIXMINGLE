// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'coin_transaction_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
	'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

CoinTransactionModel _$CoinTransactionModelFromJson(Map<String, dynamic> json) {
	return _CoinTransactionModel.fromJson(json);
}

/// @nodoc
mixin _$CoinTransactionModel {
	String? get id => throw _privateConstructorUsedError;
	String? get userId => throw _privateConstructorUsedError;
	int? get amount => throw _privateConstructorUsedError;
	String? get type => throw _privateConstructorUsedError;
	DateTime? get createdAt => throw _privateConstructorUsedError;

	/// Serializes this CoinTransactionModel to a JSON map.
	Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

	/// Create a copy of CoinTransactionModel
	/// with the given fields replaced by the non-null parameter values.
	@JsonKey(includeFromJson: false, includeToJson: false)
	$CoinTransactionModelCopyWith<CoinTransactionModel> get copyWith =>
			throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $CoinTransactionModelCopyWith<$Res> {
	factory $CoinTransactionModelCopyWith(
		CoinTransactionModel value,
		$Res Function(CoinTransactionModel) then,
	) = _$CoinTransactionModelCopyWithImpl<$Res, CoinTransactionModel>;
	@useResult
	$Res call({
		String? id,
		String? userId,
		int? amount,
		String? type,
		DateTime? createdAt,
	});
}

/// @nodoc
class _$CoinTransactionModelCopyWithImpl<
	$Res,
	$Val extends CoinTransactionModel
>
		implements $CoinTransactionModelCopyWith<$Res> {
	_$CoinTransactionModelCopyWithImpl(this._value, this._then);

	// ignore: unused_field
	final $Val _value;
	// ignore: unused_field
	final $Res Function($Val) _then;

	/// Create a copy of CoinTransactionModel
	/// with the given fields replaced by the non-null parameter values.
	@pragma('vm:prefer-inline')
	@override
	$Res call({
		Object? id = freezed,
		Object? userId = freezed,
		Object? amount = freezed,
		Object? type = freezed,
		Object? createdAt = freezed,
	}) {
		return _then(
			_value.copyWith(
						id: freezed == id
								? _value.id
								: id // ignore: cast_nullable_to_non_nullable
											as String?,
						userId: freezed == userId
								? _value.userId
								: userId // ignore: cast_nullable_to_non_nullable
											as String?,
						amount: freezed == amount
								? _value.amount
								: amount // ignore: cast_nullable_to_non_nullable
											as int?,
						type: freezed == type
								? _value.type
								: type // ignore: cast_nullable_to_non_nullable
											as String?,
						createdAt: freezed == createdAt
								? _value.createdAt
								: createdAt // ignore: cast_nullable_to_non_nullable
											as DateTime?,
					)
					as $Val,
		);
	}
}

/// @nodoc
abstract class _$$CoinTransactionModelImplCopyWith<$Res>
		implements $CoinTransactionModelCopyWith<$Res> {
	factory _$$CoinTransactionModelImplCopyWith(
		_$CoinTransactionModelImpl value,
		$Res Function(_$CoinTransactionModelImpl) then,
	) = __$$CoinTransactionModelImplCopyWithImpl<$Res>;
	@override
	@useResult
	$Res call({
		String? id,
		String? userId,
		int? amount,
		String? type,
		DateTime? createdAt,
	});
}

/// @nodoc
class __$$CoinTransactionModelImplCopyWithImpl<$Res>
		extends _$CoinTransactionModelCopyWithImpl<$Res, _$CoinTransactionModelImpl>
		implements _$$CoinTransactionModelImplCopyWith<$Res> {
	__$$CoinTransactionModelImplCopyWithImpl(
		_$CoinTransactionModelImpl _value,
		$Res Function(_$CoinTransactionModelImpl) _then,
	) : super(_value, _then);

	/// Create a copy of CoinTransactionModel
	/// with the given fields replaced by the non-null parameter values.
	@pragma('vm:prefer-inline')
	@override
	$Res call({
		Object? id = freezed,
		Object? userId = freezed,
		Object? amount = freezed,
		Object? type = freezed,
		Object? createdAt = freezed,
	}) {
		return _then(
			_$CoinTransactionModelImpl(
				id: freezed == id
						? _value.id
						: id // ignore: cast_nullable_to_non_nullable
									as String?,
				userId: freezed == userId
						? _value.userId
						: userId // ignore: cast_nullable_to_non_nullable
									as String?,
				amount: freezed == amount
						? _value.amount
						: amount // ignore: cast_nullable_to_non_nullable
									as int?,
				type: freezed == type
						? _value.type
						: type // ignore: cast_nullable_to_non_nullable
									as String?,
				createdAt: freezed == createdAt
						? _value.createdAt
						: createdAt // ignore: cast_nullable_to_non_nullable
									as DateTime?,
			),
		);
	}
}

/// @nodoc
@JsonSerializable()
class _$CoinTransactionModelImpl implements _CoinTransactionModel {
	const _$CoinTransactionModelImpl({
		this.id,
		this.userId,
		this.amount,
		this.type,
		this.createdAt,
	});

	factory _$CoinTransactionModelImpl.fromJson(Map<String, dynamic> json) =>
			_$$CoinTransactionModelImplFromJson(json);

	@override
	final String? id;
	@override
	final String? userId;
	@override
	final int? amount;
	@override
	final String? type;
	@override
	final DateTime? createdAt;

	@override
	String toString() {
		return 'CoinTransactionModel(id: $id, userId: $userId, amount: $amount, type: $type, createdAt: $createdAt)';
	}

	@override
	bool operator ==(Object other) {
		return identical(this, other) ||
				(other.runtimeType == runtimeType &&
						other is _$CoinTransactionModelImpl &&
						(identical(other.id, id) || other.id == id) &&
						(identical(other.userId, userId) || other.userId == userId) &&
						(identical(other.amount, amount) || other.amount == amount) &&
						(identical(other.type, type) || other.type == type) &&
						(identical(other.createdAt, createdAt) ||
								other.createdAt == createdAt));
	}

	@JsonKey(includeFromJson: false, includeToJson: false)
	@override
	int get hashCode =>
			Object.hash(runtimeType, id, userId, amount, type, createdAt);

	/// Create a copy of CoinTransactionModel
	/// with the given fields replaced by the non-null parameter values.
	@JsonKey(includeFromJson: false, includeToJson: false)
	@override
	@pragma('vm:prefer-inline')
	_$$CoinTransactionModelImplCopyWith<_$CoinTransactionModelImpl>
	get copyWith =>
			__$$CoinTransactionModelImplCopyWithImpl<_$CoinTransactionModelImpl>(
				this,
				_$identity,
			);

	@override
	Map<String, dynamic> toJson() {
		return _$$CoinTransactionModelImplToJson(this);
	}
}

abstract class _CoinTransactionModel implements CoinTransactionModel {
	const factory _CoinTransactionModel({
		final String? id,
		final String? userId,
		final int? amount,
		final String? type,
		final DateTime? createdAt,
	}) = _$CoinTransactionModelImpl;

	factory _CoinTransactionModel.fromJson(Map<String, dynamic> json) =
			_$CoinTransactionModelImpl.fromJson;

	@override
	String? get id;
	@override
	String? get userId;
	@override
	int? get amount;
	@override
	String? get type;
	@override
	DateTime? get createdAt;

	/// Create a copy of CoinTransactionModel
	/// with the given fields replaced by the non-null parameter values.
	@override
	@JsonKey(includeFromJson: false, includeToJson: false)
	_$$CoinTransactionModelImplCopyWith<_$CoinTransactionModelImpl>
	get copyWith => throw _privateConstructorUsedError;
}
