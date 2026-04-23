// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'message_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$MessageModel {

 String get id; String get senderId; String get roomId; String get content; DateTime get sentAt;/// 'normal' | 'system' | 'announcement'
 String get type;/// Optional rich-text markup spans (JSON-encoded list of RichSpan).
 String get richText;
/// Create a copy of MessageModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MessageModelCopyWith<MessageModel> get copyWith => _$MessageModelCopyWithImpl<MessageModel>(this as MessageModel, _$identity);

  /// Serializes this MessageModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MessageModel&&(identical(other.id, id) || other.id == id)&&(identical(other.senderId, senderId) || other.senderId == senderId)&&(identical(other.roomId, roomId) || other.roomId == roomId)&&(identical(other.content, content) || other.content == content)&&(identical(other.sentAt, sentAt) || other.sentAt == sentAt)&&(identical(other.type, type) || other.type == type)&&(identical(other.richText, richText) || other.richText == richText));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,senderId,roomId,content,sentAt,type,richText);

@override
String toString() {
  return 'MessageModel(id: $id, senderId: $senderId, roomId: $roomId, content: $content, sentAt: $sentAt, type: $type, richText: $richText)';
}


}

/// @nodoc
abstract mixin class $MessageModelCopyWith<$Res>  {
  factory $MessageModelCopyWith(MessageModel value, $Res Function(MessageModel) _then) = _$MessageModelCopyWithImpl;
@useResult
$Res call({
 String id, String senderId, String roomId, String content, DateTime sentAt, String type, String richText
});




}
/// @nodoc
class _$MessageModelCopyWithImpl<$Res>
    implements $MessageModelCopyWith<$Res> {
  _$MessageModelCopyWithImpl(this._self, this._then);

  final MessageModel _self;
  final $Res Function(MessageModel) _then;

/// Create a copy of MessageModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? senderId = null,Object? roomId = null,Object? content = null,Object? sentAt = null,Object? type = null,Object? richText = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,senderId: null == senderId ? _self.senderId : senderId // ignore: cast_nullable_to_non_nullable
as String,roomId: null == roomId ? _self.roomId : roomId // ignore: cast_nullable_to_non_nullable
as String,content: null == content ? _self.content : content // ignore: cast_nullable_to_non_nullable
as String,sentAt: null == sentAt ? _self.sentAt : sentAt // ignore: cast_nullable_to_non_nullable
as DateTime,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as String,richText: null == richText ? _self.richText : richText // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [MessageModel].
extension MessageModelPatterns on MessageModel {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _MessageModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _MessageModel() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _MessageModel value)  $default,){
final _that = this;
switch (_that) {
case _MessageModel():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _MessageModel value)?  $default,){
final _that = this;
switch (_that) {
case _MessageModel() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String senderId,  String roomId,  String content,  DateTime sentAt,  String type,  String richText)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _MessageModel() when $default != null:
return $default(_that.id,_that.senderId,_that.roomId,_that.content,_that.sentAt,_that.type,_that.richText);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String senderId,  String roomId,  String content,  DateTime sentAt,  String type,  String richText)  $default,) {final _that = this;
switch (_that) {
case _MessageModel():
return $default(_that.id,_that.senderId,_that.roomId,_that.content,_that.sentAt,_that.type,_that.richText);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String senderId,  String roomId,  String content,  DateTime sentAt,  String type,  String richText)?  $default,) {final _that = this;
switch (_that) {
case _MessageModel() when $default != null:
return $default(_that.id,_that.senderId,_that.roomId,_that.content,_that.sentAt,_that.type,_that.richText);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _MessageModel implements MessageModel {
  const _MessageModel({required this.id, required this.senderId, required this.roomId, required this.content, required this.sentAt, this.type = 'normal', this.richText = ''});
  factory _MessageModel.fromJson(Map<String, dynamic> json) => _$MessageModelFromJson(json);

@override final  String id;
@override final  String senderId;
@override final  String roomId;
@override final  String content;
@override final  DateTime sentAt;
/// 'normal' | 'system' | 'announcement'
@override@JsonKey() final  String type;
/// Optional rich-text markup spans (JSON-encoded list of RichSpan).
@override@JsonKey() final  String richText;

/// Create a copy of MessageModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$MessageModelCopyWith<_MessageModel> get copyWith => __$MessageModelCopyWithImpl<_MessageModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$MessageModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _MessageModel&&(identical(other.id, id) || other.id == id)&&(identical(other.senderId, senderId) || other.senderId == senderId)&&(identical(other.roomId, roomId) || other.roomId == roomId)&&(identical(other.content, content) || other.content == content)&&(identical(other.sentAt, sentAt) || other.sentAt == sentAt)&&(identical(other.type, type) || other.type == type)&&(identical(other.richText, richText) || other.richText == richText));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,senderId,roomId,content,sentAt,type,richText);

@override
String toString() {
  return 'MessageModel(id: $id, senderId: $senderId, roomId: $roomId, content: $content, sentAt: $sentAt, type: $type, richText: $richText)';
}


}

/// @nodoc
abstract mixin class _$MessageModelCopyWith<$Res> implements $MessageModelCopyWith<$Res> {
  factory _$MessageModelCopyWith(_MessageModel value, $Res Function(_MessageModel) _then) = __$MessageModelCopyWithImpl;
@override @useResult
$Res call({
 String id, String senderId, String roomId, String content, DateTime sentAt, String type, String richText
});




}
/// @nodoc
class __$MessageModelCopyWithImpl<$Res>
    implements _$MessageModelCopyWith<$Res> {
  __$MessageModelCopyWithImpl(this._self, this._then);

  final _MessageModel _self;
  final $Res Function(_MessageModel) _then;

/// Create a copy of MessageModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? senderId = null,Object? roomId = null,Object? content = null,Object? sentAt = null,Object? type = null,Object? richText = null,}) {
  return _then(_MessageModel(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,senderId: null == senderId ? _self.senderId : senderId // ignore: cast_nullable_to_non_nullable
as String,roomId: null == roomId ? _self.roomId : roomId // ignore: cast_nullable_to_non_nullable
as String,content: null == content ? _self.content : content // ignore: cast_nullable_to_non_nullable
as String,sentAt: null == sentAt ? _self.sentAt : sentAt // ignore: cast_nullable_to_non_nullable
as DateTime,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as String,richText: null == richText ? _self.richText : richText // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
