import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/message_model.dart';
import '../models/conversation_model.dart';
import '../../../services/moderation_service.dart';

final firestoreProvider = Provider<FirebaseFirestore>((ref) {
  return FirebaseFirestore.instance;
});

// Stream of all conversations for current user, filtered to exclude blocked users.
final conversationsStreamProvider =
    StreamProvider.family<List<Conversation>, String>((ref, userId) {
  final firestore = ref.watch(firestoreProvider);
  return firestore
      .collection('conversations')
      .where('participantIds', arrayContains: userId)
      .where('isArchived', isEqualTo: false)
      .orderBy('lastMessageAt', descending: true)
      .snapshots()
      .asyncMap((snapshot) async {
    final allConversations = snapshot.docs
        .map((doc) => Conversation.fromJson(doc.data(), doc.id))
        .toList();
    // Remove conversations where the other participant is blocked (either direction).
    try {
      final moderationService = ModerationService();
      final excludedIds = await moderationService.getExcludedUserIds(userId);
      if (excludedIds.isEmpty) return allConversations;
      return allConversations.where((conv) {
        final others = conv.participantIds.where((id) => id != userId);
        return !others.any((id) => excludedIds.contains(id));
      }).toList();
    } catch (_) {
      return allConversations;
    }
  });
});

// Stream of messages in a conversation
final messagesStreamProvider =
    StreamProvider.family<List<Message>, String>((ref, conversationId) {
  final firestore = ref.watch(firestoreProvider);
  return firestore
      .collection('conversations')
      .doc(conversationId)
      .collection('messages')
      .orderBy('createdAt', descending: true)
      .limit(50)
      .snapshots()
      .map((snapshot) {
    return snapshot.docs
        .map((doc) => Message.fromJson(doc.data(), doc.id))
        .toList()
        .reversed
        .toList();
  });
});

// ── Paginated message history ──────────────────────────────────────────────
// Loads older messages on demand (load-more). The live stream above covers the
// most recent 50; this provider fetches pages of 30 preceding those.

const _kMessagePageSize = 30;

class _PaginatedMessagesState {
  const _PaginatedMessagesState({
    this.olderMessages = const [],
    this.isLoading = false,
    this.hasMore = true,
    this.oldestDoc,
  });

  final List<Message> olderMessages;
  final bool isLoading;
  final bool hasMore;
  final DocumentSnapshot? oldestDoc;

  _PaginatedMessagesState copyWith({
    List<Message>? olderMessages,
    bool? isLoading,
    bool? hasMore,
    DocumentSnapshot? oldestDoc,
    bool clearOldest = false,
  }) {
    return _PaginatedMessagesState(
      olderMessages: olderMessages ?? this.olderMessages,
      isLoading: isLoading ?? this.isLoading,
      hasMore: hasMore ?? this.hasMore,
      oldestDoc: clearOldest ? null : (oldestDoc ?? this.oldestDoc),
    );
  }
}

class _PaginatedMessagesNotifier
    extends StateNotifier<_PaginatedMessagesState> {
  _PaginatedMessagesNotifier(this._firestore, this._conversationId)
      : super(const _PaginatedMessagesState());

  final FirebaseFirestore _firestore;
  final String _conversationId;

  Future<void> loadMore(DocumentSnapshot? liveAnchor) async {
    if (state.isLoading || !state.hasMore) return;
    state = state.copyWith(isLoading: true);

    try {
      // Start after the earliest doc we already have, or the live-stream anchor.
      final cursor = state.oldestDoc ?? liveAnchor;
      var query = _firestore
          .collection('conversations')
          .doc(_conversationId)
          .collection('messages')
          .orderBy('createdAt', descending: true)
          .limit(_kMessagePageSize);

      if (cursor != null) query = query.startAfterDocument(cursor);

      final snapshot = await query.get();
      final fetched = snapshot.docs
          .map((doc) => Message.fromJson(doc.data(), doc.id))
          .toList()
          .reversed
          .toList();

      state = state.copyWith(
        olderMessages: [...fetched, ...state.olderMessages],
        isLoading: false,
        hasMore: snapshot.docs.length == _kMessagePageSize,
        oldestDoc: snapshot.docs.isNotEmpty ? snapshot.docs.last : state.oldestDoc,
      );
    } catch (_) {
      state = state.copyWith(isLoading: false);
    }
  }
}

final paginatedMessagesProvider = StateNotifierProvider.autoDispose
    .family<_PaginatedMessagesNotifier, _PaginatedMessagesState, String>(
  (ref, conversationId) => _PaginatedMessagesNotifier(
    ref.watch(firestoreProvider),
    conversationId,
  ),
);

// Controller for sending messages
final messagingControllerProvider =
    Provider<MessagingController>((ref) {
  final firestore = ref.watch(firestoreProvider);
  return MessagingController(firestore: firestore);
});

class MessagingController {
  final FirebaseFirestore _firestore;

  MessagingController({required FirebaseFirestore firestore}) : _firestore = firestore;

  Future<void> sendMessage({
    required String conversationId,
    required String senderId,
    required String senderName,
    required String? senderAvatarUrl,
    required String content,
  }) async {
    final now = DateTime.now();
    
    // Add message to messages subcollection
    await _firestore
        .collection('conversations')
        .doc(conversationId)
        .collection('messages')
        .add({
      'conversationId': conversationId,
      'senderId': senderId,
      'senderName': senderName,
      'senderAvatarUrl': senderAvatarUrl,
      'content': content,
      'createdAt': Timestamp.fromDate(now),
      'isDeleted': false,
      'readBy': [senderId],
    });

    // Update conversation with last message info
    final convRef = _firestore.collection('conversations').doc(conversationId);
    await convRef.update({
      'lastMessagePreview': content,
      'lastMessageSenderId': senderId,
      'lastMessageAt': Timestamp.fromDate(now),
    });
  }

  Future<String> createDirectConversation({
    required String userId1,
    required String user1Name,
    required String? user1AvatarUrl,
    required String userId2,
    required String user2Name,
    required String? user2AvatarUrl,
  }) async {
    // Prevent messaging blocked users.
    final isBlocked = await ModerationService().hasBlockingRelationship(userId1, userId2);
    if (isBlocked) throw Exception('Cannot start a conversation with this user.');

    // Check if conversation already exists
    final existing = await _firestore
        .collection('conversations')
        .where('type', isEqualTo: 'direct')
        .where('participantIds', arrayContains: userId1)
        .get();

    for (final doc in existing.docs) {
      final conv = Conversation.fromJson(doc.data(), doc.id);
      if (conv.participantIds.contains(userId2)) {
        return doc.id;
      }
    }

    // Create new conversation
    final now = DateTime.now();
    final docRef = await _firestore.collection('conversations').add({
      'type': 'direct',
      'participantIds': [userId1, userId2],
      'participantNames': {
        userId1: user1Name,
        userId2: user2Name,
      },
      'createdAt': Timestamp.fromDate(now),
      'lastReadAt': {
        userId1: Timestamp.fromDate(now),
        userId2: Timestamp.fromDate(now),
      },
      'isArchived': false,
    });

    return docRef.id;
  }

  Future<String> createGroupConversation({
    required String groupName,
    required String? groupAvatarUrl,
    required List<String> participantIds,
    required Map<String, String> participantNames,
  }) async {
    final now = DateTime.now();
    final lastReadAt = <String, dynamic>{};
    for (final id in participantIds) {
      lastReadAt[id] = Timestamp.fromDate(now);
    }

    final docRef = await _firestore.collection('conversations').add({
      'type': 'group',
      'groupName': groupName,
      'groupAvatarUrl': groupAvatarUrl,
      'participantIds': participantIds,
      'participantNames': participantNames,
      'createdAt': Timestamp.fromDate(now),
      'lastReadAt': lastReadAt,
      'isArchived': false,
    });

    return docRef.id;
  }

  Future<void> markAsRead({
    required String conversationId,
    required String userId,
  }) async {
    await _firestore
        .collection('conversations')
        .doc(conversationId)
        .update({
      'lastReadAt.$userId': Timestamp.fromDate(DateTime.now()),
    });
  }

  Future<void> deleteMessage({
    required String conversationId,
    required String messageId,
  }) async {
    await _firestore
        .collection('conversations')
        .doc(conversationId)
        .collection('messages')
        .doc(messageId)
        .update({'isDeleted': true});
  }

  Future<void> archiveConversation({
    required String conversationId,
  }) async {
    await _firestore
        .collection('conversations')
        .doc(conversationId)
        .update({'isArchived': true});
  }
}
