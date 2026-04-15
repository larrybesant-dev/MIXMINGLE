import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mixvy/features/room/providers/mic_access_provider.dart';
import 'package:mixvy/features/room/providers/participant_providers.dart';
import 'package:mixvy/features/room/providers/room_firestore_provider.dart';
import 'package:mixvy/features/room/room_controller.dart';
import 'package:mixvy/features/room/services/room_session_service.dart';
import 'package:mixvy/models/presence_model.dart';
import 'package:mixvy/models/room_participant_model.dart';
import 'package:mixvy/services/presence_controller.dart';

class _SpyMicAccessController extends MicAccessController {
  _SpyMicAccessController() : super(FakeFirebaseFirestore());

  bool queued = false;
  bool grabbed = false;
  bool cancelled = false;

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

  @override
  Future<void> cancelRequest(String roomId, String requestId) async {
    cancelled = true;
  }
}

class _TestPresenceController extends PresenceController {
  @override
  PresenceControllerState build() => const PresenceControllerState();

  @override
  Future<void> setInRoom(String userId, String roomId) async {}

  @override
  Future<void> clearInRoom(String userId) async {}
}

class _FlakyRoomSessionService extends RoomSessionService {
  _FlakyRoomSessionService({
    required super.firestore,
    required super.presenceController,
    this.joinFailuresRemaining = 0,
    this.heartbeatFailuresRemaining = 0,
  });

  int joinFailuresRemaining;
  int heartbeatFailuresRemaining;

  @override
  Future<RoomJoinResult> joinRoom({
    required String roomId,
    required String userId,
    String? displayName,
    String? photoUrl,
  }) async {
    if (joinFailuresRemaining > 0) {
      joinFailuresRemaining -= 1;
      throw StateError('simulated join failure');
    }
    return super.joinRoom(
      roomId: roomId,
      userId: userId,
      displayName: displayName,
      photoUrl: photoUrl,
    );
  }

  @override
  Future<DateTime> heartbeat({
    required String roomId,
    required String userId,
    DateTime? lastParticipantSyncAt,
    bool forceParticipantSync = false,
  }) async {
    if (heartbeatFailuresRemaining > 0) {
      heartbeatFailuresRemaining -= 1;
      throw StateError('simulated heartbeat failure');
    }
    return super.heartbeat(
      roomId: roomId,
      userId: userId,
      lastParticipantSyncAt: lastParticipantSyncAt,
      forceParticipantSync: forceParticipantSync,
    );
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

    test('cancelMicRequest lets a listener lower their hand', () async {
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
          roomMemberUserIdsProvider.overrideWith(
            (ref, roomId) => Stream.value(const <String>['host-1', 'user-1']),
          ),
          micAccessControllerProvider.overrideWithValue(micAccess),
        ],
      );
      addTearDown(scopedContainer.dispose);

      final controller = scopedContainer.read(
        roomControllerProvider('room-a').notifier,
      );
      await controller.joinRoom('user-1', displayName: 'User One');
      await controller.cancelMicRequest('user-1_host-1');

      expect(micAccess.cancelled, isTrue);
    });

    test(
      'MicAccessController prevents rapid requeue spam after denial',
      () async {
        final firestore = FakeFirebaseFirestore();
        await firestore.collection('rooms').doc('room-a').set({
          'hostId': 'host-1',
        });
        await firestore
            .collection('rooms')
            .doc('room-a')
            .collection('mic_access_requests')
            .doc('user-1_host-1')
            .set({
              'id': 'user-1_host-1',
              'roomId': 'room-a',
              'requesterId': 'user-1',
              'hostId': 'host-1',
              'status': 'denied',
              'priority': 1,
              'expiresAt': Timestamp.fromDate(
                DateTime.now().add(const Duration(minutes: 5)),
              ),
              'createdAt': Timestamp.fromDate(DateTime.now()),
              'updatedAt': Timestamp.fromDate(DateTime.now()),
            });

        final controller = MicAccessController(firestore);

        await expectLater(
          controller.requestAccess(
            roomId: 'room-a',
            requesterId: 'user-1',
            hostId: 'host-1',
          ),
          throwsA(isA<StateError>()),
        );
      },
    );

    test('host authority survives delayed participant hydration', () async {
      final firestore = FakeFirebaseFirestore();
      await firestore.collection('rooms').doc('room-a').set({
        'hostId': 'host-1',
        'isLocked': false,
      });

      final participantsController =
          StreamController<List<RoomParticipantModel>>.broadcast();
      addTearDown(participantsController.close);

      final container = ProviderContainer(
        overrides: [
          roomFirestoreProvider.overrideWithValue(firestore),
          roomDocStreamProvider.overrideWith(
            (ref, roomId) => Stream.value({'hostId': 'host-1'}),
          ),
          participantsStreamProvider.overrideWith(
            (ref, roomId) => participantsController.stream,
          ),
        ],
      );
      addTearDown(container.dispose);

      final controller = container.read(
        roomControllerProvider('room-a').notifier,
      );

      await controller.joinRoom('host-1', displayName: 'Host One');

      final hydratingState = container.read(roomControllerProvider('room-a'));
      expect(hydratingState.lifecycleState, RoomLifecycleState.hydrating);

      controller.hydrateCurrentUser(
        'host-1',
        displayName: 'Host One',
        role: 'host',
      );

      final activeState = container.read(roomControllerProvider('room-a'));
      expect(activeState.lifecycleState, RoomLifecycleState.active);

      await expectLater(controller.setMicTimer(60), completes);

      final policySnap = await firestore
          .collection('rooms')
          .doc('room-a')
          .collection('policies')
          .doc('settings')
          .get();
      expect(policySnap.data()?['micTimerSeconds'], 60);
    });

    test('joinRoom degrades cleanly when the session service throws', () async {
      final firestore = FakeFirebaseFirestore();
      await firestore.collection('rooms').doc('room-a').set({
        'hostId': 'host-1',
        'ownerId': 'host-1',
        'isLocked': false,
      });

      final flakySession = _FlakyRoomSessionService(
        firestore: firestore,
        presenceController: _TestPresenceController(),
        joinFailuresRemaining: 1,
      );

      final container = ProviderContainer(
        overrides: [
          roomFirestoreProvider.overrideWithValue(firestore),
          roomSessionServiceProvider.overrideWithValue(flakySession),
        ],
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

      expect(result.isSuccess, isFalse);
      expect(result.errorMessage, isNotEmpty);
      expect(state.isConnected, isFalse);
      expect(state.currentUserId, isNull);
      expect(state.lifecycleState, RoomLifecycleState.degraded);
    });

    test('room lifecycle recovers after a transient sync failure', () async {
      final firestore = FakeFirebaseFirestore();
      await firestore.collection('rooms').doc('room-a').set({
        'hostId': 'user-1',
        'ownerId': 'user-1',
        'isLocked': false,
      });

      final flakySession = _FlakyRoomSessionService(
        firestore: firestore,
        presenceController: _TestPresenceController(),
      );

      final container = ProviderContainer(
        overrides: [
          roomFirestoreProvider.overrideWithValue(firestore),
          roomSessionServiceProvider.overrideWithValue(flakySession),
        ],
      );
      addTearDown(container.dispose);

      final controller = container.read(
        roomControllerProvider('room-a').notifier,
      );

      final result = await controller.joinRoom(
        'user-1',
        displayName: 'User One',
      );
      expect(result.isSuccess, isTrue);

      controller.hydrateCurrentUser(
        'user-1',
        displayName: 'User One',
        role: 'host',
      );
      expect(
        container.read(roomControllerProvider('room-a')).lifecycleState,
        RoomLifecycleState.active,
      );

      flakySession.heartbeatFailuresRemaining = 1;
      await controller.syncPresenceNow(forceSync: true);

      final degradedState = container.read(roomControllerProvider('room-a'));
      expect(degradedState.errorMessage, isNotNull);
      expect(degradedState.lifecycleState, RoomLifecycleState.degraded);

      await controller.syncPresenceNow(forceSync: true);

      final recoveredState = container.read(roomControllerProvider('room-a'));
      expect(recoveredState.errorMessage, isNull);
      expect(recoveredState.lifecycleState, RoomLifecycleState.active);
    });
  });
}
