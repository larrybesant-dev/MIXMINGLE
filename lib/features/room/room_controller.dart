import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mixvy/models/room_model.dart';

final roomControllerProvider =
    StateNotifierProvider<RoomController, RoomModel?>(
  (ref) => RoomController(),
);

class RoomController extends StateNotifier<RoomModel?> {
  RoomController() : super(null);

  void createRoom(RoomModel room) {
    state = room;
  }

  void leaveRoom() {
    state = null;
  }

  void updateRoom(String roomId, Map<String, dynamic> updates) {
    state = state?.id == roomId
        ? state?.copyWith(
            name: updates['name'] as String? ?? state!.name,
            description:
                updates['description'] as String? ?? state!.description,
            isLive: updates['isLive'] as bool? ?? state!.isLive,
          )
        : state;
  }
}
