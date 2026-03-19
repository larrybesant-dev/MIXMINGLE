import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/room_model.dart';
class HomeController extends StateNotifier<List<RoomModel>> {
    String? error;
  HomeController() : super([]);

  Future<void> fetchRooms() async {
    try {
      // Example: Fetch rooms from backend
      // Replace with real API call
      final rooms = <RoomModel>[];
      // ...fetch logic...
      state = rooms;
      error = null;
    } catch (e) {
      error = e.toString();
    }
  }
  void addRoom(RoomModel room) {
    try {
      state = [...state, room];
      error = null;
    } catch (e) {
      error = e.toString();
    }
  }
  void removeRoom(String roomId) {
    try {
      state = state.where((room) => room.id != roomId).toList();
      error = null;
    } catch (e) {
      error = e.toString();
    }
  }
}
