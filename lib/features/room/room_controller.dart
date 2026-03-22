
import '../../models/room_model.dart';

final roomControllerProvider = NotifierProvider<RoomController, RoomModel?>(
  () => RoomController(),
);

class RoomController extends Notifier<RoomModel?> {
  String? error;

  @override
  RoomModel? build() => null;

  void createRoom(RoomModel room) {
    try {
      state = room;
      error = null;
      // Add backend logic
    } catch (e) {
      error = e.toString();
    }
  }

  void joinRoom(String roomId) {
    try {
      // Fetch room by ID and set state
      // Example: state = RoomModel(id: roomId);
      error = null;
    } catch (e) {
      error = e.toString();
    }
  }

  void leaveRoom() {
    try {
      state = null;
      error = null;
    } catch (e) {
      error = e.toString();
    }
  }

  void updateRoom(RoomModel room) {
    try {
      state = room;
      error = null;
    } catch (e) {
      error = e.toString();
    }
  }
}
