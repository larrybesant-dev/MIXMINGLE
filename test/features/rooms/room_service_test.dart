import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mix_and_mingle/shared/models/room.dart';
import 'package:mix_and_mingle/features/rooms/services/category_service.dart';
import 'package:mix_and_mingle/features/rooms/services/room_service.dart';

void main() {
  late FakeFirebaseFirestore fakeFirestore;
  late RoomService roomService;
  late CategoryService categoryService;

  setUp(() {
    fakeFirestore = FakeFirebaseFirestore();
    categoryService = CategoryService();
    roomService = RoomService(
      firestore: fakeFirestore,
      categoryService: categoryService,
    );
  });

  group('RoomService - createRoom', () {
    test('creates a room with auto-computed category', () async {
      final room = Room(
        id: '',
        title: 'Music Room',
        description: 'A room for music lovers',
        hostId: 'user123',
        tags: ['music', 'dj'],
        category: '', // Will be auto-computed
        createdAt: DateTime.now(),
        isLive: false,
        viewerCount: 0,
      );

      final createdRoom = await roomService.createRoom(room);

      expect(createdRoom.id, isNotEmpty);
      expect(createdRoom.category, 'Music');
      expect(createdRoom.tags, ['music', 'dj']);
      expect(createdRoom.title, 'Music Room');
    });

    test('normalizes tags when creating room', () async {
      final room = Room(
        id: '',
        title: 'Gaming Room',
        description: 'A room for gamers',
        hostId: 'user123',
        tags: ['GAMING', '  game  ', 'Gaming'],
        category: '',
        createdAt: DateTime.now(),
        isLive: false,
        viewerCount: 0,
      );

      final createdRoom = await roomService.createRoom(room);

      expect(createdRoom.category, 'Gaming');
      expect(createdRoom.tags, ['gaming', 'game']);
    });

    test('throws error for invalid tags', () async {
      final room = Room(
        id: '',
        title: 'Invalid Room',
        description: 'Room with invalid tags',
        hostId: 'user123',
        tags: ['tag with spaces', 'tag@special'],
        category: '',
        createdAt: DateTime.now(),
        isLive: false,
        viewerCount: 0,
      );

      expect(
        () => roomService.createRoom(room),
        throwsArgumentError,
      );
    });

    test('throws error for empty tags', () async {
      final room = Room(
        id: '',
        title: 'No Tags Room',
        description: 'Room with no tags',
        hostId: 'user123',
        tags: [],
        category: '',
        createdAt: DateTime.now(),
        isLive: false,
        viewerCount: 0,
      );

      expect(
        () => roomService.createRoom(room),
        throwsArgumentError,
      );
    });

    test('assigns Other category for unmatched tags', () async {
      final room = Room(
        id: '',
        title: 'Random Room',
        description: 'Room with random tags',
        hostId: 'user123',
        tags: ['random', 'unknown'],
        category: '',
        createdAt: DateTime.now(),
        isLive: false,
        viewerCount: 0,
      );

      final createdRoom = await roomService.createRoom(room);

      expect(createdRoom.category, 'Other');
    });
  });

  group('RoomService - updateRoom', () {
    test('updates room and recomputes category', () async {
      // First create a room
      final room = Room(
        id: '',
        title: 'Music Room',
        description: 'A room for music',
        hostId: 'user123',
        tags: ['music'],
        category: '',
        createdAt: DateTime.now(),
        isLive: false,
        viewerCount: 0,
      );

      final createdRoom = await roomService.createRoom(room);
      expect(createdRoom.category, 'Music');

      // Update with gaming tags
      final updatedRoom = createdRoom.copyWith(
        tags: ['gaming', 'esports'],
      );

      await roomService.updateRoom(updatedRoom);

      // Fetch and verify
      final fetchedRoom = await roomService.fetchRoomById(createdRoom.id);
      expect(fetchedRoom?.category, 'Gaming');
      expect(fetchedRoom?.tags, ['gaming', 'esports']);
    });

    test('throws error when updating room with empty ID', () async {
      final room = Room(
        id: '',
        title: 'Room',
        description: 'Description',
        hostId: 'user123',
        tags: ['music'],
        category: 'Music',
        createdAt: DateTime.now(),
        isLive: false,
        viewerCount: 0,
      );

      expect(
        () => roomService.updateRoom(room),
        throwsArgumentError,
      );
    });
  });

  group('RoomService - fetchRoomsByCategory', () {
    test('fetches rooms by category correctly', () async {
      // Create multiple rooms
      await roomService.createRoom(Room(
        id: '',
        title: 'Music Room 1',
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
        title: 'Gaming Room 1',
        description: 'Gaming',
        hostId: 'user123',
        tags: ['gaming'],
        category: '',
        createdAt: DateTime.now(),
        isLive: false,
        viewerCount: 0,
      ));

      await roomService.createRoom(Room(
        id: '',
        title: 'Music Room 2',
        description: 'More Music',
        hostId: 'user123',
        tags: ['dj'],
        category: '',
        createdAt: DateTime.now(),
        isLive: false,
        viewerCount: 0,
      ));

      // Fetch Music category
      final musicRooms = await roomService.fetchRoomsByCategory('Music').first;

      expect(musicRooms.length, 2);
      expect(musicRooms.every((r) => r.category == 'Music'), true);
    });

    test('throws error for invalid category', () {
      expect(
        () => roomService.fetchRoomsByCategory('InvalidCategory'),
        throwsArgumentError,
      );
    });
  });

  group('RoomService - fetchAllRooms', () {
    test('fetches all rooms', () async {
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

      final allRooms = await roomService.fetchAllRooms().first;

      expect(allRooms.length, 2);
    });
  });

  group('RoomService - updateLiveStatus', () {
    test('updates live status correctly', () async {
      final room = await roomService.createRoom(Room(
        id: '',
        title: 'Room',
        description: 'Description',
        hostId: 'user123',
        tags: ['live'],
        category: '',
        createdAt: DateTime.now(),
        isLive: false,
        viewerCount: 0,
      ));

      await roomService.updateLiveStatus(room.id, true);

      final updatedRoom = await roomService.fetchRoomById(room.id);
      expect(updatedRoom?.isLive, true);
    });
  });

  group('RoomService - updateViewerCount', () {
    test('updates viewer count correctly', () async {
      final room = await roomService.createRoom(Room(
        id: '',
        title: 'Room',
        description: 'Description',
        hostId: 'user123',
        tags: ['live'],
        category: '',
        createdAt: DateTime.now(),
        isLive: false,
        viewerCount: 0,
      ));

      await roomService.updateViewerCount(room.id, 10);

      final updatedRoom = await roomService.fetchRoomById(room.id);
      expect(updatedRoom?.viewerCount, 10);
    });

    test('throws error for negative viewer count', () async {
      final room = await roomService.createRoom(Room(
        id: '',
        title: 'Room',
        description: 'Description',
        hostId: 'user123',
        tags: ['live'],
        category: '',
        createdAt: DateTime.now(),
        isLive: false,
        viewerCount: 0,
      ));

      expect(
        () => roomService.updateViewerCount(room.id, -5),
        throwsArgumentError,
      );
    });
  });

  group('RoomService - deleteRoom', () {
    test('deletes room successfully', () async {
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

      await roomService.deleteRoom(room.id, 'user123');

      final deletedRoom = await roomService.fetchRoomById(room.id);
      expect(deletedRoom, null);
    });
  });
}
