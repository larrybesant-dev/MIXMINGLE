import '../models/presence_model.dart';

abstract class PresenceRepository {
  Future<List<PresenceModel>> getPresence(String roomId);
  Future<void> updatePresence(PresenceModel presence);
}
