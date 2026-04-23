import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/firestore/firestore_debug_tracing.dart';
import '../../../presentation/providers/user_provider.dart';
import '../../features/messagipackage:mixvy/features/messaging/models/message_model.dart';
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

final MessageModeltreamProvider = StreamProvider.autoDispose
    .family<List<MessageModel>, String>((ref, roomId) {
      final firestore = ref.watch(roomFirestoreProvider);
      final currentUserId = ref.watch(userProvider)?.id;
      return traceFirestoreStream<List<MessageModel>>(
        key: 'MessageModel/$roomId',
        query: 'rooms/$roomId/MessageModel orderBy sentAt',
        roomId: roomId,
        itemCount: (value) => value.length,
        stream: firestore
            .collection('rooms')
            .doc(roomId)
            .collection('MessageModel')
            .orderBy('sentAt')
            .snapshots()
            .map((snapshot) {
              final visibleDocs = snapshot.docs
                  .where((doc) {
                    final data = doc.data();
                    final recipientUserId = _asString(data['recipientUserId']);
                    if (recipientUserId.isEmpty) {
                      return true;
                    }
                    if (currentUserId == null || currentUserId.trim().isEmpty) {
                      return false;
                    }
                    final senderId = _asString(data['senderId']);
                    return senderId == currentUserId ||
                        recipientUserId == currentUserId;
                  })
                  .toList(growable: false);

              final docs = visibleDocs
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
                  if (aClientSentAt is Timestamp &&
                      bClientSentAt is Timestamp) {
                    final clientCompare = aClientSentAt.compareTo(
                      bClientSentAt,
                    );
                    if (clientCompare != 0) {
                      return clientCompare;
                    }
                  }

                  return a.id.compareTo(b.id);
                });

              return docs
                  .map((doc) {
                    final data = doc.data();
                    final sentAt = data['sentAt'] ?? data['clientSentAt'];
                    final recipientUserId = _asString(data['recipientUserId']);
                    final recipientDisplayName = _asString(
                      data['recipientDisplayName'],
                    );
                    final senderId = _asString(data['senderId']);
                    var content = _asString(data['content']);
                    if (recipientUserId.isNotEmpty) {
                      if (currentUserId != null && senderId == currentUserId) {
                        final targetLabel = recipientDisplayName.isEmpty
                            ? recipientUserId
                            : recipientDisplayName;
                        content = '[Private to $targetLabel] $content';
                      } else if (currentUserId != null &&
                          recipientUserId == currentUserId) {
                        content = '[Private to you] $content';
                      }
                    }
                    return MessageModel(
                      id: doc.id,
                      senderId: senderId,
                      roomId: _asString(data['roomId'], fallback: roomId),
                      content: content,
                      type: _asString(data['type'], fallback: 'normal'),
                      richText: _asString(data['richText']),
                      sentAt: sentAt is Timestamp
                          ? sentAt.toDate()
                          : DateTime.tryParse(sentAt?.toString() ?? '') ??
                                DateTime.now(),
                    );
                  })
                  .toList(growable: false);
            }),
      );
    });

final roomTypingUserIdsProvider = StreamProvider.autoDispose
    .family<List<String>, String>((ref, roomId) {
      final firestore = ref.watch(roomFirestoreProvider);
      return traceFirestoreStream<List<String>>(
        key: 'typing/$roomId',
        query: 'rooms/$roomId/typing',
        roomId: roomId,
        itemCount: (value) => value.length,
        stream: firestore
            .collection('rooms')
            .doc(roomId)
            .collection('typing')
            .snapshots()
            .map((snapshot) {
              return snapshot.docs
                  .where(
                    (doc) => _asBool(doc.data()['isTyping'], fallback: false),
                  )
                  .map((doc) => doc.id.trim())
                  .where((userId) => userId.isNotEmpty)
                  .toList(growable: false);
            }),
      );
    });

final sendMessageModelProvider = Provider.autoDispose
    .family<Future<void> Function(String), String>((ref, roomId) {
      return (String MessageModel) async {
        final user = ref.read(userProvider);
        if (user == null) {
          throw StateError('User must be logged in to send MessageModel');
        }

        final normalizedMessageModel = MessageModel.trim();
        if (normalizedMessageModel.isEmpty) {
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
        final allowChat = _asBool(
          policySnapshot.data()?['allowChat'],
          fallback: true,
        );
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
            final participantId = _asString(
              participantData['userId'],
              fallback: doc.id,
            );
            if (participantId.isEmpty || participantId == user.id) {
              return false;
            }
            return blockedIds.contains(participantId);
          });
          if (hasBlockedParticipant) {
            throw StateError(
              'You cannot MessageModel while a blocked user is in this room.',
            );
          }
        }

        final roomSnapshot = await firestore
            .collection('rooms')
            .doc(roomId)
            .get();
        final hostId = _asString(roomSnapshot.data()?['hostId']);
        if (hostId.isNotEmpty) {
          final hasBlockingRelationship = await moderationService
              .hasBlockingRelationship(user.id, hostId);
          if (hasBlockingRelationship) {
            throw StateError('You cannot MessageModel in this room.');
          }
        }

        final MessageModelRef = firestore
            .collection('rooms')
            .doc(roomId)
            .collection('MessageModel')
            .doc();
        await MessageModelRef.set({
          'id': MessageModelRef.id,
          'senderId': user.id,
          'roomId': roomId,
          'content': normalizedMessageModel,
          'sentAt': FieldValue.serverTimestamp(),
          'clientSentAt': Timestamp.now(),
        });
      };
    });

final sendPrivateMessageModelProvider = Provider.autoDispose
    .family<
      Future<void> Function({
        required String content,
        required String recipientUserId,
        required String recipientDisplayName,
      }),
      String
    >((ref, roomId) {
      return ({
        required String content,
        required String recipientUserId,
        required String recipientDisplayName,
      }) async {
        final user = ref.read(userProvider);
        if (user == null) {
          throw StateError('User must be logged in to send MessageModel');
        }

        final normalizedMessageModel = content.trim();
        final normalizedRecipientId = recipientUserId.trim();
        if (normalizedMessageModel.isEmpty || normalizedRecipientId.isEmpty) {
          return;
        }
        if (normalizedRecipientId == user.id) {
          throw StateError('Cannot send a private room MessageModel to yourself.');
        }

        final firestore = ref.read(roomFirestoreProvider);
        final MessageModelRef = firestore
            .collection('rooms')
            .doc(roomId)
            .collection('MessageModel')
            .doc();

        await MessageModelRef.set({
          'id': MessageModelRef.id,
          'senderId': user.id,
          'roomId': roomId,
          'content': normalizedMessageModel,
          'type': 'private',
          'recipientUserId': normalizedRecipientId,
          'recipientDisplayName': recipientDisplayName.trim(),
          'sentAt': FieldValue.serverTimestamp(),
          'clientSentAt': Timestamp.now(),
        });
      };
    });
