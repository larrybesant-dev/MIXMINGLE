import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/room_service.dart';
import '../models/room_model.dart';

final roomListProvider = StreamProvider<List<Room>>((ref) {
  return RoomService().streamRooms();
});
