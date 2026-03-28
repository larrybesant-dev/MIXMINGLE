import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../presentation/providers/user_provider.dart';
import '../../../models/message_model.dart';
import '../../../services/moderation_service.dart';
import 'room_firestore_provider.dart';

final messageStreamProvider = StreamProvider.autoDispose.family<List<MessageModel>, String>((ref, roomId) {
	final firestore = ref.watch(roomFirestoreProvider);
	return firestore
			.collection('rooms')
			.doc(roomId)
			.collection('messages')
			.orderBy('sentAt')
			.snapshots()
			.map(
				(snapshot) {
					final docs = snapshot.docs.toList(growable: false)
						..sort((a, b) {
							final aData = a.data();
							final bData = b.data();
							final aSentAt = aData['sentAt'];
							final bSentAt = bData['sentAt'];
							if (aSentAt is Timestamp && bSentAt is Timestamp) {
								final sentAtCompare = aSentAt.compareTo(bSentAt);
								if (sentAtCompare != 0) {
									return sentAtCompare;
								}
							}

							final aClientSentAt = aData['clientSentAt'];
							final bClientSentAt = bData['clientSentAt'];
							if (aClientSentAt is Timestamp && bClientSentAt is Timestamp) {
								final clientCompare = aClientSentAt.compareTo(bClientSentAt);
								if (clientCompare != 0) {
									return clientCompare;
								}
							}

							return a.id.compareTo(b.id);
						});

					return docs.map((doc) {
						final data = doc.data();
						final sentAt = data['sentAt'] ?? data['clientSentAt'];
						return MessageModel(
							id: doc.id,
							senderId: data['senderId'] as String? ?? '',
							roomId: data['roomId'] as String? ?? roomId,
							content: data['content'] as String? ?? '',
							sentAt: sentAt is Timestamp
									? sentAt.toDate()
									: DateTime.tryParse(sentAt?.toString() ?? '') ?? DateTime.now(),
						);
					}).toList(growable: false);
				},
			);
});

final sendMessageProvider =
		Provider.autoDispose.family<Future<void> Function(String), String>((ref, roomId) {
	return (String message) async {
		final user = ref.read(userProvider);
		if (user == null) {
			throw StateError('User must be logged in to send messages');
		}

		final normalizedMessage = message.trim();
		if (normalizedMessage.isEmpty) {
			return;
		}

		final firestore = ref.read(roomFirestoreProvider);
		final roomSnapshot = await firestore.collection('rooms').doc(roomId).get();
		final hostId = (roomSnapshot.data()?['hostId'] as String? ?? '').trim();
		if (hostId.isNotEmpty) {
			final moderationService = ModerationService(firestore: firestore);
			final hasBlockingRelationship = await moderationService.hasBlockingRelationship(user.id, hostId);
			if (hasBlockingRelationship) {
				throw StateError('You cannot message in this room.');
			}
		}

		final messageRef = firestore.collection('rooms').doc(roomId).collection('messages').doc();
		await messageRef.set({
			'id': messageRef.id,
			'senderId': user.id,
			'roomId': roomId,
			'content': normalizedMessage,
			'sentAt': FieldValue.serverTimestamp(),
			'clientSentAt': Timestamp.now(),
		});
	};
});
