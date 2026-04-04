import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/presence_model.dart';

class PresenceService {
	final FirebaseFirestore _firestore;

	PresenceService({FirebaseFirestore? firestore})
			: _firestore = firestore ?? FirebaseFirestore.instance;

	DocumentReference<Map<String, dynamic>> _ref(String userId) =>
			_firestore.collection('presence').doc(userId);

	// ── Read ──

	Stream<PresenceModel> watchUserPresence(String userId) {
		return _ref(userId).snapshots().map((doc) {
			final data = doc.data();
			if (data == null) {
				return PresenceModel(
					userId: userId,
					isOnline: false,
					status: UserStatus.offline,
				);
			}
			return PresenceModel.fromJson({'userId': userId, ...data});
		});
	}

	Stream<bool> userPresenceStream(String userId) =>
			watchUserPresence(userId).map((p) => p.isOnline == true);

	// ── Write ──

	Future<void> setStatus(String userId, UserStatus status) async {
		final isOnline = status != UserStatus.offline;
		await _ref(userId).set({
			'isOnline': isOnline,
			'status': status.name,
			'lastSeen': FieldValue.serverTimestamp(),
		}, SetOptions(merge: true));
	}

	/// Legacy helper kept for backwards-compat callers.
	Future<void> setUserOnline(String userId, bool isOnline) =>
			setStatus(userId, isOnline ? UserStatus.online : UserStatus.offline);

	Future<void> setInRoom(String userId, String roomId) async {
		await _ref(userId).set({
			'inRoom': roomId,
			'lastSeen': FieldValue.serverTimestamp(),
		}, SetOptions(merge: true));
	}

	Future<void> clearRoom(String userId) async {
		await _ref(userId).set({
			'inRoom': null,
			'lastSeen': FieldValue.serverTimestamp(),
		}, SetOptions(merge: true));
	}
}
