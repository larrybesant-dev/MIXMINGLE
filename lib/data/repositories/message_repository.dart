import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/message_model.dart';

abstract class MessageRepository {
  Future<List<MessageModel>> getMessages(String roomId);
  Future<void> sendMessage(String roomId, MessageModel message);
}

class MessageRepositoryImpl implements MessageRepository {
  final FirebaseFirestore firestore;
  MessageRepositoryImpl(this.firestore);

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
      return MessageModel(
        id: (data['id'] as String?)?.trim().isNotEmpty == true ? (data['id'] as String).trim() : doc.id,
        senderId: (data['senderId'] as String?) ?? '',
        roomId: (data['roomId'] as String?) ?? roomId,
        content: (data['content'] as String?) ?? '',
        sentAt: _parseSentAt(sentAt),
      );
    }).toList(growable: false);
  }

  @override
  Future<void> sendMessage(String roomId, MessageModel message) async {
    await firestore.collection('rooms').doc(roomId).collection('messages').add(message.toJson());
  }
}
