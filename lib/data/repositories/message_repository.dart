import '../models/message_model.dart';

abstract class MessageRepository {
  Future<List<MessageModel>> getMessages(String roomId);
  Future<void> sendMessage(MessageModel message);
  Future<void> deleteMessage(String messageId);
}
