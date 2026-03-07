import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/firestore_schema.dart';

class MessagingService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Create or return existing conversation ID between two users
  Future<String> getOrCreateConversationId(String userA, String userB) async {
    final query = await _firestore
        .collection(FirestorePaths.conversations)
        .where('participants', arrayContains: userA)
        .get();

    for (final doc in query.docs) {
      final participants = List<String>.from(doc['participants']);
      if (participants.contains(userB)) {
        return doc.id;
      }
    }

    final newDoc = await _firestore.collection(FirestorePaths.conversations).add({
      'participants': [userA, userB],
      'lastMessage': null,
      'lastTimestamp': FieldValue.serverTimestamp(),
      'unread': {
        userA: 0,
        userB: 0,
      },
    });

    return newDoc.id;
  }

  /// Send a message
  Future<void> sendMessage({
    required String conversationId,
    required String senderId,
    required String text,
  }) async {
    final messageRef = _firestore
        .collection(FirestorePaths.conversations)
        .doc(conversationId)
        .collection(FirestorePaths.messages)
        .doc();

    await messageRef.set({
      'id': messageRef.id,
      'senderId': senderId,
      'text': text,
      'timestamp': FieldValue.serverTimestamp(),
    });

    final convoRef =
        _firestore.collection(FirestorePaths.conversations).doc(conversationId);

    final convoDoc = await convoRef.get();
    final participants = List<String>.from(convoDoc['participants']);

    final unread = Map<String, dynamic>.from(convoDoc['unread']);
    for (final p in participants) {
      if (p == senderId) continue;
      unread[p] = (unread[p] ?? 0) + 1;
    }

    await convoRef.update({
      'lastMessage': text,
      'lastTimestamp': FieldValue.serverTimestamp(),
      'unread': unread,
    });
  }

  /// Stream messages in a conversation
  Stream<List<Map<String, dynamic>>> streamMessages(String conversationId) {
    return _firestore
        .collection(FirestorePaths.conversations)
        .doc(conversationId)
        .collection(FirestorePaths.messages)
        .orderBy('timestamp', descending: false)
        .snapshots()
        .map((snap) => snap.docs.map((d) => d.data()).toList());
  }

  /// Stream conversation list for a user
  Stream<List<Map<String, dynamic>>> streamConversations(String userId) {
    return _firestore
        .collection(FirestorePaths.conversations)
        .where('participants', arrayContains: userId)
        .orderBy('lastTimestamp', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map((d) {
              final data = d.data();
              data['id'] = d.id;
              return data;
            }).toList());
  }

  /// Mark conversation as read
  Future<void> markAsRead(String conversationId, String userId) async {
    final convoRef =
        _firestore.collection(FirestorePaths.conversations).doc(conversationId);

    final doc = await convoRef.get();
    final unread = Map<String, dynamic>.from(doc['unread']);
    unread[userId] = 0;

    await convoRef.update({'unread': unread});
  }
}

final messagingServiceProvider =
    Provider<MessagingService>((ref) => MessagingService());
