// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark
part of 'test_freezed_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

TestFreezedModel _$TestFreezedModelFromJson(Map<String, dynamic> json) {
  return _TestFreezedModel.fromJson(json);
}

/// @nodoc
mixin _$TestFreezedModel {
  String? get id => throw _privateConstructorUsedError;
  String? get name => throw _privateConstructorUsedError;

  /// Serializes this TestFreezedModel to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of TestFreezedModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $TestFreezedModelCopyWith<TestFreezedModel> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $TestFreezedModelCopyWith<$Res> {
  factory $TestFreezedModelCopyWith(
    TestFreezedModel value,
    $Res Function(TestFreezedModel) then,
  ) = _$TestFreezedModelCopyWithImpl<$Res, TestFreezedModel>;
  @useResult
  $Res call({String? id, String? name});
}

/// @nodoc
class _$TestFreezedModelCopyWithImpl<$Res, $Val extends TestFreezedModel>
    implements $TestFreezedModelCopyWith<$Res> {
  _$TestFreezedModelCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of TestFreezedModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? id = freezed, Object? name = freezed}) {
    return _then(
      _value.copyWith(
            id: freezed == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as String?,
            name: freezed == name
                ? _value.name
                : name // ignore: cast_nullable_to_non_nullable
                      as String?,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$TestFreezedModelImplCopyWith<$Res>
    implements $TestFreezedModelCopyWith<$Res> {
  factory _$$TestFreezedModelImplCopyWith(
    _$TestFreezedModelImpl value,
    $Res Function(_$TestFreezedModelImpl) then,
  ) = __$$TestFreezedModelImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String? id, String? name});
}

/// @nodoc
class __$$TestFreezedModelImplCopyWithImpl<$Res>
    extends _$TestFreezedModelCopyWithImpl<$Res, _$TestFreezedModelImpl>
    implements _$$TestFreezedModelImplCopyWith<$Res> {
  __$$TestFreezedModelImplCopyWithImpl(
    _$TestFreezedModelImpl _value,
    $Res Function(_$TestFreezedModelImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of TestFreezedModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? id = freezed, Object? name = freezed}) {
    return _then(
      _$TestFreezedModelImpl(
        id: freezed == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String?,
        name: freezed == name
            ? _value.name
            : name // ignore: cast_nullable_to_non_nullable
                  as String?,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$TestFreezedModelImpl implements _TestFreezedModel {
  const _$TestFreezedModelImpl({this.id, this.name});

  factory _$TestFreezedModelImpl.fromJson(Map<String, dynamic> json) =>
      _$$TestFreezedModelImplFromJson(json);

  @override
  final String? id;
  @override
  final String? name;

  @override
  String toString() {
    return 'TestFreezedModel(id: $id, name: $name)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$TestFreezedModelImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.name, name) || other.name == name));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, id, name);

  /// Create a copy of TestFreezedModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$TestFreezedModelImplCopyWith<_$TestFreezedModelImpl> get copyWith =>
      __$$TestFreezedModelImplCopyWithImpl<_$TestFreezedModelImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$TestFreezedModelImplToJson(this);
  }
}

abstract class _TestFreezedModel implements TestFreezedModel {
  const factory _TestFreezedModel({final String? id, final String? name}) =
      _$TestFreezedModelImpl;

  factory _TestFreezedModel.fromJson(Map<String, dynamic> json) =
      _$TestFreezedModelImpl.fromJson;

  @override
  String? get id;
  @override
  String? get name;

  /// Create a copy of TestFreezedModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$TestFreezedModelImplCopyWith<_$TestFreezedModelImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
