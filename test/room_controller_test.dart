import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mixvy/features/room/room_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'test_helpers.dart';
import 'package:mixvy/models/room_model.dart';

void main() {
  setUpAll(() async {
    await testSetup();
  });

  group('RoomController', () {
    late ProviderContainer container;
    setUp(() {
      // Optionally, override providers here if needed
      container = ProviderContainer();
    });

    test('createRoom sets state', () {
      final controller = container.read(roomControllerProvider.notifier);
      final room = RoomModel(
        id: 'room1',
        name: 'Test Room',
        hostId: 'host1',
        createdAt: Timestamp.fromDate(DateTime.now()),
      );
      controller.createRoom(room);
      final state = container.read(roomControllerProvider);
      expect(state?.id, 'room1');
    }, skip: skipIntegrationTests);

    test('leaveRoom clears state', () {
      final controller = container.read(roomControllerProvider.notifier);
      final room = RoomModel(
        id: 'room1',
        name: 'Test Room',
        hostId: 'host1',
        createdAt: Timestamp.fromDate(DateTime.now()),
      );
      controller.createRoom(room);
      controller.leaveRoom();
      final state = container.read(roomControllerProvider);
      expect(state, isNull);
    }, skip: skipIntegrationTests);

    test('updateRoom updates state', () {
      final controller = container.read(roomControllerProvider.notifier);
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
      final state = container.read(roomControllerProvider);
      expect(state?.id, 'room1');
    }, skip: skipIntegrationTests);
  });
}
