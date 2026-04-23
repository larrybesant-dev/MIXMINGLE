import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:mixvy/features/messaging/models/message_model.dart';

abstract class messageRepository {
  Future<List<MessageModel>> getmessage(String conversationId);
  Future<void> sendmessage(String conversationId, MessageModel message);
  Future<int> debugmessageCount();
}

class messageRepositoryImpl implements messageRepository {
  final FirebaseFirestore firestore;
  messageRepositoryImpl(this.firestore);

  String _asString(dynamic value, {String fallback = ''}) {
    if (value is String) {
      final trimmed = value.trim();
      if (trimmed.isNotEmpty) return trimmed;
    }
    return fallback;
  }

  DateTime _parseDateTime(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is String) {
      return DateTime.tryParse(value) ?? DateTime.now();
    }
    return DateTime.now();
  }

  @override
  Future<List<MessageModel>> getmessage(String conversationId) async {
    final snapshot = await firestore
        .collection('conversations')
        .doc(conversationId)
        .collection('messages')
        .orderBy('createdAt')
        .get();

    return snapshot.docs.map((doc) {
      final data = doc.data();

      return MessageModel(
        id: doc.id,
        conversationId: _asString(data['conversationId'], fallback: conversationId),
        senderId: _asString(data['senderId']),
        senderName: _asString(data['senderName'], fallback: 'Unknown'),
        senderAvatarUrl: data['senderAvatarUrl'],
        content: _asString(data['content']),
        createdAt: _parseDateTime(data['createdAt']),
        expiresAt: data['expiresAt'] != null
            ? _parseDateTime(data['expiresAt'])
            : null,
        editedAt: data['editedAt'] != null
            ? _parseDateTime(data['editedAt'])
            : null,
        isDeleted: data['isDeleted'] ?? false,
        readBy: (data['readBy'] as List?)?.cast<String>() ?? [],
      );
    }).toList(growable: false);
  }

  @override
  Future<void> sendmessage(String conversationId, MessageModel message) async {
    await firestore
        .collection('conversations')
        .doc(conversationId)
        .collection('messages')
        .add(message.toJson());
  }

  @override
  Future<int> debugmessageCount() async {
    final snap = await firestore.collectionGroup('message').get();
    final total = snap.docs.length;
    debugPrint('message FOUND: $total');
    return total;
  }
}
