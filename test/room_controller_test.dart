import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mixvy/features/room/providers/mic_access_provider.dart';
import 'package:mixvy/features/room/providers/participant_providers.dart';
import 'package:mixvy/features/room/providers/room_firestore_provider.dart';
import 'package:mixvy/features/room/room_controller.dart';
import 'package:mixvy/models/room_participant_model.dart';

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
  TestWidgetsFlutterBinding.ensureInitialized();

  group('RoomController', () {
    test('joinRoom keeps the joined user in shared room state', () async {
      final firestore = FakeFirebaseFirestore();
      await firestore.collection('rooms').doc('room-a').set({
        'hostId': 'host-1',
        'isLocked': false,
      });

      final container = ProviderContainer(
        overrides: [roomFirestoreProvider.overrideWithValue(firestore)],
      );
      addTearDown(container.dispose);

      final controller = container.read(
        roomControllerProvider('room-a').notifier,
      );
      final result = await controller.joinRoom(
        'user-1',
        displayName: 'User One',
      );
      final state = container.read(roomControllerProvider('room-a'));

      expect(result.isSuccess, isTrue);
      expect(state.roomId, 'room-a');
      expect(state.currentUserId, 'user-1');
      expect(state.isConnected, isTrue);
      expect(state.users, contains('user-1'));
    });

    test('leaveRoom resets the room session state', () async {
      final firestore = FakeFirebaseFirestore();
      await firestore.collection('rooms').doc('room-a').set({
        'hostId': 'host-1',
        'isLocked': false,
      });

      final container = ProviderContainer(
        overrides: [roomFirestoreProvider.overrideWithValue(firestore)],
      );
      addTearDown(container.dispose);

      final controller = container.read(
        roomControllerProvider('room-a').notifier,
      );
      await controller.joinRoom('user-1', displayName: 'User One');
      await controller.leaveRoom();
      final state = container.read(roomControllerProvider('room-a'));

      expect(state.isConnected, isFalse);
      expect(state.currentUserId, isNull);
      expect(state.users, isEmpty);
    });

    test(
      'requestMic queues listeners when someone else already holds the mic',
      () async {
        final firestore = FakeFirebaseFirestore();
        await firestore.collection('rooms').doc('room-a').set({
          'hostId': 'host-1',
          'isLocked': false,
        });

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
        await controller.joinRoom('user-1', displayName: 'User One');
        final result = await controller.requestMic(userId: 'user-1');

        expect(result, MicRequestResult.queued);
        expect(micAccess.queued, isTrue);
        expect(micAccess.grabbed, isFalse);
      },
    );
  });
}
