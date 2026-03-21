import 'package:freezed_annotation/freezed_annotation.dart';
part 'friend_model.freezed.dart';
part 'friend_model.g.dart';

@freezed
abstract class FriendModel with _$FriendModel {
	const factory FriendModel({
		String? id,
		String? userId,
		String? friendId,
		DateTime? createdAt,
	}) = _FriendModel;

	factory FriendModel.fromJson(Map<String, dynamic> json) => _$FriendModelFromJson(json);
}
