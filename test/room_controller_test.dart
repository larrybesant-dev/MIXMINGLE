import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mixvy/features/room/room_controller.dart';
import 'package:mixvy/models/room_model.dart';

void main() {
  group('RoomController', () {
    late RoomController controller;

    setUp(() {
      controller = RoomController();
    });

    test('createRoom sets state', () {
      final room = RoomModel(
        id: 'room1',
        name: 'Test Room',
        hostId: 'host1',
        createdAt: Timestamp.fromDate(DateTime.now()),
      );
      controller.createRoom(room);
      expect(controller.state?.id, 'room1');
    });

    test('leaveRoom clears state', () {
      final room = RoomModel(
        id: 'room1',
        name: 'Test Room',
        hostId: 'host1',
        createdAt: Timestamp.fromDate(DateTime.now()),
      );
      controller.createRoom(room);
      controller.leaveRoom();
      expect(controller.state, isNull);
    });

    test('updateRoom updates state', () {
      final room = RoomModel(
        id: 'room1',
        name: 'Test Room',
        hostId: 'host1',
        createdAt: Timestamp.fromDate(DateTime.now()),
      );
      controller.createRoom(room);
      final updatedRoom = RoomModel(
        id: 'room1',
        name: 'Updated Room',
        hostId: 'host1',
        createdAt: Timestamp.fromDate(DateTime.now()),
      );
      controller.updateRoom(updatedRoom);
      expect(controller.state?.id, 'room1');
    });
  });
}
