// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'presence_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

PresenceModel _$PresenceModelFromJson(Map<String, dynamic> json) {
  return _PresenceModel.fromJson(json);
}

/// @nodoc
mixin _$PresenceModel {
  String? get id => throw _privateConstructorUsedError;
  String? get userId => throw _privateConstructorUsedError;
  bool? get isOnline => throw _privateConstructorUsedError;
  DateTime? get lastSeen => throw _privateConstructorUsedError;

  /// Serializes this PresenceModel to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of PresenceModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $PresenceModelCopyWith<PresenceModel> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $PresenceModelCopyWith<$Res> {
  factory $PresenceModelCopyWith(
    PresenceModel value,
    $Res Function(PresenceModel) then,
  ) = _$PresenceModelCopyWithImpl<$Res, PresenceModel>;
  @useResult
  $Res call({String? id, String? userId, bool? isOnline, DateTime? lastSeen});
}

/// @nodoc
class _$PresenceModelCopyWithImpl<$Res, $Val extends PresenceModel>
    implements $PresenceModelCopyWith<$Res> {
  _$PresenceModelCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of PresenceModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = freezed,
    Object? userId = freezed,
    Object? isOnline = freezed,
    Object? lastSeen = freezed,
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
            isOnline: freezed == isOnline
                ? _value.isOnline
                : isOnline // ignore: cast_nullable_to_non_nullable
                      as bool?,
            lastSeen: freezed == lastSeen
                ? _value.lastSeen
                : lastSeen // ignore: cast_nullable_to_non_nullable
                      as DateTime?,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$PresenceModelImplCopyWith<$Res>
    implements $PresenceModelCopyWith<$Res> {
  factory _$$PresenceModelImplCopyWith(
    _$PresenceModelImpl value,
    $Res Function(_$PresenceModelImpl) then,
  ) = __$$PresenceModelImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String? id, String? userId, bool? isOnline, DateTime? lastSeen});
}

/// @nodoc
class __$$PresenceModelImplCopyWithImpl<$Res>
    extends _$PresenceModelCopyWithImpl<$Res, _$PresenceModelImpl>
    implements _$$PresenceModelImplCopyWith<$Res> {
  __$$PresenceModelImplCopyWithImpl(
    _$PresenceModelImpl _value,
    $Res Function(_$PresenceModelImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of PresenceModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = freezed,
    Object? userId = freezed,
    Object? isOnline = freezed,
    Object? lastSeen = freezed,
  }) {
    return _then(
      _$PresenceModelImpl(
        id: freezed == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String?,
        userId: freezed == userId
            ? _value.userId
            : userId // ignore: cast_nullable_to_non_nullable
                  as String?,
        isOnline: freezed == isOnline
            ? _value.isOnline
            : isOnline // ignore: cast_nullable_to_non_nullable
                  as bool?,
        lastSeen: freezed == lastSeen
            ? _value.lastSeen
            : lastSeen // ignore: cast_nullable_to_non_nullable
                  as DateTime?,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$PresenceModelImpl implements _PresenceModel {
  const _$PresenceModelImpl({
    this.id,
    this.userId,
    this.isOnline,
    this.lastSeen,
  });

  factory _$PresenceModelImpl.fromJson(Map<String, dynamic> json) =>
      _$$PresenceModelImplFromJson(json);

  @override
  final String? id;
  @override
  final String? userId;
  @override
  final bool? isOnline;
  @override
  final DateTime? lastSeen;

  @override
  String toString() {
    return 'PresenceModel(id: $id, userId: $userId, isOnline: $isOnline, lastSeen: $lastSeen)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$PresenceModelImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.userId, userId) || other.userId == userId) &&
            (identical(other.isOnline, isOnline) ||
                other.isOnline == isOnline) &&
            (identical(other.lastSeen, lastSeen) ||
                other.lastSeen == lastSeen));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, id, userId, isOnline, lastSeen);

  /// Create a copy of PresenceModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$PresenceModelImplCopyWith<_$PresenceModelImpl> get copyWith =>
      __$$PresenceModelImplCopyWithImpl<_$PresenceModelImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$PresenceModelImplToJson(this);
  }
}

abstract class _PresenceModel implements PresenceModel {
  const factory _PresenceModel({
    final String? id,
    final String? userId,
    final bool? isOnline,
    final DateTime? lastSeen,
  }) = _$PresenceModelImpl;

  factory _PresenceModel.fromJson(Map<String, dynamic> json) =
      _$PresenceModelImpl.fromJson;

  @override
  String? get id;
  @override
  String? get userId;
  @override
  bool? get isOnline;
  @override
  DateTime? get lastSeen;

  /// Create a copy of PresenceModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$PresenceModelImplCopyWith<_$PresenceModelImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
