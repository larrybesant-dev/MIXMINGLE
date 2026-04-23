import 'package:mixvy/features/messaging/models/message_model.dart';
import '../../data/repositories/message_repository.dart';

class SendmessageUseCase {
  final messageRepository repository;
  SendmessageUseCase(this.repository);
  Future<void> call(String roomId, MessageModel message) =>
      repository.sendmessage(roomId, message);
}
