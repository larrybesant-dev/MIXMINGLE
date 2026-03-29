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

	Future<List<RoomModel>> getLiveRooms({int limit = 20}) async {
		final snapshot = await _roomsCollection
				.where('isLive', isEqualTo: true)
				.orderBy('updatedAt', descending: true)
				.limit(limit)
				.get();

		return snapshot.docs
				.map((doc) => RoomModel.fromJson(doc.data(), doc.id))
				.toList(growable: false);
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
	}) async {
		final now = FieldValue.serverTimestamp();
		final docRef = _roomsCollection.doc();

		await docRef.set({
			'name': name.trim(),
			'description': description?.trim(),
			'rules': rules?.trim(),
			'hostId': hostId.trim(),
			'isLive': isLive,
			'thumbnailUrl': thumbnailUrl?.trim(),
			'createdAt': now,
			'updatedAt': now,
			'stageUserIds': <String>[],
			'audienceUserIds': <String>[hostId.trim()],
			'memberCount': 1,
			'category': category?.trim(),
			'tags': tags.map((tag) => tag.trim()).where((tag) => tag.isNotEmpty).toList(growable: false),
			'coHosts': <String>[],
			'isLocked': false,
			'slowModeSeconds': 0,
		});

		return docRef.id;
	}

	Future<void> updateRoom(RoomModel room) async {
		await _roomsCollection.doc(room.id).update({
			...room.toJson(),
			'updatedAt': FieldValue.serverTimestamp(),
		});
	}

	Future<void> setRoomLiveStatus(String roomId, {required bool isLive}) async {
		await _roomsCollection.doc(roomId).update({
			'isLive': isLive,
			'updatedAt': FieldValue.serverTimestamp(),
		});
	}

	Future<void> deleteRoom(String roomId) async {
		await _roomsCollection.doc(roomId).delete();
	}
}
