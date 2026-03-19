import '../../data/models/message_model.dart';
import '../../data/repositories/message_repository.dart';

class SendMessageUseCase {
  final MessageRepository repository;
  SendMessageUseCase(this.repository);
  Future<void> call(String roomId, MessageModel message) => repository.sendMessage(roomId, message);
}
