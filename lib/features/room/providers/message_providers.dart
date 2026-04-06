import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../presentation/providers/user_provider.dart';
import '../../../models/message_model.dart';
import '../../../services/moderation_service.dart';
import 'room_firestore_provider.dart';

bool _asBool(dynamic value, {required bool fallback}) {
	if (value is bool) {
		return value;
	}
	if (value is num) {
		return value != 0;
	}
	if (value is String) {
		final normalized = value.trim().toLowerCase();
		if (normalized == 'true' || normalized == '1' || normalized == 'yes') {
			return true;
		}
		if (normalized == 'false' || normalized == '0' || normalized == 'no') {
			return false;
		}
	}
	return fallback;
}

String _asString(dynamic value, {String fallback = ''}) {
	if (value is String) {
		final trimmed = value.trim();
		if (trimmed.isNotEmpty) {
			return trimmed;
		}
	}
	return fallback;
}

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
							senderId: _asString(data['senderId']),
							roomId: _asString(data['roomId'], fallback: roomId),
							content: _asString(data['content']),						type: _asString(data['type'], fallback: 'normal'),
						richText: _asString(data['richText']),							sentAt: sentAt is Timestamp
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
		final moderationService = ModerationService(firestore: firestore);
		final blockedIds = await moderationService.getExcludedUserIds(user.id);

		final policySnapshot = await firestore
				.collection('rooms')
				.doc(roomId)
				.collection('policies')
				.doc('settings')
				.get();
		final allowChat = _asBool(policySnapshot.data()?['allowChat'], fallback: true);
		if (!allowChat) {
			throw StateError('Chat is currently disabled in this room.');
		}

		if (blockedIds.isNotEmpty) {
			final participantsSnapshot = await firestore
					.collection('rooms')
					.doc(roomId)
					.collection('participants')
					.get();
			final hasBlockedParticipant = participantsSnapshot.docs.any((doc) {
				final participantData = doc.data();
				final participantId = _asString(participantData['userId'], fallback: doc.id);
				if (participantId.isEmpty || participantId == user.id) {
					return false;
				}
				return blockedIds.contains(participantId);
			});
			if (hasBlockedParticipant) {
				throw StateError('You cannot message while a blocked user is in this room.');
			}
		}

		final roomSnapshot = await firestore.collection('rooms').doc(roomId).get();
		final hostId = _asString(roomSnapshot.data()?['hostId']);
		if (hostId.isNotEmpty) {
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
