import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mixvy/features/room/room_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:mixvy/features/room/providers/mic_access_provider.dart';
import 'package:mixvy/features/room/providers/participant_providers.dart';
import 'package:mixvy/features/room/providers/room_firestore_provider.dart';
import 'package:mixvy/models/room_participant_model.dart';
import 'test_helpers.dart';
import 'package:mixvy/models/room_model.dart';

class _SpyMicAccessController extends MicAccessController {
  _SpyMicAccessController() : super(FakeFirebaseFirestore());

  bool queued = false;
  bool grabbed = false;

  @override
  Future<void> requestAccess({
    required String roomId,
    required String requesterId,
    required String hostId,
    int? priority,
  }) async {
    queued = true;
  }

  @override
  Future<void> grabMicDirectly({
    required String roomId,
    required String userId,
  }) async {
    grabbed = true;
  }
}

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
    });

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
    });

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
      controller.updateRoom(updatedRoom.id, {'name': updatedRoom.name});
      final state = container.read(roomControllerProvider);
      expect(state?.id, 'room1');
    });

    test('requestMic queues listeners when someone else already holds the mic', () async {
      final firestore = FakeFirebaseFirestore();
      final micAccess = _SpyMicAccessController();
      final scopedContainer = ProviderContainer(
        overrides: [
          roomFirestoreProvider.overrideWithValue(firestore),
          roomDocStreamProvider.overrideWith(
            (ref, roomId) => Stream.value({'hostId': 'host-1'}),
          ),
          participantsStreamProvider.overrideWith(
            (ref, roomId) => Stream.value([
              RoomParticipantModel(
                userId: 'host-1',
                role: 'host',
                micOn: true,
                joinedAt: DateTime(2026, 1, 1),
                lastActiveAt: DateTime.now(),
              ),
              RoomParticipantModel(
                userId: 'user-1',
                role: 'audience',
                micOn: false,
                joinedAt: DateTime(2026, 1, 1),
                lastActiveAt: DateTime.now(),
              ),
            ]),
          ),
          micAccessControllerProvider.overrideWithValue(micAccess),
        ],
      );
      addTearDown(scopedContainer.dispose);

      final controller = scopedContainer.read(
        roomControllerProvider('room-a').notifier,
      );
      controller.state = const RoomState(
        phase: LiveRoomPhase.joined,
        roomId: 'room-a',
        currentUserId: 'user-1',
        hostId: 'host-1',
        userIds: ['host-1', 'user-1'],
        stableUserIds: ['host-1', 'user-1'],
        speakerIds: ['host-1'],
        participantRolesByUser: {
          'host-1': 'host',
          'user-1': 'audience',
        },
      );

      final result = await controller.requestMic(userId: 'user-1');

      expect(result, MicRequestResult.queued);
      expect(micAccess.queued, isTrue);
      expect(micAccess.grabbed, isFalse);
    });
  });
}
