import '../models/room_model.dart';

abstract class RoomRepository {
  Future<List<RoomModel>> getRooms();
  Future<RoomModel?> getRoom(String roomId);
  Future<void> createRoom(RoomModel room);
  Future<void> updateRoom(RoomModel room);
  Future<void> deleteRoom(String roomId);
}
