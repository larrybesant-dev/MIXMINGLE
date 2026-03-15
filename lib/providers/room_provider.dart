import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod/riverpod.dart';
import '../services/room_service.dart';
import '../models/room_model.dart';

final roomProvider = StreamProvider.family<Room?, String>((ref, roomId) {
  return RoomService().streamRooms().map((rooms) => rooms.firstWhere(
    (room) => room.id == roomId,
    orElse: () => null,
  ));
});
