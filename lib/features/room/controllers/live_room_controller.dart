import '../room_controller.dart';
import 'room_state.dart';

export '../room_controller.dart'
    show RoomController, MicRequestResult, roomControllerProvider;
export 'room_state.dart' show LiveRoomPhase, RoomState;

typedef LiveRoomController = RoomController;
typedef LiveRoomState = RoomState;

final liveRoomControllerProvider = roomControllerProvider;
