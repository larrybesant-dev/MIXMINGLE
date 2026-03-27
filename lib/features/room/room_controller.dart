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
}

final roomControllerProvider = StateNotifierProvider<RoomController, RoomModel?>(
  (ref) => RoomController(),
);
