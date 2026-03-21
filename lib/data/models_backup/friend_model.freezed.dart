// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'friend_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
	'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

FriendModel _$FriendModelFromJson(Map<String, dynamic> json) {
	return _FriendModel.fromJson(json);
}

/// @nodoc
mixin _$FriendModel {
	String? get id => throw _privateConstructorUsedError;
	String? get userId => throw _privateConstructorUsedError;
	String? get friendId => throw _privateConstructorUsedError;
	DateTime? get createdAt => throw _privateConstructorUsedError;

	/// Serializes this FriendModel to a JSON map.
	Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

	/// Create a copy of FriendModel
	/// with the given fields replaced by the non-null parameter values.
	@JsonKey(includeFromJson: false, includeToJson: false)
	$FriendModelCopyWith<FriendModel> get copyWith =>
			throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $FriendModelCopyWith<$Res> {
	factory $FriendModelCopyWith(
		FriendModel value,
		$Res Function(FriendModel) then,
	) = _$FriendModelCopyWithImpl<$Res, FriendModel>;
	@useResult
	$Res call({
		String? id,
		String? userId,
		String? friendId,
		DateTime? createdAt,
	});
}

/// @nodoc
class _$FriendModelCopyWithImpl<$Res, $Val extends FriendModel>
		implements $FriendModelCopyWith<$Res> {
	_$FriendModelCopyWithImpl(this._value, this._then);

	// ignore: unused_field
	final $Val _value;
	// ignore: unused_field
	final $Res Function($Val) _then;

	/// Create a copy of FriendModel
	/// with the given fields replaced by the non-null parameter values.
	@pragma('vm:prefer-inline')
	@override
	$Res call({
		Object? id = freezed,
		Object? userId = freezed,
		Object? friendId = freezed,
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
						friendId: freezed == friendId
								? _value.friendId
								: friendId // ignore: cast_nullable_to_non_nullable
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
abstract class _$$FriendModelImplCopyWith<$Res>
		implements $FriendModelCopyWith<$Res> {
	factory _$$FriendModelImplCopyWith(
		_$FriendModelImpl value,
		$Res Function(_$FriendModelImpl) then,
	) = __$$FriendModelImplCopyWithImpl<$Res>;
	@override
	@useResult
	$Res call({
		String? id,
		String? userId,
		String? friendId,
		DateTime? createdAt,
	});
}

/// @nodoc
class __$$FriendModelImplCopyWithImpl<$Res>
		extends _$FriendModelCopyWithImpl<$Res, _$FriendModelImpl>
		implements _$$FriendModelImplCopyWith<$Res> {
	__$$FriendModelImplCopyWithImpl(
		_$FriendModelImpl _value,
		$Res Function(_$FriendModelImpl) _then,
	) : super(_value, _then);

	/// Create a copy of FriendModel
	/// with the given fields replaced by the non-null parameter values.
	@pragma('vm:prefer-inline')
	@override
	$Res call({
		Object? id = freezed,
		Object? userId = freezed,
		Object? friendId = freezed,
		Object? createdAt = freezed,
	}) {
		return _then(
			_$FriendModelImpl(
				id: freezed == id
						? _value.id
						: id // ignore: cast_nullable_to_non_nullable
									as String?,
				userId: freezed == userId
						? _value.userId
						: userId // ignore: cast_nullable_to_non_nullable
									as String?,
				friendId: freezed == friendId
						? _value.friendId
						: friendId // ignore: cast_nullable_to_non_nullable
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
class _$FriendModelImpl implements _FriendModel {
	const _$FriendModelImpl({
		this.id,
		this.userId,
		this.friendId,
		this.createdAt,
	});

	factory _$FriendModelImpl.fromJson(Map<String, dynamic> json) =>
			_$$FriendModelImplFromJson(json);

	@override
	final String? id;
	@override
	final String? userId;
	@override
	final String? friendId;
	@override
	final DateTime? createdAt;

	@override
	String toString() {
		return 'FriendModel(id: $id, userId: $userId, friendId: $friendId, createdAt: $createdAt)';
	}

	@override
	bool operator ==(Object other) {
		return identical(this, other) ||
				(other.runtimeType == runtimeType &&
						other is _$FriendModelImpl &&
						(identical(other.id, id) || other.id == id) &&
						(identical(other.userId, userId) || other.userId == userId) &&
						(identical(other.friendId, friendId) ||
								other.friendId == friendId) &&
						(identical(other.createdAt, createdAt) ||
								other.createdAt == createdAt));
	}

	@JsonKey(includeFromJson: false, includeToJson: false)
	@override
	int get hashCode => Object.hash(runtimeType, id, userId, friendId, createdAt);

	/// Create a copy of FriendModel
	/// with the given fields replaced by the non-null parameter values.
	@JsonKey(includeFromJson: false, includeToJson: false)
	@override
	@pragma('vm:prefer-inline')
	_$$FriendModelImplCopyWith<_$FriendModelImpl> get copyWith =>
			__$$FriendModelImplCopyWithImpl<_$FriendModelImpl>(this, _$identity);

	@override
	Map<String, dynamic> toJson() {
		return _$$FriendModelImplToJson(this);
	}
}

abstract class _FriendModel implements FriendModel {
	const factory _FriendModel({
		final String? id,
		final String? userId,
		final String? friendId,
		final DateTime? createdAt,
	}) = _$FriendModelImpl;

	factory _FriendModel.fromJson(Map<String, dynamic> json) =
			_$FriendModelImpl.fromJson;

	@override
	String? get id;
	@override
	String? get userId;
	@override
	String? get friendId;
	@override
	DateTime? get createdAt;

	/// Create a copy of FriendModel
	/// with the given fields replaced by the non-null parameter values.
	@override
	@JsonKey(includeFromJson: false, includeToJson: false)
	_$$FriendModelImplCopyWith<_$FriendModelImpl> get copyWith =>
			throw _privateConstructorUsedError;
}
