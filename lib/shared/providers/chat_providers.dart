// lib/providers/chat_providers.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/chat_message.dart';
import '../models/chat_room.dart';
import '../../services/chat/chat_service.dart';
import '../../services/chat/typing_service.dart';
import '../../services/storage/file_share_service.dart';

final chatServiceProvider = Provider((ref) => ChatService());
final typingServiceProvider = Provider((ref) => TypingService());
final fileShareServiceProvider = Provider((ref) => FileShareService());

/// Conversation list provider - streams all chat rooms for current user
final conversationListProvider = StreamProvider<List<ChatRoom>>((ref) {
  final service = ref.watch(chatServiceProvider);
  return service.streamUserChatRooms();
});

/// Messages provider for a specific chat room (DM or group chat)
final messagesProvider = StreamProvider.family<List<ChatMessage>, String>(
  (ref, roomId) {
    final service = ref.watch(chatServiceProvider);
    return service.streamMessages(roomId);
  },
);

/// Pinned messages provider for a chat room
final pinnedMessagesProvider = StreamProvider.family<List<ChatMessage>, String>(
  (ref, roomId) {
    final service = ref.watch(chatServiceProvider);
    return service.streamPinnedMessages(roomId);
  },
);

/// Typing indicator provider for a chat room
final typingStatusProvider = StreamProvider.family<bool, String>(
  (ref, roomId) {
    final service = ref.watch(chatServiceProvider);
    return service.streamTypingStatus(roomId);
  },
);

/// Presence provider - streams online status for a user from the presence collection.
/// Returns {isOnline: bool, lastSeen: DateTime?} for backward-compat with chat list.
final presenceProvider = StreamProvider.family<Map<String, dynamic>, String>(
  (ref, userId) {
<<<<<<< HEAD
    return FirebaseFirestore.instance.collection('presence').doc(userId).snapshots().map((snapshot) {
=======
    return FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .snapshots()
        .map((snapshot) {
>>>>>>> origin/develop
      if (!snapshot.exists) {
        return {'isOnline': false, 'lastSeen': null};
      }

      final data = snapshot.data()!;
      final state = data['state'] as String? ?? 'offline';
      final lastActive = (data['lastActive'] as Timestamp?)?.toDate();

      // Stale check: if lastActive > 10 min ago, treat as offline
      final isStale = lastActive != null &&
          DateTime.now().difference(lastActive) > const Duration(minutes: 10);

      return {
<<<<<<< HEAD
        'isOnline': state == 'online' && !isStale,
        'lastSeen': lastActive,
=======
        'isOnline': data['isOnline'] ?? false,
        'lastSeen': data['lastSeen'] != null
            ? (data['lastSeen'] as Timestamp).toDate()
            : null,
>>>>>>> origin/develop
      };
    });
  },
);

/// Chat settings provider
final chatSettingsProvider =
    FutureProvider.family<Map<String, dynamic>, String>(
  (ref, roomId) async {
    final service = ref.watch(chatServiceProvider);
    return service.getChatSettings(roomId);
  },
);

/// Message count provider
final messageCountProvider = FutureProvider.family<int, String>(
  (ref, roomId) async {
    final service = ref.watch(chatServiceProvider);
    return service.getMessageCount(roomId);
  },
);
