import '../../models/presence_model.dart';

class RoomActivityContract {
  static bool shouldRebuild(List<RoomPresenceModel> oldPresence, List<RoomPresenceModel> newPresence, Map<String, bool> oldTyping, Map<String, bool> newTyping) {
    return oldTyping.toString() != newTyping.toString() || oldPresence.toString() != newPresence.toString();
  }
}
