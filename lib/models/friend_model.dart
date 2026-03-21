class FriendModel {
	final String? id;
	final String? name;
	final String? avatarUrl;

	FriendModel({this.id, this.name, this.avatarUrl});

	factory FriendModel.fromJson(Map<String, dynamic> json) => FriendModel(
				id: json['id'],
				name: json['name'],
				avatarUrl: json['avatarUrl'],
			);

	Map<String, dynamic> toJson() => {
				'id': id,
				'name': name,
				'avatarUrl': avatarUrl,
			};
}