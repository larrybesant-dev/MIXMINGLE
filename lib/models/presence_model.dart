import 'package:cloud_firestore/cloud_firestore.dart';

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
				isOnline: json['isOnline'] as bool? ?? true,
				lastSeen: _parseDateTime(json['lastSeen'] ?? json['lastActiveAt']),
			);

	static DateTime? _parseDateTime(dynamic value) {
		if (value == null) {
			return null;
		}

		if (value is Timestamp) {
			return value.toDate();
		}

		if (value is DateTime) {
			return value;
		}

		return DateTime.tryParse(value.toString());
	}

	Map<String, dynamic> toJson() => {
				'id': id,
				'userId': userId,
				'isOnline': isOnline,
				'lastSeen': lastSeen?.toIso8601String(),
			};
}