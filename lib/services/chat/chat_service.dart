// lib/services/chat_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../shared/models/chat_message.dart';
import '../../shared/models/chat_room.dart';

class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Get chat rooms for current user
  Future<List<ChatRoom>> getUserChatRooms() async {
    final user = _auth.currentUser;
    if (user == null) return [];

    try {
      // Get all chat rooms for the user
      final query = _firestore.collection('chatRooms').where('participants', arrayContains: user.uid);

      final snapshot = await query.get();
      final rooms = snapshot.docs.map((doc) => ChatRoom.fromMap(doc.data()..['id'] = doc.id)).toList();

      // Sort by last message time in memory
      rooms.sort((a, b) => b.lastMessageTime.compareTo(a.lastMessageTime));

      return rooms;
    } catch (e) {
      // Return empty list instead of throwing to avoid errors on empty database
      return [];
    }
  }

  // Get or create chat room between two users
  Future<ChatRoom> getOrCreateChatRoom(String otherUserId) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    final participants = [user.uid, otherUserId]..sort();
    final roomId = participants.join('_');

    try {
      final docRef = _firestore.collection('chatRooms').doc(roomId);
      final doc = await docRef.get();

      if (doc.exists) {
        return ChatRoom.fromMap(doc.data()!..['id'] = doc.id);
      } else {
        // Create new chat room
        final newRoom = ChatRoom(
          id: roomId,
          participants: participants,
          lastMessage: '',
          lastMessageTime: DateTime.now(),
          unreadCounts: {user.uid: 0, otherUserId: 0},
          isTyping: false,
        );

        await docRef.set(newRoom.toMap());
        return newRoom;
      }
    } catch (e) {
      throw Exception('Failed to get or create chat room: $e');
    }
  }

  // Send message
  Future<void> sendMessage(String roomId, String content,
      {String? imageUrl, String senderName = 'Unknown User'}) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    try {
      final message = ChatMessage(
        id: _firestore.collection('chatRooms').doc(roomId).collection('messages').doc().id,
        roomId: roomId,
        senderId: user.uid,
        senderName: senderName,
        content: content,
        imageUrl: imageUrl,
        timestamp: DateTime.now(),
        isRead: false,
      );

      // Add message to subcollection
      await _firestore.collection('chatRooms').doc(roomId).collection('messages').doc(message.id).set(message.toMap());

      // Update chat room's last message
      await _firestore.collection('chatRooms').doc(roomId).update({
        'lastMessage': content,
        'lastMessageTime': Timestamp.fromDate(message.timestamp),
        'unreadCounts': FieldValue.increment(1), // This would need to be more specific per user
      });
    } catch (e) {
      throw Exception('Failed to send message: $e');
    }
  }

  // Get messages for a chat room
  Future<List<ChatMessage>> getMessages(String roomId, {int limit = 50}) async {
    try {
      final query = _firestore
          .collection('chatRooms')
          .doc(roomId)
          .collection('messages')
          .orderBy('timestamp', descending: true)
          .limit(limit);

      final snapshot = await query.get();
      return snapshot.docs.map((doc) => ChatMessage.fromMap(doc.data()..['id'] = doc.id)).toList().reversed.toList();
    } catch (e) {
      throw Exception('Failed to get messages: $e');
    }
  }

  // Mark messages as read
  Future<void> markMessagesAsRead(String roomId) async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      final batch = _firestore.batch();

      final unreadMessages = await _firestore
          .collection('chatRooms')
          .doc(roomId)
          .collection('messages')
          .where('senderId', isNotEqualTo: user.uid)
          .where('isRead', isEqualTo: false)
          .get();

      for (final doc in unreadMessages.docs) {
        batch.update(doc.reference, {'isRead': true});
      }

      // Reset unread count and record lastReadAt for current user
      await _firestore.collection('chatRooms').doc(roomId).update({
        'unreadCounts.${user.uid}': 0,
        'lastReadAt.${user.uid}': Timestamp.fromDate(DateTime.now()),
      });

      await batch.commit();
    } catch (e) {
      throw Exception('Failed to mark messages as read: $e');
    }
  }

  // Update typing status
  Future<void> updateTypingStatus(String roomId, bool isTyping) async {
    try {
      await _firestore.collection('chatRooms').doc(roomId).update({
        'isTyping': isTyping,
      });
    } catch (e) {
      throw Exception('Failed to update typing status: $e');
    }
  }

  // Stream chat rooms for current user (real-time, no composite index needed)
  Stream<List<ChatRoom>> streamUserChatRooms() {
    final user = _auth.currentUser;
    if (user == null) return Stream.value([]);

    try {
      return _firestore
          .collection('chatRooms')
          .where('participants', arrayContains: user.uid)
          .snapshots()
          .map((snapshot) {
        final rooms = snapshot.docs.map((doc) => ChatRoom.fromMap(doc.data()..['id'] = doc.id)).toList();

        // Sort by last message time in memory
        rooms.sort((a, b) => b.lastMessageTime.compareTo(a.lastMessageTime));
        return rooms;
      }).handleError((error) => Stream.value([]));
    } catch (e) {
      return Stream.value([]);
    }
  }

  // Stream messages for a chat room
  Stream<List<ChatMessage>> streamMessages(String roomId) {
    return _firestore
        .collection('chatRooms')
        .doc(roomId)
        .collection('messages')
        .orderBy('timestamp')
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => ChatMessage.fromMap(doc.data()..['id'] = doc.id)).toList());
  }

  // Stream typing status for a chat room
  Stream<bool> streamTypingStatus(String roomId) {
    return _firestore
        .collection('chatRooms')
        .doc(roomId)
        .snapshots()
        .map((doc) => doc.data()?['isTyping'] as bool? ?? false);
  }

  // Delete message (for current user only - marks as deleted)
  Future<void> deleteMessage(String roomId, String messageId) async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      await _firestore.collection('chatRooms').doc(roomId).collection('messages').doc(messageId).update({
        'deletedBy': FieldValue.arrayUnion([user.uid]),
      });
    } catch (e) {
      throw Exception('Failed to delete message: $e');
    }
  }

  // Report message
  Future<void> reportMessage(String roomId, String messageId, String reason) async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      await _firestore.collection('reportedMessages').add({
        'roomId': roomId,
        'messageId': messageId,
        'reportedBy': user.uid,
        'reason': reason,
        'timestamp': Timestamp.fromDate(DateTime.now()),
      });
    } catch (e) {
      throw Exception('Failed to report message: $e');
    }
  }

  // Convenience alias for common naming pattern
  Stream<List<ChatMessage>> messagesStream(String roomId) => streamMessages(roomId);

  // Stream pinned messages for a chat room
  Stream<List<ChatMessage>> streamPinnedMessages(String roomId) {
    return _firestore
        .collection('chatRooms')
        .doc(roomId)
        .collection('messages')
        .where('isPinned', isEqualTo: true)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => ChatMessage.fromMap(doc.data()..['id'] = doc.id)).toList());
  }

  // Get chat settings for a room
  Future<Map<String, dynamic>> getChatSettings(String roomId) async {
    try {
      final doc = await _firestore.collection('chatRooms').doc(roomId).get();
      return doc.data()?['settings'] as Map<String, dynamic>? ?? {};
    } catch (e) {
      return {};
    }
  }

  // Get message count for a chat room
  Future<int> getMessageCount(String roomId) async {
    try {
      final snapshot = await _firestore.collection('chatRooms').doc(roomId).collection('messages').count().get();
      return snapshot.count ?? 0;
    } catch (e) {
      return 0;
    }
  }

  // Update user presence (online/offline status)
  Future<void> updatePresence(String userId, {required bool isOnline}) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'isOnline': isOnline,
        'lastSeen': Timestamp.fromDate(DateTime.now()),
      });
    } catch (e) {
      throw Exception('Failed to update presence: $e');
    }
  }

  // Set user online
  Future<void> setUserOnline(String userId) async {
    await updatePresence(userId, isOnline: true);
  }

  // Set user offline
  Future<void> setUserOffline(String userId) async {
    await updatePresence(userId, isOnline: false);
  }

  // ---------------------------------------------------------------------------
  // Typing indicators (chatRooms/{roomId}/typing/{userId})
  // ---------------------------------------------------------------------------

  /// Sets or clears a user's typing indicator.
  Future<void> setTyping(
      String roomId, String userId, String userName, bool isTyping) async {
    final ref = _firestore
        .collection('chatRooms')
        .doc(roomId)
        .collection('typing')
        .doc(userId);
    if (!isTyping) {
      await ref.delete().catchError((_) {});
    } else {
      await ref.set({
        'userId': userId,
        'userName': userName.isEmpty ? 'Someone' : userName,
        'timestamp': FieldValue.serverTimestamp(),
      });
    }
  }

  /// Streams display names of users currently typing, excluding [excludeUserId].
  Stream<List<String>> typingUsersStream(String roomId,
      {String? excludeUserId}) {
    return _firestore
        .collection('chatRooms')
        .doc(roomId)
        .collection('typing')
        .snapshots()
        .map((snapshot) {
      final cutoff = DateTime.now().subtract(const Duration(seconds: 30));
      return snapshot.docs
          .where((doc) {
            if (doc.id == excludeUserId) return false;
            final ts = (doc.data()['timestamp'] as Timestamp?)?.toDate();
            return ts != null && ts.isAfter(cutoff);
          })
          .map((doc) => doc.data()['userName'] as String? ?? 'Someone')
          .toList();
    });
  }

  // ---------------------------------------------------------------------------
  // Reactions (reactionsMap: {userId: emoji} stored in message document)
  // ---------------------------------------------------------------------------

  /// Adds or replaces [emoji] reaction by [userId] on a message.
  Future<void> addReaction(
      String roomId, String messageId, String userId, String emoji) async {
    await _firestore
        .collection('chatRooms')
        .doc(roomId)
        .collection('messages')
        .doc(messageId)
        .update({'reactionsMap.$userId': emoji});
  }

  /// Removes [userId]'s reaction from a message.
  Future<void> removeReaction(
      String roomId, String messageId, String userId) async {
    await _firestore
        .collection('chatRooms')
        .doc(roomId)
        .collection('messages')
        .doc(messageId)
        .update({'reactionsMap.$userId': FieldValue.delete()});
  }

  // ---------------------------------------------------------------------------
  // Cursor-based pagination
  // ---------------------------------------------------------------------------

  /// Loads a page of messages ordered oldest-first.
  /// [lastDoc] is the cursor from the previous page (the oldest doc seen).
  Future<(List<ChatMessage>, DocumentSnapshot?)> getMessagesPage(
    String roomId, {
    DocumentSnapshot? lastDoc,
    int limit = 25,
  }) async {
    var query = _firestore
        .collection('chatRooms')
        .doc(roomId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .limit(limit);
    if (lastDoc != null) query = query.startAfterDocument(lastDoc);
    final snapshot = await query.get();
    if (snapshot.docs.isEmpty) return (const <ChatMessage>[], null);
    final messages = snapshot.docs
        .map((doc) => ChatMessage.fromMap(doc.data()..['id'] = doc.id))
        .toList()
        .reversed
        .toList();
    return (messages, snapshot.docs.last);
  }

  // ---------------------------------------------------------------------------
  // Archive
  // ---------------------------------------------------------------------------

  /// Archives a chat room for the current user.
  Future<void> archiveChat(String roomId) async {
    final user = _auth.currentUser;
    if (user == null) return;
    await _firestore.collection('chatRooms').doc(roomId).update({
      'archivedBy': FieldValue.arrayUnion([user.uid]),
    });
  }

  // ---------------------------------------------------------------------------
  // Image / media message
  // ---------------------------------------------------------------------------

  /// Sends a message embedding a remote [imageUrl].
  Future<void> sendImageMessage(
    String roomId,
    String imageUrl,
    String fileName, {
    String senderName = 'Unknown User',
  }) async {
    final user = _auth.currentUser;
    if (user == null) return;
    final docRef = _firestore
        .collection('chatRooms')
        .doc(roomId)
        .collection('messages')
        .doc();
    final msg = ChatMessage(
      id: docRef.id,
      roomId: roomId,
      senderId: user.uid,
      senderName: senderName,
      content: '\u{1F4CE} $fileName',
      imageUrl: imageUrl,
      timestamp: DateTime.now(),
      contentType: MessageContentType.image,
    );
    await docRef.set(msg.toMap());
    await _firestore.collection('chatRooms').doc(roomId).update({
      'lastMessage': '\u{1F4F7} Photo',
      'lastMessageTime': Timestamp.fromDate(msg.timestamp),
    });
  }
}


