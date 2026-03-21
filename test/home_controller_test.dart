import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mixvy/features/home/home_controller.dart';
import 'package:mixvy/models/room_model.dart';

void main() {
  group('HomeController', () {
    late HomeController controller;

    setUp(() {
      controller = HomeController();
    });

    test('addRoom adds a room', () {
      final room = RoomModel(
        id: 'room1',
        name: 'Test Room',
        hostId: 'host1',
        createdAt: Timestamp.fromDate(DateTime.now()),
      );
      controller.addRoom(room);
      expect(controller.state.length, 1);
      expect(controller.state.first.id, 'room1');
    });

    test('removeRoom removes a room', () {
      final room = RoomModel(
        id: 'room1',
        name: 'Test Room',
        hostId: 'host1',
        createdAt: Timestamp.fromDate(DateTime.now()),
      );
      controller.addRoom(room);
      controller.removeRoom('room1');
      expect(controller.state.isEmpty, true);
    });
  });
}
