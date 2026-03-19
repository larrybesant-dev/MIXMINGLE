import 'package:flutter_test/flutter_test.dart';
import 'package:mixvy/features/room/room_controller.dart';
import 'package:mixvy/data/models/room_model.dart';

void main() {
  group('RoomController', () {
    late RoomController controller;

    setUp(() {
      controller = RoomController();
    });

    test('createRoom sets state', () {
      final room = RoomModel(id: 'room1');
      controller.createRoom(room);
      expect(controller.state?.id, 'room1');
    });

    test('leaveRoom clears state', () {
      final room = RoomModel(id: 'room1');
      controller.createRoom(room);
      controller.leaveRoom();
      expect(controller.state, isNull);
    });

    test('updateRoom updates state', () {
      final room = RoomModel(id: 'room1');
      controller.createRoom(room);
      final updatedRoom = RoomModel(id: 'room1');
      controller.updateRoom(updatedRoom);
      expect(controller.state?.id, 'room1');
    });
  });
}
