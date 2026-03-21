
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mixvy/data/models/room_model.dart';

final homeControllerProvider = StateNotifierProvider<HomeController, List<RoomModel>>(
  (ref) => HomeController(),
);

class HomeController extends StateNotifier<List<RoomModel>> {
  HomeController() : super([]);

  void addRoom(RoomModel room) {
    state = [...state, room];
  }

  void removeRoom(String id) {
    state = state.where((room) => room.id != id).toList();
  }
}
