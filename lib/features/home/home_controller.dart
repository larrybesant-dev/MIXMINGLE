
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mixvy/models/room_model.dart';


final homeControllerProvider = NotifierProvider<HomeController, List<RoomModel>>(
  () => HomeController(),
);

class HomeController extends Notifier<List<RoomModel>> {
  @override
  List<RoomModel> build() => [];

  void addRoom(RoomModel room) {
    state = [...state, room];
  }

  void removeRoom(String id) {
    state = state.where((room) => room.id != id).toList();
  }
}
