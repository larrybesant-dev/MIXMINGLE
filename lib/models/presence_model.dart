class PresenceModel {
	final String? id;
	final String? userId;
	final bool? isOnline;
	final DateTime? lastSeen;

	PresenceModel({
		this.id,
		this.userId,
		this.isOnline,
		this.lastSeen,
	});

	factory PresenceModel.fromJson(Map<String, dynamic> json) => PresenceModel(
				id: json['id'],
				userId: json['userId'],
				isOnline: json['isOnline'],
				lastSeen: json['lastSeen'] != null ? DateTime.parse(json['lastSeen']) : null,
			);

	Map<String, dynamic> toJson() => {
				'id': id,
				'userId': userId,
				'isOnline': isOnline,
				'lastSeen': lastSeen?.toIso8601String(),
			};
}