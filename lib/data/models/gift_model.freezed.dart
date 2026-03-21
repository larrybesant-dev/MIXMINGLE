// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark
part of 'gift_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

GiftModel _$GiftModelFromJson(Map<String, dynamic> json) {
  return _GiftModel.fromJson(json);
}

/// @nodoc
mixin _$GiftModel {
  String? get id => throw _privateConstructorUsedError;
  String? get senderId => throw _privateConstructorUsedError;
  String? get receiverId => throw _privateConstructorUsedError;
  int? get amount => throw _privateConstructorUsedError;
  String? get type => throw _privateConstructorUsedError;
  DateTime? get sentAt => throw _privateConstructorUsedError;

  /// Serializes this GiftModel to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of GiftModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $GiftModelCopyWith<GiftModel> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $GiftModelCopyWith<$Res> {
  factory $GiftModelCopyWith(GiftModel value, $Res Function(GiftModel) then) =
      _$GiftModelCopyWithImpl<$Res, GiftModel>;
  @useResult
  $Res call({
    String? id,
    String? senderId,
    String? receiverId,
    int? amount,
    String? type,
    DateTime? sentAt,
  });
}

/// @nodoc
class _$GiftModelCopyWithImpl<$Res, $Val extends GiftModel>
    implements $GiftModelCopyWith<$Res> {
  _$GiftModelCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of GiftModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = freezed,
    Object? senderId = freezed,
    Object? receiverId = freezed,
    Object? amount = freezed,
    Object? type = freezed,
    Object? sentAt = freezed,
  }) {
    return _then(
      _value.copyWith(
            id: freezed == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as String?,
            senderId: freezed == senderId
                ? _value.senderId
                : senderId // ignore: cast_nullable_to_non_nullable
                      as String?,
            receiverId: freezed == receiverId
                ? _value.receiverId
                : receiverId // ignore: cast_nullable_to_non_nullable
                      as String?,
            amount: freezed == amount
                ? _value.amount
                : amount // ignore: cast_nullable_to_non_nullable
                      as int?,
            type: freezed == type
                ? _value.type
                : type // ignore: cast_nullable_to_non_nullable
                      as String?,
            sentAt: freezed == sentAt
                ? _value.sentAt
                : sentAt // ignore: cast_nullable_to_non_nullable
                      as DateTime?,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$GiftModelImplCopyWith<$Res>
    implements $GiftModelCopyWith<$Res> {
  factory _$$GiftModelImplCopyWith(
    _$GiftModelImpl value,
    $Res Function(_$GiftModelImpl) then,
  ) = __$$GiftModelImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String? id,
    String? senderId,
    String? receiverId,
    int? amount,
    String? type,
    DateTime? sentAt,
  });
}

/// @nodoc
class __$$GiftModelImplCopyWithImpl<$Res>
    extends _$GiftModelCopyWithImpl<$Res, _$GiftModelImpl>
    implements _$$GiftModelImplCopyWith<$Res> {
  __$$GiftModelImplCopyWithImpl(
    _$GiftModelImpl _value,
    $Res Function(_$GiftModelImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of GiftModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = freezed,
    Object? senderId = freezed,
    Object? receiverId = freezed,
    Object? amount = freezed,
    Object? type = freezed,
    Object? sentAt = freezed,
  }) {
    return _then(
      _$GiftModelImpl(
        id: freezed == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String?,
        senderId: freezed == senderId
            ? _value.senderId
            : senderId // ignore: cast_nullable_to_non_nullable
                  as String?,
        receiverId: freezed == receiverId
            ? _value.receiverId
            : receiverId // ignore: cast_nullable_to_non_nullable
                  as String?,
        amount: freezed == amount
            ? _value.amount
            : amount // ignore: cast_nullable_to_non_nullable
                  as int?,
        type: freezed == type
            ? _value.type
            : type // ignore: cast_nullable_to_non_nullable
                  as String?,
        sentAt: freezed == sentAt
            ? _value.sentAt
            : sentAt // ignore: cast_nullable_to_non_nullable
                  as DateTime?,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$GiftModelImpl implements _GiftModel {
  const _$GiftModelImpl({
    this.id,
    this.senderId,
    this.receiverId,
    this.amount,
    this.type,
    this.sentAt,
  });

  factory _$GiftModelImpl.fromJson(Map<String, dynamic> json) =>
      _$$GiftModelImplFromJson(json);

  @override
  final String? id;
  @override
  final String? senderId;
  @override
  final String? receiverId;
  @override
  final int? amount;
  @override
  final String? type;
  @override
  final DateTime? sentAt;

  @override
  String toString() {
    return 'GiftModel(id: $id, senderId: $senderId, receiverId: $receiverId, amount: $amount, type: $type, sentAt: $sentAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$GiftModelImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.senderId, senderId) ||
                other.senderId == senderId) &&
            (identical(other.receiverId, receiverId) ||
                other.receiverId == receiverId) &&
            (identical(other.amount, amount) || other.amount == amount) &&
            (identical(other.type, type) || other.type == type) &&
            (identical(other.sentAt, sentAt) || other.sentAt == sentAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode =>
      Object.hash(runtimeType, id, senderId, receiverId, amount, type, sentAt);

  /// Create a copy of GiftModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$GiftModelImplCopyWith<_$GiftModelImpl> get copyWith =>
      __$$GiftModelImplCopyWithImpl<_$GiftModelImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$GiftModelImplToJson(this);
  }
}

abstract class _GiftModel implements GiftModel {
  const factory _GiftModel({
    final String? id,
    final String? senderId,
    final String? receiverId,
    final int? amount,
    final String? type,
    final DateTime? sentAt,
  }) = _$GiftModelImpl;

  factory _GiftModel.fromJson(Map<String, dynamic> json) =
      _$GiftModelImpl.fromJson;

  @override
  String? get id;
  @override
  String? get senderId;
  @override
  String? get receiverId;
  @override
  int? get amount;
  @override
  String? get type;
  @override
  DateTime? get sentAt;

  /// Create a copy of GiftModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$GiftModelImplCopyWith<_$GiftModelImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
