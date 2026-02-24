import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Chat message model for Module C
class ChatMessage {
  final String id;
  final String userId;
  final String userName;
  final String userAvatarUrl;
  final String content;
  final DateTime timestamp;
  final bool isSystemMessage;
  final bool isPinned;
  final List<String> reactions;

  ChatMessage({
    required this.id,
    required this.userId,
    required this.userName,
    required this.userAvatarUrl,
    required this.content,
    required this.timestamp,
    this.isSystemMessage = false,
    this.isPinned = false,
    this.reactions = const [],
  });

  factory ChatMessage.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ChatMessage(
      id: doc.id,
      userId: data['userId'] ?? '',
      userName: data['userName'] ?? 'Anonymous',
      userAvatarUrl: data['userAvatarUrl'] ?? '',
      content: data['content'] ?? '',
      timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isSystemMessage: data['isSystemMessage'] ?? false,
      isPinned: data['isPinned'] ?? false,
      reactions: List<String>.from(data['reactions'] ?? []),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'userName': userName,
      'userAvatarUrl': userAvatarUrl,
      'content': content,
      'timestamp': Timestamp.fromDate(timestamp),
      'isSystemMessage': isSystemMessage,
      'isPinned': isPinned,
      'reactions': reactions,
    };
  }

  ChatMessage copyWith({
    String? id,
    String? userId,
    String? userName,
    String? userAvatarUrl,
    String? content,
    DateTime? timestamp,
    bool? isSystemMessage,
    bool? isPinned,
    List<String>? reactions,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      userAvatarUrl: userAvatarUrl ?? this.userAvatarUrl,
      content: content ?? this.content,
      timestamp: timestamp ?? this.timestamp,
      isSystemMessage: isSystemMessage ?? this.isSystemMessage,
      isPinned: isPinned ?? this.isPinned,
      reactions: reactions ?? this.reactions,
    );
  }
}

/// Enhanced Chat Service
class EnhancedChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Send a new chat message
  Future<String> sendMessage({
    required String roomId,
    required String userId,
    required String userName,
    required String userAvatarUrl,
    required String content,
  }) async {
    final docRef = await _firestore.collection('rooms').doc(roomId).collection('chat_messages').add({
      'userId': userId,
      'userName': userName,
      'userAvatarUrl': userAvatarUrl,
      'content': content,
      'timestamp': FieldValue.serverTimestamp(),
      'isSystemMessage': false,
      'isPinned': false,
      'reactions': [],
    });
    return docRef.id;
  }

  /// Pin a message
  Future<void> pinMessage(String roomId, String messageId) async {
    await _firestore
        .collection('rooms')
        .doc(roomId)
        .collection('chat_messages')
        .doc(messageId)
        .update({'isPinned': true});
  }

  /// Unpin a message
  Future<void> unpinMessage(String roomId, String messageId) async {
    await _firestore
        .collection('rooms')
        .doc(roomId)
        .collection('chat_messages')
        .doc(messageId)
        .update({'isPinned': false});
  }

  /// Delete a message
  Future<void> deleteMessage(String roomId, String messageId) async {
    await _firestore.collection('rooms').doc(roomId).collection('chat_messages').doc(messageId).delete();
  }

  /// Add a reaction to a message
  Future<void> addReaction(String roomId, String messageId, String emoji) async {
    final messageRef = _firestore.collection('rooms').doc(roomId).collection('chat_messages').doc(messageId);

    final doc = await messageRef.get();
    final reactions = List<String>.from(doc['reactions'] ?? []);

    if (!reactions.contains(emoji)) {
      reactions.add(emoji);
      await messageRef.update({'reactions': reactions});
    }
  }

  /// Remove a reaction from a message
  Future<void> removeReaction(String roomId, String messageId, String emoji) async {
    final messageRef = _firestore.collection('rooms').doc(roomId).collection('chat_messages').doc(messageId);

    final doc = await messageRef.get();
    final reactions = List<String>.from(doc['reactions'] ?? []);

    reactions.remove(emoji);
    await messageRef.update({'reactions': reactions});
  }

  /// Get messages for a room as a stream
  Stream<List<ChatMessage>> getMessagesStream(String roomId) {
    return _firestore
        .collection('rooms')
        .doc(roomId)
        .collection('chat_messages')
        .orderBy('timestamp', descending: true)
        .limit(100)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => ChatMessage.fromFirestore(doc)).toList();
    });
  }

  /// Get pinned messages
  Stream<List<ChatMessage>> getPinnedMessagesStream(String roomId) {
    return _firestore
        .collection('rooms')
        .doc(roomId)
        .collection('chat_messages')
        .where('isPinned', isEqualTo: true)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => ChatMessage.fromFirestore(doc)).toList();
    });
  }
}

/// Provider for Enhanced Chat Service
final enhancedChatServiceProvider = Provider<EnhancedChatService>((ref) {
  return EnhancedChatService();
});

/// Provider for chat messages in a specific room
final chatMessagesProvider = StreamProvider.family<List<ChatMessage>, String>((ref, roomId) {
  final chatService = ref.watch(enhancedChatServiceProvider);
  return chatService.getMessagesStream(roomId);
});

/// Provider for pinned chat messages in a specific room
final pinnedChatMessagesProvider = StreamProvider.family<List<ChatMessage>, String>((ref, roomId) {
  final chatService = ref.watch(enhancedChatServiceProvider);
  return chatService.getPinnedMessagesStream(roomId);
});


