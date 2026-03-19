import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/room_model.dart';
class RoomController extends StateNotifier<RoomModel?> {
    String? error;
  RoomController() : super(null);

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
