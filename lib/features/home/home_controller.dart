
import '../../data/models/room_model.dart';
import 'package:state_notifier/state_notifier.dart';
class HomeController extends StateNotifier<List<RoomModel>> {
    String? error;
final homeControllerProvider =
    StateNotifierProvider<HomeController, int>((ref) {
  return HomeController();
});

class HomeController extends void StateNotifier<int> {
  HomeController() : super(0);

  void increment() {
    state++;
  }

  void decrement() {
    state--;
  }
}
