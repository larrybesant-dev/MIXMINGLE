import 'dart:math' as math;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mixvy/models/room_model.dart';

final roomServiceProvider = Provider<RoomService>((ref) {
	return RoomService();
});

class RoomService {
	static const Duration _participantFreshnessWindow = Duration(seconds: 60);

	RoomService({FirebaseFirestore? firestore})
			: _firestore = firestore ?? FirebaseFirestore.instance;

	final FirebaseFirestore _firestore;

	CollectionReference<Map<String, dynamic>> get _roomsCollection =>
			_firestore.collection('rooms');

	Query<Map<String, dynamic>> _liveRoomsQuery({
		required int limit,
		required bool includeAdultRooms,
	}) {
		var query = _roomsCollection.where('isLive', isEqualTo: true);
		if (!includeAdultRooms) {
			query = query.where('isAdult', isEqualTo: false);
		}
		return query.limit(limit);
	}

	Query<Map<String, dynamic>> _upcomingRoomsQuery({
		required int limit,
		required bool includeAdultRooms,
		required Timestamp now,
		required Timestamp cutoff,
	}) {
		var query = _roomsCollection
				.where('isLive', isEqualTo: false)
				.where('scheduledAt', isGreaterThanOrEqualTo: now)
				.where('scheduledAt', isLessThanOrEqualTo: cutoff);
		if (!includeAdultRooms) {
			query = query.where('isAdult', isEqualTo: false);
		}
		return query.limit(limit);
	}

	CollectionReference<Map<String, dynamic>> _participantsCollection(String roomId) =>
			_roomsCollection.doc(roomId).collection('participants');

	String _normalizeRoomId(String roomId) {
		final trimmedRoomId = roomId.trim();
		if (trimmedRoomId.isEmpty) {
			throw ArgumentError.value(roomId, 'roomId', 'roomId cannot be empty');
		}
		return trimmedRoomId;
	}

	DateTime get _freshParticipantCutoff =>
			DateTime.now().subtract(_participantFreshnessWindow);

	Future<bool> _hasFreshParticipants(String roomId) async {
		try {
			final snapshot = await _participantsCollection(roomId)
					.where(
						'lastActiveAt',
						isGreaterThanOrEqualTo: Timestamp.fromDate(_freshParticipantCutoff),
					)
					.limit(1)
					.get();
			return snapshot.docs.isNotEmpty;
		} on FirebaseException {
			// Some production rule sets can restrict participant reads.
			// Fail open here so discovery feed remains usable.
			return true;
		}
	}

	Future<void> _markRoomInactive(String roomId) {
		return _roomsCollection.doc(roomId).set({
			'isLive': false,
			'memberCount': 0,
			'audienceUserIds': <String>[],
			'stageUserIds': <String>[],
			'updatedAt': FieldValue.serverTimestamp(),
		}, SetOptions(merge: true));
	}

	Future<List<RoomModel>> _filterActiveLiveRooms(
			Iterable<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
	) async {
		final activeRooms = <RoomModel>[];
		for (final doc in docs) {
			final room = RoomModel.fromJson(doc.data(), doc.id);
			try {
				if (await _hasFreshParticipants(doc.id)) {
					activeRooms.add(room);
					continue;
				}

				await _markRoomInactive(doc.id);
			} on FirebaseException {
				// Keep the room visible instead of failing the entire feed.
				activeRooms.add(room);
			}
		}
		activeRooms.sort(_compareStableLiveRooms);
		return activeRooms;
	}

	int _compareStableLiveRooms(RoomModel a, RoomModel b) {
		final createdA = a.createdAt?.toDate();
		final createdB = b.createdAt?.toDate();
		final createdCompare = (createdB ?? DateTime.fromMillisecondsSinceEpoch(0))
				.compareTo(createdA ?? DateTime.fromMillisecondsSinceEpoch(0));
		if (createdCompare != 0) {
			return createdCompare;
		}

		return a.id.compareTo(b.id);
	}

	Stream<List<RoomModel>> watchLiveRooms({
		int limit = 30,
		bool includeAdultRooms = true,
	}) {
		return _liveRoomsQuery(limit: limit, includeAdultRooms: includeAdultRooms)
				.snapshots()
				.asyncMap((snapshot) => _filterActiveLiveRooms(snapshot.docs));
	}

	/// Rooms scheduled to start in the next 48 hours, ordered soonest first.
	Stream<List<RoomModel>> watchUpcomingRooms({
		int limit = 10,
		bool includeAdultRooms = true,
	}) {
		final now = Timestamp.now();
		final cutoff = Timestamp.fromDate(
			DateTime.now().add(const Duration(hours: 48)),
		);
		return _upcomingRoomsQuery(
					limit: limit,
					includeAdultRooms: includeAdultRooms,
					now: now,
					cutoff: cutoff,
				)
				.snapshots()
				.map((snap) {
					final rooms = snap.docs
							.map((doc) => RoomModel.fromJson(doc.data(), doc.id))
							.toList(growable: false)
						..sort((a, b) {
								final scheduledA = a.scheduledAt?.toDate()
										?? DateTime.fromMillisecondsSinceEpoch(0);
								final scheduledB = b.scheduledAt?.toDate()
										?? DateTime.fromMillisecondsSinceEpoch(0);
								return scheduledA.compareTo(scheduledB);
							});
					return rooms;
				});
	}

	Future<List<RoomModel>> getUpcomingRooms({
		int limit = 10,
		bool includeAdultRooms = true,
	}) async {
		if (limit <= 0) {
			return const <RoomModel>[];
		}

		final now = Timestamp.now();
		final cutoff = Timestamp.fromDate(
			DateTime.now().add(const Duration(hours: 48)),
		);
		final snapshot = await _upcomingRoomsQuery(
			limit: limit,
			includeAdultRooms: includeAdultRooms,
			now: now,
			cutoff: cutoff,
		).get();

		final rooms = snapshot.docs
				.map((doc) => RoomModel.fromJson(doc.data(), doc.id))
				.toList(growable: false)
			..sort((a, b) {
				final scheduledA = a.scheduledAt?.toDate()
						?? DateTime.fromMillisecondsSinceEpoch(0);
				final scheduledB = b.scheduledAt?.toDate()
						?? DateTime.fromMillisecondsSinceEpoch(0);
				return scheduledA.compareTo(scheduledB);
			});
		return rooms;
	}

	Future<List<RoomModel>> getLiveRooms({
		int limit = 20,
		bool includeAdultRooms = true,
	}) async {
		if (limit <= 0) {
			return const <RoomModel>[];
		}

		final snapshot = await _liveRoomsQuery(
			limit: limit,
			includeAdultRooms: includeAdultRooms,
		).get();

		return _filterActiveLiveRooms(snapshot.docs);
	}

	Future<List<RoomModel>> getRecommendedLiveRooms({
		required int limit,
		Set<String> friendIds = const <String>{},
		Set<String> excludedHostIds = const <String>{},
		bool includeAdultRooms = true,
	}) async {
		if (limit <= 0) {
			return const <RoomModel>[];
		}

		final rooms = await getLiveRooms(
			limit: math.max(limit * 2, limit),
			includeAdultRooms: includeAdultRooms,
		);
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
		bool isAdult = false,
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
			'isAdult': isAdult,
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
