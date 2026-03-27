import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mixvy/models/room_model.dart';

class RoomController extends StateNotifier<RoomModel?> {
  RoomController() : super(null);

  void createRoom(RoomModel room) {
    state = room;
  }

  void leaveRoom() {
    state = null;
  }

  Future<void> updateRoom(String roomId, Map<String, dynamic> data) async {
    if (state != null && state!.id == roomId) {
      state = state!.copyWith(
        name: data['name'] as String?,
        description: data['description'] as String?,
        isLive: data['isLive'] as bool?,
        isLocked: data['isLocked'] as bool?,
        memberCount: data['memberCount'] as int?,
      );
    }
  }
}

final roomControllerProvider = StateNotifierProvider<RoomController, RoomModel?>(
  (ref) => RoomController(),
);
