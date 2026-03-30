import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/message_model.dart';

abstract class MessageRepository {
  Future<List<MessageModel>> getMessages(String roomId);
  Future<void> sendMessage(String roomId, MessageModel message);
}

class MessageRepositoryImpl implements MessageRepository {
  final FirebaseFirestore firestore;
  MessageRepositoryImpl(this.firestore);

  String _asString(dynamic value, {String fallback = ''}) {
    if (value is String) {
      final trimmed = value.trim();
      if (trimmed.isNotEmpty) {
        return trimmed;
      }
    }
    return fallback;
  }

  DateTime _parseSentAt(dynamic value) {
    if (value is Timestamp) {
      return value.toDate();
    }
    if (value is DateTime) {
      return value;
    }
    if (value is String) {
      final parsed = DateTime.tryParse(value);
      if (parsed != null) {
        return parsed;
      }
    }
    return DateTime.now();
  }

  @override
  Future<List<MessageModel>> getMessages(String roomId) async {
    final snapshot = await firestore
        .collection('rooms')
        .doc(roomId)
        .collection('messages')
        .orderBy('sentAt')
        .get();

    return snapshot.docs.map((doc) {
      final data = doc.data();
      final sentAt = data['sentAt'] ?? data['clientSentAt'];
      final messageId = _asString(data['id'], fallback: doc.id);
      return MessageModel(
        id: messageId,
        senderId: _asString(data['senderId']),
        roomId: _asString(data['roomId'], fallback: roomId),
        content: _asString(data['content']),
        sentAt: _parseSentAt(sentAt),
      );
    }).toList(growable: false);
  }

  @override
  Future<void> sendMessage(String roomId, MessageModel message) async {
    await firestore.collection('rooms').doc(roomId).collection('messages').add(message.toJson());
  }
}
