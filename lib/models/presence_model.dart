import 'package:cloud_firestore/cloud_firestore.dart';

enum UserStatus { online, away, dnd, offline }

class PresenceModel {
	final String? id;
	final String? userId;
	final bool? isOnline;
	final DateTime? lastSeen;
	final UserStatus status;
	final String? inRoom;

	PresenceModel({
		this.id,
		this.userId,
		this.isOnline,
		this.lastSeen,
		this.status = UserStatus.offline,
		this.inRoom,
	});

	static String? _asNullableString(dynamic value) {
		if (value is String) {
			final trimmed = value.trim();
			return trimmed.isEmpty ? null : trimmed;
		}
		return null;
	}

	static bool _asBool(dynamic value, {bool fallback = true}) {
		if (value is bool) {
			return value;
		}
		if (value is num) {
			return value != 0;
		}
		if (value is String) {
			final normalized = value.trim().toLowerCase();
			if (normalized == 'true' || normalized == '1') {
				return true;
			}
			if (normalized == 'false' || normalized == '0') {
				return false;
			}
		}
		return fallback;
	}

	static UserStatus _parseStatus(dynamic value) {
		if (value is String) {
			switch (value.trim().toLowerCase()) {
				case 'online': return UserStatus.online;
				case 'away': return UserStatus.away;
				case 'dnd': return UserStatus.dnd;
				default: return UserStatus.offline;
			}
		}
		return UserStatus.offline;
	}

	factory PresenceModel.fromJson(Map<String, dynamic> json) => PresenceModel(
			id: _asNullableString(json['id']),
			userId: _asNullableString(json['userId']),
			isOnline: _asBool(json['isOnline']),
			lastSeen: _parseDateTime(json['lastSeen'] ?? json['lastActiveAt']),
			status: _parseStatus(json['status']),
			inRoom: _asNullableString(json['inRoom']),
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
				'status': status.name,
				'inRoom': inRoom,
			};
}