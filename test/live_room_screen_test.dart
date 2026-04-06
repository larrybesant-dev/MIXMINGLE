import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mixvy/features/room/providers/host_provider.dart';
import 'package:mixvy/features/room/providers/message_providers.dart';
import 'package:mixvy/features/room/providers/participant_providers.dart';
import 'package:mixvy/models/room_participant_model.dart';
import 'package:mixvy/features/room/providers/room_firestore_provider.dart';
import 'package:mixvy/models/user_model.dart';
import 'package:mixvy/presentation/providers/user_provider.dart';
import 'package:mixvy/presentation/screens/live_room_screen.dart';

void main() {
  Future<void> configureViewport(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1200, 2200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
  }

  testWidgets('LiveRoomScreen shows login prompt when user is missing', (
    WidgetTester tester,
  ) async {
    await configureViewport(tester);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [userProvider.overrideWithValue(null)],
        child: const MaterialApp(home: LiveRoomScreen(roomId: 'room-a')),
      ),
    );

    expect(find.text('Please log in.'), findsOneWidget);
  });

  testWidgets('LiveRoomScreen renders joined audience state', (
    WidgetTester tester,
  ) async {
    await configureViewport(tester);
    final firestore = FakeFirebaseFirestore();
    await firestore.collection('rooms').doc('room-a').set({
      'hostId': 'host-1',
      'isLocked': false,
      'slowModeSeconds': 0,
    });
    await firestore
        .collection('rooms')
        .doc('room-a')
        .collection('participants')
        .doc('user-1')
        .set({
          'userId': 'user-1',
          'role': 'audience',
          'isMuted': false,
          'isBanned': false,
          'joinedAt': DateTime(2026, 1, 1),
          'lastActiveAt': DateTime(2026, 1, 1),
        });

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          roomFirestoreProvider.overrideWithValue(firestore),
          currentParticipantProvider.overrideWith(
            (ref, args) => Stream.value(
              RoomParticipantModel(
                userId: 'user-1',
                role: 'audience',
                joinedAt: DateTime(2026, 1, 1),
                lastActiveAt: DateTime(2026, 1, 1),
              ),
            ),
          ),
          participantsStreamProvider.overrideWith(
            (ref, roomId) => Stream.value([
              RoomParticipantModel(
                userId: 'user-1',
                role: 'audience',
                joinedAt: DateTime(2026, 1, 1),
                lastActiveAt: DateTime(2026, 1, 1),
              ),
            ]),
          ),
          participantCountProvider.overrideWith(
            (ref, roomId) => Stream.value(1),
          ),
          messageStreamProvider.overrideWith((ref, roomId) => Stream.value([])),
          hostProvider.overrideWith(
            (ref, roomId) => Stream.value(Host('host-1')),
          ),
          coHostsProvider.overrideWith(
            (ref, roomId) => Stream.value(const <Cohost>[]),
          ),
          userProvider.overrideWithValue(
            UserModel(
              id: 'user-1',
              email: 'user1@mixvy.com',
              username: 'User One',
              createdAt: DateTime(2026, 1, 1),
            ),
          ),
        ],
        child: const MaterialApp(home: LiveRoomScreen(roomId: 'room-a')),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.text('No messages yet.'), findsOneWidget);
    expect(find.textContaining('1 total joined'), findsOneWidget);
    expect(find.text('Send'), findsOneWidget);
    expect(find.byTooltip('Leave Room'), findsOneWidget);
    // Drain the _preWarmAgora Future.delayed(2s) timer so the test ends cleanly.
    await tester.pump(const Duration(seconds: 3));
  });

  testWidgets('LiveRoomScreen opens the people roster for room members', (
    WidgetTester tester,
  ) async {
    await configureViewport(tester);
    final firestore = FakeFirebaseFirestore();
    await firestore.collection('rooms').doc('room-a').set({
      'hostId': 'host-1',
      'isLocked': false,
      'slowModeSeconds': 0,
    });

    final participants = [
      RoomParticipantModel(
        userId: 'host-1',
        role: 'host',
        joinedAt: DateTime(2026, 1, 1),
        lastActiveAt: DateTime(2026, 1, 1),
      ),
      RoomParticipantModel(
        userId: 'user-1',
        role: 'audience',
        joinedAt: DateTime(2026, 1, 1),
        lastActiveAt: DateTime(2026, 1, 1),
      ),
    ];

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          roomFirestoreProvider.overrideWithValue(firestore),
          currentParticipantProvider.overrideWith(
            (ref, args) => Stream.value(
              RoomParticipantModel(
                userId: 'user-1',
                role: 'audience',
                joinedAt: DateTime(2026, 1, 1),
                lastActiveAt: DateTime(2026, 1, 1),
              ),
            ),
          ),
          participantsStreamProvider.overrideWith(
            (ref, roomId) => Stream.value(participants),
          ),
          participantCountProvider.overrideWith(
            (ref, roomId) => Stream.value(2),
          ),
          messageStreamProvider.overrideWith((ref, roomId) => Stream.value([])),
          hostProvider.overrideWith(
            (ref, roomId) => Stream.value(Host('host-1')),
          ),
          coHostsProvider.overrideWith(
            (ref, roomId) => Stream.value(const <Cohost>[]),
          ),
          userProvider.overrideWithValue(
            UserModel(
              id: 'user-1',
              email: 'user1@mixvy.com',
              username: 'User One',
              createdAt: DateTime(2026, 1, 1),
            ),
          ),
        ],
        child: const MaterialApp(home: LiveRoomScreen(roomId: 'room-a')),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    await tester.tap(find.byTooltip('People in room').first);
    await tester.pumpAndSettle();

    expect(find.text('People in room'), findsOneWidget);
    expect(find.text('host-1'), findsOneWidget);
    expect(find.text('User One'), findsWidgets);
    await tester.pump(const Duration(seconds: 3));
  });

  testWidgets('LiveRoomScreen exposes expanded host controls', (
    WidgetTester tester,
  ) async {
    await configureViewport(tester);
    final firestore = FakeFirebaseFirestore();
    await firestore.collection('rooms').doc('room-a').set({
      'hostId': 'host-1',
      'isLocked': false,
      'slowModeSeconds': 0,
    });

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          roomFirestoreProvider.overrideWithValue(firestore),
          currentParticipantProvider.overrideWith(
            (ref, args) => Stream.value(
              RoomParticipantModel(
                userId: 'host-1',
                role: 'host',
                joinedAt: DateTime(2026, 1, 1),
                lastActiveAt: DateTime(2026, 1, 1),
              ),
            ),
          ),
          participantsStreamProvider.overrideWith(
            (ref, roomId) => Stream.value([
              RoomParticipantModel(
                userId: 'host-1',
                role: 'host',
                joinedAt: DateTime(2026, 1, 1),
                lastActiveAt: DateTime(2026, 1, 1),
              ),
            ]),
          ),
          participantCountProvider.overrideWith(
            (ref, roomId) => Stream.value(1),
          ),
          messageStreamProvider.overrideWith((ref, roomId) => Stream.value([])),
          hostProvider.overrideWith(
            (ref, roomId) => Stream.value(Host('host-1')),
          ),
          coHostsProvider.overrideWith(
            (ref, roomId) => Stream.value(const <Cohost>[]),
          ),
          userProvider.overrideWithValue(
            UserModel(
              id: 'host-1',
              email: 'host@mixvy.com',
              username: 'Host One',
              createdAt: DateTime(2026, 1, 1),
            ),
          ),
        ],
        child: const MaterialApp(home: LiveRoomScreen(roomId: 'room-a')),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    // Host controls are now behind the 'Controls' floating button (TikTok layout).
    await tester.tap(find.text('Controls'));
    await tester.pump(); // trigger tap
    await tester.pump(const Duration(milliseconds: 300)); // let bottom sheet open

    expect(find.text('Host Controls'), findsOneWidget);
    expect(find.text('Mic request queue'), findsOneWidget);
    expect(find.text('Gifts'), findsOneWidget);
    expect(find.text('Manage people'), findsOneWidget);
    await tester.pump(const Duration(seconds: 3)); // drain prewarm timer
  });

  testWidgets(
    'LiveRoomScreen hides audience stage request panel for moderators',
    (WidgetTester tester) async {
      await configureViewport(tester);
      final firestore = FakeFirebaseFirestore();
      await firestore.collection('rooms').doc('room-a').set({
        'hostId': 'host-1',
        'isLocked': false,
        'slowModeSeconds': 0,
      });

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            roomFirestoreProvider.overrideWithValue(firestore),
            currentParticipantProvider.overrideWith(
              (ref, args) => Stream.value(
                RoomParticipantModel(
                  userId: 'mod-1',
                  role: 'moderator',
                  joinedAt: DateTime(2026, 1, 1),
                  lastActiveAt: DateTime(2026, 1, 1),
                ),
              ),
            ),
            participantsStreamProvider.overrideWith(
              (ref, roomId) => Stream.value([
                RoomParticipantModel(
                  userId: 'host-1',
                  role: 'host',
                  joinedAt: DateTime(2026, 1, 1),
                  lastActiveAt: DateTime(2026, 1, 1),
                ),
                RoomParticipantModel(
                  userId: 'mod-1',
                  role: 'moderator',
                  joinedAt: DateTime(2026, 1, 1),
                  lastActiveAt: DateTime(2026, 1, 1),
                ),
              ]),
            ),
            participantCountProvider.overrideWith(
              (ref, roomId) => Stream.value(2),
            ),
            messageStreamProvider.overrideWith(
              (ref, roomId) => Stream.value([]),
            ),
            hostProvider.overrideWith(
              (ref, roomId) => Stream.value(Host('host-1')),
            ),
            coHostsProvider.overrideWith(
              (ref, roomId) => Stream.value(const <Cohost>[]),
            ),
            userProvider.overrideWithValue(
              UserModel(
                id: 'mod-1',
                email: 'mod@mixvy.com',
                username: 'Moderator One',
                createdAt: DateTime(2026, 1, 1),
              ),
            ),
          ],
          child: const MaterialApp(home: LiveRoomScreen(roomId: 'room-a')),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.text('Host Controls'), findsNothing);
      expect(find.text('Request Stage Access'), findsNothing);
      expect(find.byTooltip('People in room'), findsWidgets);
      await tester.pump(const Duration(seconds: 3));
    },
  );

  // ---------------------------------------------------------------------------
  // Camera wall visibility (fix acfb943 / 37a0680)
  // The camera wall and its controls (cam/mic toggle buttons) live inside an
  // `_isCallReady && _agoraService != null` guard. Before Agora connects, they
  // must not be visible regardless of the participant role.
  // ---------------------------------------------------------------------------

  testWidgets(
    'LiveRoomScreen does not show camera/mic toggle buttons before Agora connects',
    (WidgetTester tester) async {
      await configureViewport(tester);
      final firestore = FakeFirebaseFirestore();
      await firestore.collection('rooms').doc('room-a').set({
        'hostId': 'host-1',
        'isLocked': false,
        'slowModeSeconds': 0,
      });

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            roomFirestoreProvider.overrideWithValue(firestore),
            currentParticipantProvider.overrideWith(
              (ref, args) => Stream.value(
                RoomParticipantModel(
                  userId: 'user-1',
                  role: 'audience',
                  joinedAt: DateTime(2026, 1, 1),
                  lastActiveAt: DateTime(2026, 1, 1),
                ),
              ),
            ),
            participantsStreamProvider.overrideWith(
              (ref, roomId) => Stream.value([
                RoomParticipantModel(
                  userId: 'user-1',
                  role: 'audience',
                  joinedAt: DateTime(2026, 1, 1),
                  lastActiveAt: DateTime(2026, 1, 1),
                ),
              ]),
            ),
            participantCountProvider.overrideWith(
              (ref, roomId) => Stream.value(1),
            ),
            messageStreamProvider.overrideWith(
              (ref, roomId) => Stream.value([]),
            ),
            hostProvider.overrideWith(
              (ref, roomId) => Stream.value(Host('host-1')),
            ),
            coHostsProvider.overrideWith(
              (ref, roomId) => Stream.value(const <Cohost>[]),
            ),
            userProvider.overrideWithValue(
              UserModel(
                id: 'user-1',
                email: 'user1@mixvy.com',
                username: 'User One',
                createdAt: DateTime(2026, 1, 1),
              ),
            ),
          ],
          child: const MaterialApp(home: LiveRoomScreen(roomId: 'room-a')),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      // Without an active AgoraService, the camera wall section is hidden.
      // These tooltips only appear inside `_isCallReady && _agoraService != null`.
      expect(find.byTooltip('Turn camera on'), findsNothing);
      expect(find.byTooltip('Turn camera off'), findsNothing);
      expect(find.byTooltip('Mute microphone'), findsNothing);
      expect(find.byTooltip('Unmute microphone'), findsNothing);
      expect(find.text('Camera Wall'), findsNothing);
      // Basic room chrome validates the screen mounted correctly.
      expect(find.byTooltip('Leave Room'), findsOneWidget);
      await tester.pump(const Duration(seconds: 3));
    },
  );

  testWidgets(
    'LiveRoomScreen renders member-role participant without crash',
    (WidgetTester tester) async {
      await configureViewport(tester);
      final firestore = FakeFirebaseFirestore();
      await firestore.collection('rooms').doc('room-a').set({
        'hostId': 'host-1',
        'isLocked': false,
        'slowModeSeconds': 0,
      });

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            roomFirestoreProvider.overrideWithValue(firestore),
            currentParticipantProvider.overrideWith(
              (ref, args) => Stream.value(
                RoomParticipantModel(
                  userId: 'user-1',
                  role: 'member',
                  joinedAt: DateTime(2026, 1, 1),
                  lastActiveAt: DateTime(2026, 1, 1),
                ),
              ),
            ),
            participantsStreamProvider.overrideWith(
              (ref, roomId) => Stream.value([
                RoomParticipantModel(
                  userId: 'user-1',
                  role: 'member',
                  joinedAt: DateTime(2026, 1, 1),
                  lastActiveAt: DateTime(2026, 1, 1),
                ),
              ]),
            ),
            participantCountProvider.overrideWith(
              (ref, roomId) => Stream.value(1),
            ),
            messageStreamProvider.overrideWith(
              (ref, roomId) => Stream.value([]),
            ),
            hostProvider.overrideWith(
              (ref, roomId) => Stream.value(Host('host-1')),
            ),
            coHostsProvider.overrideWith(
              (ref, roomId) => Stream.value(const <Cohost>[]),
            ),
            userProvider.overrideWithValue(
              UserModel(
                id: 'user-1',
                email: 'user1@mixvy.com',
                username: 'User One',
                createdAt: DateTime(2026, 1, 1),
              ),
            ),
          ],
          child: const MaterialApp(home: LiveRoomScreen(roomId: 'room-a')),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      // A member-role user sees the standard audience UI (no host controls,
      // no stage-access panel) and the room stays open (no login prompt).
      expect(find.text('Please log in.'), findsNothing);
      expect(find.text('Host Controls'), findsNothing);
      expect(find.byTooltip('Leave Room'), findsOneWidget);
      // Camera wall is NOT visible before Agora connects, even for members
      // who have camera permission — this guards against the black AgoraVideoView
      // regression fixed in acfb943.
      expect(find.text('Camera Wall'), findsNothing);
      await tester.pump(const Duration(seconds: 3));
    },
  );
}
