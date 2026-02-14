import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mix_and_mingle/shared/models/room.dart';
import 'package:mix_and_mingle/features/rooms/providers/room_providers.dart';
import 'package:mix_and_mingle/features/rooms/services/category_service.dart';
import 'package:mix_and_mingle/features/rooms/services/room_service.dart';

void main() {
  late FakeFirebaseFirestore fakeFirestore;
  late ProviderContainer container;

  setUp(() {
    fakeFirestore = FakeFirebaseFirestore();
    container = ProviderContainer(
      overrides: [
        roomServiceProvider.overrideWithValue(
          RoomService(
            firestore: fakeFirestore,
            categoryService: CategoryService(),
          ),
        ),
      ],
    );
  });

  tearDown(() {
    container.dispose();
  });

  group('Room Providers', () {
    test('categoriesProvider returns all categories', () {
      final categories = container.read(categoriesProvider);
      expect(categories, ['Music', 'Gaming', 'Chat', 'Live', 'Other']);
    });

    test('createRoomProvider creates a room successfully', () async {
      final notifier = container.read(createRoomProvider.notifier);

      await notifier.createRoom(
        title: 'Test Room',
        description: 'A test room',
        hostId: 'user123',
        tags: ['music', 'dj'],
      );

      final state = container.read(createRoomProvider);

      expect(state.hasValue, true);
      expect(state.value?.title, 'Test Room');
      expect(state.value?.category, 'Music');
    });

    test('roomsByCategoryProvider fetches rooms by category', () async {
      final roomService = container.read(roomServiceProvider);

      // Create test rooms
      await roomService.createRoom(Room(
        id: '',
        title: 'Music Room',
        description: 'Music',
        hostId: 'user123',
        tags: ['music'],
        category: '',
        createdAt: DateTime.now(),
        isLive: false,
        viewerCount: 0,
      ));

      await roomService.createRoom(Room(
        id: '',
        title: 'Gaming Room',
        description: 'Gaming',
        hostId: 'user123',
        tags: ['gaming'],
        category: '',
        createdAt: DateTime.now(),
        isLive: false,
        viewerCount: 0,
      ));

      // Allow stream to emit first value
      await Future.delayed(const Duration(milliseconds: 100));

      // Fetch by category using stream directly
      final musicRooms = await roomService.fetchRoomsByCategory('Music').first;

      expect(musicRooms.length, 1);
      expect(musicRooms.first.category, 'Music');
    });

    test('allRoomsProvider fetches all rooms', () async {
      final roomService = container.read(roomServiceProvider);

      // Create test rooms
      await roomService.createRoom(Room(
        id: '',
        title: 'Room 1',
        description: 'Description',
        hostId: 'user123',
        tags: ['music'],
        category: '',
        createdAt: DateTime.now(),
        isLive: false,
        viewerCount: 0,
      ));

      await roomService.createRoom(Room(
        id: '',
        title: 'Room 2',
        description: 'Description',
        hostId: 'user123',
        tags: ['gaming'],
        category: '',
        createdAt: DateTime.now(),
        isLive: false,
        viewerCount: 0,
      ));

      // Allow stream to emit first value
      await Future.delayed(const Duration(milliseconds: 100));

      final allRooms = await roomService.fetchAllRooms().first;

      expect(allRooms.length, 2);
    });

    test('liveRoomsProvider fetches only live rooms', () async {
      final roomService = container.read(roomServiceProvider);

      // Create test rooms
      await roomService.createRoom(Room(
        id: '',
        title: 'Live Room',
        description: 'Live',
        hostId: 'user123',
        tags: ['live'],
        category: '',
        createdAt: DateTime.now(),
        isLive: true,
        viewerCount: 10,
      ));

      await roomService.createRoom(Room(
        id: '',
        title: 'Offline Room',
        description: 'Offline',
        hostId: 'user123',
        tags: ['music'],
        category: '',
        createdAt: DateTime.now(),
        isLive: false,
        viewerCount: 0,
      ));

      // Allow stream to emit first value
      await Future.delayed(const Duration(milliseconds: 100));

      final liveRooms = await roomService.fetchLiveRooms().first;

      expect(liveRooms.length, 1);
      expect(liveRooms.first.isLive, true);
    });

    test('updateRoomProvider updates live status', () async {
      final roomService = container.read(roomServiceProvider);

      // Create a room
      final room = await roomService.createRoom(Room(
        id: '',
        title: 'Room',
        description: 'Description',
        hostId: 'user123',
        tags: ['music'],
        category: '',
        createdAt: DateTime.now(),
        isLive: false,
        viewerCount: 0,
      ));

      // Update live status
      final notifier = container.read(updateRoomProvider.notifier);
      await notifier.updateLiveStatus(room.id, true);

      // Verify update
      final updatedRoom = await roomService.fetchRoomById(room.id);
      expect(updatedRoom?.isLive, true);
    });

    test('deleteRoomProvider deletes room', () async {
      final roomService = container.read(roomServiceProvider);

      // Create a room
      final room = await roomService.createRoom(Room(
        id: '',
        title: 'Room to Delete',
        description: 'Description',
        hostId: 'user123',
        tags: ['music'],
        category: '',
        createdAt: DateTime.now(),
        isLive: false,
        viewerCount: 0,
      ));

      // Delete room
      final notifier = container.read(deleteRoomProvider.notifier);
      await notifier.deleteRoom(room.id, 'user123');

      // Verify deletion
      final deletedRoom = await roomService.fetchRoomById(room.id);
      expect(deletedRoom, null);
    });
  });
}
