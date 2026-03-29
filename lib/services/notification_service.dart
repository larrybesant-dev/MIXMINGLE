import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/notification_model.dart';

class NotificationService {
	NotificationService({FirebaseFirestore? firestore})
			: _firestore = firestore ?? FirebaseFirestore.instance;

	final FirebaseFirestore _firestore;

	String _safeActorId(String fallbackUserId) {
		try {
			final authUid = FirebaseAuth.instance.currentUser?.uid;
			if (authUid != null && authUid.trim().isNotEmpty) {
				return authUid.trim();
			}
		} catch (_) {
			// FirebaseAuth may be unavailable in unit tests.
		}
		final fallback = fallbackUserId.trim();
		return fallback.isEmpty ? 'system' : fallback;
	}

	Stream<List<NotificationModel>> notificationsForUser(String userId) {
		return _firestore
				.collection('notifications')
				.where('userId', isEqualTo: userId)
				.orderBy('createdAt', descending: true)
				.snapshots()
				.map(
					(snapshot) {
						final docs = snapshot.docs.toList(growable: false)
							..sort((a, b) {
								final aTs = a.data()['createdAt'];
								final bTs = b.data()['createdAt'];
								if (aTs is Timestamp && bTs is Timestamp) {
									return bTs.compareTo(aTs);
								}
								return b.id.compareTo(a.id);
							});

						return docs
								.map((doc) => NotificationModel.fromJson(doc.id, doc.data()))
								.toList(growable: false);
					},
				);
	}

	Future<void> markAllRead(String userId) async {
		final snapshot = await _firestore
				.collection('notifications')
				.where('userId', isEqualTo: userId)
				.where('isRead', isEqualTo: false)
				.get();

		final batch = _firestore.batch();
		for (final doc in snapshot.docs) {
			batch.update(doc.reference, {'isRead': true, 'readAt': FieldValue.serverTimestamp()});
		}
		await batch.commit();
	}

	Future<void> markRead(String userId, String notificationId) async {
		final ref = _firestore.collection('notifications').doc(notificationId);
		final snap = await ref.get();
		if (!snap.exists) {
			return;
		}

		final data = snap.data() as Map<String, dynamic>;
		if ((data['userId'] as String?) != userId) {
			return;
		}

		await ref.update({
			'isRead': true,
			'readAt': FieldValue.serverTimestamp(),
		});
	}

	Future<void> pushNotification(String userId, String message) async {
		final actorId = _safeActorId(userId);
		await _firestore.collection('notifications').add({
			'userId': userId,
			'actorId': actorId,
			'type': 'push',
			'content': message,
			'isRead': false,
			'createdAt': FieldValue.serverTimestamp(),
		});
	}

	Future<void> inAppNotification(String userId, String message) async {
		final actorId = _safeActorId(userId);
		await _firestore.collection('notifications').add({
			'userId': userId,
			'actorId': actorId,
			'type': 'in_app',
			'content': message,
			'isRead': false,
			'createdAt': FieldValue.serverTimestamp(),
		});
	}
}
