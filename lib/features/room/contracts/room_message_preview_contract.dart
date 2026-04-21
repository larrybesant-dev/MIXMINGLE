import 'package:mixvy/models/message_model.dart';

class RoomMessagePreviewContract {
  static bool shouldRebuild(List<MessageModel> oldMsgs, List<MessageModel> newMsgs) {
    if (oldMsgs.isEmpty && newMsgs.isEmpty) return false;
    if (oldMsgs.isEmpty || newMsgs.isEmpty) return true;
    final oldLast = oldMsgs.last;
    final newLast = newMsgs.last;
    return oldLast.id != newLast.id || oldLast.sentAt != newLast.sentAt;
  }
}
