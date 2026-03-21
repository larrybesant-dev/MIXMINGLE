class FriendModel {
	final String? id;
	final String? userId;
	final String? friendId;
	final String? name;
	final String? avatarUrl;

	FriendModel({this.id, this.userId, this.friendId, this.name, this.avatarUrl});

	factory FriendModel.fromJson(Map<String, dynamic> json) => FriendModel(
				id: json['id'],
				userId: json['userId'],
				friendId: json['friendId'],
				name: json['name'],
				avatarUrl: json['avatarUrl'],
			);

	Map<String, dynamic> toJson() => {
				'id': id,
				'userId': userId,
				'friendId': friendId,
				'name': name,
				'avatarUrl': avatarUrl,
			};
}