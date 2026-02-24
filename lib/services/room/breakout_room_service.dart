// lib/services/breakout_room_service.dart

import '../shared/models/breakout_room_model.dart';

class BreakoutRoomService {
  // Future-ready skeleton for breakout room management
  final Map<String, BreakoutRoomModel> _breakoutRooms = {};

  List<BreakoutRoomModel> get rooms => _breakoutRooms.values.toList();

  void createRoom(String name, List<String> participantUids) {
    final roomId = DateTime.now().millisecondsSinceEpoch.toString();
    _breakoutRooms[roomId] = BreakoutRoomModel(
      roomId: roomId,
      name: name,
      participantUids: participantUids,
      createdAt: DateTime.now(),
    );
  }

  void addParticipant(String roomId, String uid) {
    final room = _breakoutRooms[roomId];
    if (room != null && !room.participantUids.contains(uid)) {
      room.participantUids.add(uid);
    }
  }

  void removeParticipant(String roomId, String uid) {
    final room = _breakoutRooms[roomId];
    room?.participantUids.remove(uid);
  }

  void deleteRoom(String roomId) {
    _breakoutRooms.remove(roomId);
  }
}
