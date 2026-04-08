import 'dart:math' as math;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mixvy/models/room_model.dart';

final roomServiceProvider = Provider<RoomService>((ref) {
	return RoomService();
});

class RoomService {
	RoomService({FirebaseFirestore? firestore})
			: _firestore = firestore ?? FirebaseFirestore.instance;

	final FirebaseFirestore _firestore;

	CollectionReference<Map<String, dynamic>> get _roomsCollection =>
			_firestore.collection('rooms');

	String _normalizeRoomId(String roomId) {
		final trimmedRoomId = roomId.trim();
		if (trimmedRoomId.isEmpty) {
			throw ArgumentError.value(roomId, 'roomId', 'roomId cannot be empty');
		}
		return trimmedRoomId;
	}

	Stream<List<RoomModel>> watchLiveRooms({int limit = 30}) {
		return _roomsCollection
				.where('isLive', isEqualTo: true)
				.orderBy('updatedAt', descending: true)
				.limit(limit)
				.snapshots()
				.map((snapshot) {
			return snapshot.docs
					.map((doc) => RoomModel.fromJson(doc.data(), doc.id))
					.toList(growable: false);
		});
	}

	/// Rooms scheduled to start in the next 48 hours, ordered soonest first.
	Stream<List<RoomModel>> watchUpcomingRooms({int limit = 10}) {
		final now = Timestamp.now();
		final cutoff = Timestamp.fromDate(
			DateTime.now().add(const Duration(hours: 48)),
		);
		return _roomsCollection
				.where('isLive', isEqualTo: false)
				.where('scheduledAt', isGreaterThanOrEqualTo: now)
				.where('scheduledAt', isLessThanOrEqualTo: cutoff)
				.orderBy('scheduledAt')
				.limit(limit)
				.snapshots()
				.map((snap) => snap.docs
						.map((doc) => RoomModel.fromJson(doc.data(), doc.id))
						.toList(growable: false));
	}

	Future<List<RoomModel>> getLiveRooms({int limit = 20}) async {
		if (limit <= 0) {
			return const <RoomModel>[];
		}

		final snapshot = await _roomsCollection
				.where('isLive', isEqualTo: true)
				.orderBy('updatedAt', descending: true)
				.limit(limit)
				.get();

		return snapshot.docs
				.map((doc) => RoomModel.fromJson(doc.data(), doc.id))
				.toList(growable: false);
	}

	Future<List<RoomModel>> getRecommendedLiveRooms({
		required int limit,
		Set<String> friendIds = const <String>{},
		Set<String> excludedHostIds = const <String>{},
	}) async {
		if (limit <= 0) {
			return const <RoomModel>[];
		}

		final rooms = await getLiveRooms(limit: math.max(limit * 2, limit));
		final filtered = rooms
				.where((room) => !excludedHostIds.contains(room.hostId))
				.toList(growable: false);

		final sorted = filtered.toList(growable: false)
			..sort((a, b) {
				final scoreB = _scoreRoom(b, friendIds);
				final scoreA = _scoreRoom(a, friendIds);
				final scoreCompare = scoreB.compareTo(scoreA);
				if (scoreCompare != 0) {
					return scoreCompare;
				}

				final updatedA = a.updatedAt?.toDate() ?? DateTime.fromMillisecondsSinceEpoch(0);
				final updatedB = b.updatedAt?.toDate() ?? DateTime.fromMillisecondsSinceEpoch(0);
				return updatedB.compareTo(updatedA);
			});

		return sorted.take(limit).toList(growable: false);
	}

	String getRecommendationReason(RoomModel room, {Set<String> friendIds = const <String>{}}) {
		if (friendIds.contains(room.hostId)) {
			return 'Friend is hosting';
		}

		final friendPresenceCount = room.members.where((memberId) => friendIds.contains(memberId)).length;
		if (friendPresenceCount > 1) {
			return '$friendPresenceCount friends are here';
		}
		if (friendPresenceCount == 1) {
			return '1 friend is here';
		}

		if (room.memberCount >= 25) {
			return 'Popular right now';
		}

		final updatedAt = room.updatedAt?.toDate();
		if (updatedAt != null && DateTime.now().difference(updatedAt).inMinutes <= 20) {
			return 'Just started';
		}

		return 'Active now';
	}

	String getRecommendationTier(RoomModel room, {Set<String> friendIds = const <String>{}}) {
		if (friendIds.contains(room.hostId)) {
			return 'Friends';
		}

		final friendPresenceCount = room.members.where((memberId) => friendIds.contains(memberId)).length;
		if (friendPresenceCount > 0) {
			return 'Friends';
		}

		if (room.memberCount >= 25) {
			return 'Hot';
		}

		final updatedAt = room.updatedAt?.toDate();
		if (updatedAt != null && DateTime.now().difference(updatedAt).inMinutes <= 20) {
			return 'Fresh';
		}

		return 'Live';
	}

	double _scoreRoom(RoomModel room, Set<String> friendIds) {
		final memberCountScore = room.memberCount.clamp(0, 120).toDouble() * 0.8;

		final hostFriendBonus = friendIds.contains(room.hostId) ? 25.0 : 0.0;

		final friendPresenceCount = room.members.where((memberId) => friendIds.contains(memberId)).length;
		final friendPresenceBonus = math.min(friendPresenceCount * 6.0, 24.0);

		final updatedAt = room.updatedAt?.toDate();
		double recencyBonus = 0;
		if (updatedAt != null) {
			final minutesAgo = DateTime.now().difference(updatedAt).inMinutes;
			recencyBonus = math.max(0, 18 - (minutesAgo / 8));
		}

		final lockPenalty = room.isLocked ? -6.0 : 0.0;

		return memberCountScore + hostFriendBonus + friendPresenceBonus + recencyBonus + lockPenalty;
	}

	Stream<RoomModel?> watchRoomById(String roomId) {
		final trimmedRoomId = roomId.trim();
		if (trimmedRoomId.isEmpty) {
			return Stream<RoomModel?>.value(null);
		}

		return _roomsCollection.doc(trimmedRoomId).snapshots().map((doc) {
			final data = doc.data();
			if (!doc.exists || data == null) {
				return null;
			}
			return RoomModel.fromJson(data, doc.id);
		});
	}

	Future<RoomModel?> getRoomById(String roomId) async {
		final trimmedRoomId = roomId.trim();
		if (trimmedRoomId.isEmpty) {
			return null;
		}

		final doc = await _roomsCollection.doc(trimmedRoomId).get();
		if (!doc.exists) {
			return null;
		}

		final data = doc.data();
		if (data == null) {
			return null;
		}

		return RoomModel.fromJson(data, doc.id);
	}

	Future<String> createRoom({
		required String hostId,
		required String name,
		String? description,
		String? rules,
		bool isLive = true,
		String? thumbnailUrl,
		String? category,
		List<String> tags = const <String>[],
		DateTime? scheduledAt,
	}) async {
		final trimmedHostId = hostId.trim();
		final trimmedName = name.trim();
		if (trimmedHostId.isEmpty) {
			throw ArgumentError.value(hostId, 'hostId', 'hostId cannot be empty');
		}
		if (trimmedName.isEmpty) {
			throw ArgumentError.value(name, 'name', 'name cannot be empty');
		}

		final now = FieldValue.serverTimestamp();
		final docRef = _roomsCollection.doc();

		await docRef.set({
			'name': trimmedName,
			'description': description?.trim(),
			'rules': rules?.trim(),
			'hostId': trimmedHostId,
			'isLive': isLive,
			'thumbnailUrl': thumbnailUrl?.trim(),
			'createdAt': now,
			'updatedAt': now,
			'stageUserIds': <String>[],
			'audienceUserIds': <String>[trimmedHostId],
			'memberCount': 1,
			'category': category?.trim(),
			'tags': tags.map((tag) => tag.trim()).where((tag) => tag.isNotEmpty).toList(growable: false),
			'coHosts': <String>[],
			'isLocked': false,
			'slowModeSeconds': 0,
			if (scheduledAt != null) 'scheduledAt': Timestamp.fromDate(scheduledAt),
		});

		return docRef.id;
	}

	Future<void> updateRoom(RoomModel room) async {
		final roomId = _normalizeRoomId(room.id);
		await _roomsCollection.doc(roomId).update({
			...room.toJson(),
			'updatedAt': FieldValue.serverTimestamp(),
		});
	}

	Future<void> setRoomLiveStatus(String roomId, {required bool isLive}) async {
		final normalizedRoomId = _normalizeRoomId(roomId);
		await _roomsCollection.doc(normalizedRoomId).update({
			'isLive': isLive,
			'updatedAt': FieldValue.serverTimestamp(),
		});
	}

	Future<void> deleteRoom(String roomId) async {
		final normalizedRoomId = _normalizeRoomId(roomId);
		await _roomsCollection.doc(normalizedRoomId).delete();
	}
}
