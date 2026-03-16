import '../../data/models/presence_model.dart';
import '../../data/repositories/presence_repository.dart';

class UpdatePresenceUseCase {
  final PresenceRepository repository;
  UpdatePresenceUseCase(this.repository);
  Future<void> call(PresenceModel presence) => repository.updatePresence(presence);
}
