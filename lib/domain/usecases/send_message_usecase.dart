import '../features/messagipackage:mixvy/features/messaging/models/message_model.dart';
import '../../data/repositories/MessageModel_repository.dart';

class SendMessageModelUseCase {
  final MessageModelRepository repository;
  SendMessageModelUseCase(this.repository);
  Future<void> call(String roomId, MessageModel MessageModel) => repository.sendMessageModel(roomId, MessageModel);
}
