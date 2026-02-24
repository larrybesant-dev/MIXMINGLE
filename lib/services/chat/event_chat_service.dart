import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../shared/models/chat_message.dart';

class EventChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Watch chat messages for an event in real-time
  Stream<List<ChatMessage>> watchEventChat(String eventId) {
    return _firestore
        .collection('events')
        .doc(eventId)
        .collection('chat')
        .orderBy('timestamp', descending: true)
        .limit(100)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return ChatMessage(
          id: doc.id,
          senderId: data['senderId'] as String,
          senderName: data['senderName'] as String,
          senderAvatarUrl: data['senderAvatarUrl'] as String?,
          content: data['content'] as String,
          timestamp: (data['timestamp'] as Timestamp).toDate(),
          replyToId: data['replyToId'] as String?,
          context: MessageContext.group,
        );
      }).toList();
    });
  }

  /// Send a message to event chat
  Future<void> sendMessage({
    required String eventId,
    required String message,
    required String senderName,
    String? senderAvatarUrl,
    String? replyToId,
  }) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) throw Exception('User not authenticated');

    final messageData = {
      'senderId': userId,
      'senderName': senderName,
      'senderAvatarUrl': senderAvatarUrl,
      'content': message,
      'timestamp': FieldValue.serverTimestamp(),
      'replyToId': replyToId,
    };

    await _firestore.collection('events').doc(eventId).collection('chat').add(messageData);
  }

  /// Delete a message (only sender can delete)
  Future<void> deleteMessage(String eventId, String messageId) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) throw Exception('User not authenticated');

    final messageDoc = await _firestore.collection('events').doc(eventId).collection('chat').doc(messageId).get();

    if (messageDoc.exists && messageDoc.data()?['senderId'] == userId) {
      await messageDoc.reference.delete();
    } else {
      throw Exception('Unauthorized to delete this message');
    }
  }

  /// Get message count for an event
  Future<int> getMessageCount(String eventId) async {
    final snapshot = await _firestore.collection('events').doc(eventId).collection('chat').count().get();
    return snapshot.count ?? 0;
  }
}


