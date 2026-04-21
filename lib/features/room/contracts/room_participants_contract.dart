import 'package:mixvy/models/room_participant_model.dart';

bool _sameSet(List<RoomParticipantModel> a, List<RoomParticipantModel> b) {
  final aIds = a.map((e) => e.userId).toSet();
  final bIds = b.map((e) => e.userId).toSet();
  return aIds.length == bIds.length && aIds.difference(bIds).isEmpty;
}

class RoomParticipantsContract {
  static bool shouldRebuild(List<RoomParticipantModel> oldList, List<RoomParticipantModel> newList) {
    return oldList.length != newList.length || !_sameSet(oldList, newList);
  }
}
