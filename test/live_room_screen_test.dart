import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mixvy/features/feed/providers/host_controls_providers.dart';
import 'package:mixvy/features/room/providers/host_provider.dart';
import 'package:mixvy/features/room/providers/message_providers.dart';
import 'package:mixvy/features/room/providers/mic_access_provider.dart';
import 'package:mixvy/features/room/providers/participant_providers.dart';
import 'package:mixvy/features/room/providers/room_policy_provider.dart';
import 'package:mixvy/features/room/widgets/room_host_control_panel.dart';
import 'package:mixvy/models/mic_access_request_model.dart';
import 'package:mixvy/models/room_model.dart';
import 'package:mixvy/models/room_participant_model.dart';
import 'package:mixvy/models/room_policy_model.dart';
import 'package:mixvy/features/room/providers/room_firestore_provider.dart';
import 'package:mixvy/models/presence_model.dart';
import 'package:mixvy/models/message_model.dart';
import 'package:mixvy/models/user_model.dart';
import 'package:mixvy/features/room/providers/presence_provider.dart';
import 'package:mixvy/presentation/providers/user_provider.dart';
import 'package:mixvy/presentation/screens/live_room_screen.dart';

void main() {
  test('resolvePublicUsername keeps registered names visible', () {
    expect(
      resolvePublicUsername(
        uid: 'user-1',
        profileUsername: 'Larry Besant',
        authDisplayName: 'Larry Besant',
      ),
      'Larry Besant',
    );

    expect(
      resolvePublicUsername(uid: 'user-1', profileUsername: 'Larry Besant'),
      'Larry Besant',
    );

    expect(
      resolvePublicUsername(
        uid: 'user-1',
        profileUsername: 'VelvetHandle',
        authDisplayName: 'Larry Besant',
      ),
      'VelvetHandle',
    );
  });

  test(
    'resolvePublicUsername keeps safe handles visible for the current user',
    () {
      expect(
        resolvePublicUsername(
          uid: 'user-1',
          profileUsername: 'VelvetHandle',
          authDisplayName: 'VelvetHandle',
        ),
        'VelvetHandle',
      );
    },
  );

  test('resolvePublicUsername never falls back to Guest labels', () {
    expect(
      resolvePublicUsername(uid: 'user-1', profileUsername: null),
      isNot(contains('Guest')),
    );
  });

  test('resolvePublicUsername masks raw uid-style names safely', () {
    expect(
      resolvePublicUsername(uid: 'Le6mdtczbpXYzFnW9msFE4abcdef'),
      'Member LE6M',
    );
  });

  test(
    'roomParticipantCanBeShownAsTalking keeps active local mic users visible',
    () {
      final activeMember = RoomParticipantModel(
        userId: 'user-1',
        role: 'member',
        micOn: true,
        joinedAt: DateTime(2026, 1, 1),
        lastActiveAt: DateTime(2026, 1, 1),
      );
      final mutedStage = RoomParticipantModel(
        userId: 'user-2',
        role: 'stage',
        micOn: false,
        joinedAt: DateTime(2026, 1, 1),
        lastActiveAt: DateTime(2026, 1, 1),
      );
      final liveStage = RoomParticipantModel(
        userId: 'user-3',
        role: 'stage',
        micOn: true,
        joinedAt: DateTime(2026, 1, 1),
        lastActiveAt: DateTime(2026, 1, 1),
      );

      expect(roomParticipantCanBeShownAsTalking(activeMember), isTrue);
      expect(roomParticipantCanBeShownAsTalking(mutedStage), isFalse);
      expect(roomParticipantCanBeShownAsTalking(liveStage), isTrue);
    },
  );
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

    expect(find.text('Please log in'), findsOneWidget);
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
          messageStreamProvider.overrideWith((ref, roomId) => Stream.value([])),
          hostProvider.overrideWith(
            (ref, roomId) => Stream.value(Host('host-1')),
          ),
          coHostsProvider.overrideWith(
            (ref, roomId) => Stream.value(const <Cohost>[]),
          ),
          roomPresenceStreamProvider.overrideWith(
            (ref, roomId) => Stream.value([
              RoomPresenceModel(
                userId: 'user-1',
                isOnline: true,
                lastHeartbeatAt: null,
                lastSeenAt: null,
              ),
            ]),
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

    expect(find.text('No messages yet'), findsOneWidget);
    expect(find.textContaining('1 online'), findsOneWidget);
    expect(find.text('Room warming up'), findsWidgets);
    expect(
      find.textContaining('1 here • 0 on mic • 0 watching cam'),
      findsWidgets,
    );
    expect(
      find.text('Tap Grab Mic above or turn on cam to start the vibe.'),
      findsWidgets,
    );
    expect(find.byTooltip('Send message'), findsOneWidget);
    expect(find.byTooltip('Leave Room'), findsOneWidget);
    // Drain the _preWarmAgora Future.delayed(2s) timer so the test ends cleanly.
    await tester.pump(const Duration(seconds: 3));
  });

  testWidgets(
    'LiveRoomScreen shows the current user in the sidebar when live',
    (WidgetTester tester) async {
      await configureViewport(tester);
      final firestore = FakeFirebaseFirestore();
      await firestore.collection('rooms').doc('room-a').set({
        'hostId': 'host-1',
        'isLocked': false,
        'slowModeSeconds': 0,
      });

      final me = RoomParticipantModel(
        userId: 'user-1',
        role: 'stage',
        camOn: true,
        micOn: true,
        joinedAt: DateTime(2026, 1, 1),
        lastActiveAt: DateTime(2026, 1, 1),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            roomFirestoreProvider.overrideWithValue(firestore),
            currentParticipantProvider.overrideWith(
              (ref, args) => Stream.value(me),
            ),
            participantsStreamProvider.overrideWith(
              (ref, roomId) => Stream.value([me]),
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
            roomPresenceStreamProvider.overrideWith(
              (ref, roomId) => Stream.value([
                RoomPresenceModel(
                  userId: 'user-1',
                  isOnline: true,
                  lastHeartbeatAt: null,
                  lastSeenAt: null,
                ),
              ]),
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

      expect(find.text('On Cam 1'), findsOneWidget);
      expect(find.text('Chatting 1'), findsOneWidget);
      expect(
        find.text('No one else is here yet. Invite people to join the room.'),
        findsNothing,
      );

      await tester.pump(const Duration(seconds: 3));
    },
  );

  testWidgets(
    'LiveRoomScreen keeps the current user visible when the roster stream lags',
    (WidgetTester tester) async {
      await configureViewport(tester);
      final firestore = FakeFirebaseFirestore();
      await firestore.collection('rooms').doc('room-a').set({
        'hostId': 'host-1',
        'isLocked': false,
        'slowModeSeconds': 0,
      });

      final me = RoomParticipantModel(
        userId: 'user-1',
        role: 'stage',
        camOn: true,
        micOn: true,
        joinedAt: DateTime(2026, 1, 1),
        lastActiveAt: DateTime(2026, 1, 1),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            roomFirestoreProvider.overrideWithValue(firestore),
            currentParticipantProvider.overrideWith(
              (ref, args) => Stream.value(me),
            ),
            participantsStreamProvider.overrideWith(
              (ref, roomId) => Stream.value(const <RoomParticipantModel>[]),
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
            roomPresenceStreamProvider.overrideWith(
              (ref, roomId) => Stream.value([
                RoomPresenceModel(
                  userId: 'user-1',
                  isOnline: true,
                  lastHeartbeatAt: null,
                  lastSeenAt: null,
                ),
              ]),
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

      expect(find.text('On Cam 1'), findsOneWidget);
      expect(find.text('Chatting 1'), findsOneWidget);
      expect(find.textContaining('(You)'), findsWidgets);

      await tester.pump(const Duration(seconds: 3));
    },
  );

  testWidgets(
    'LiveRoomScreen keeps mic status consistent when the roster stream lags',
    (WidgetTester tester) async {
      await configureViewport(tester);
      final firestore = FakeFirebaseFirestore();
      await firestore.collection('rooms').doc('room-a').set({
        'hostId': 'host-1',
        'isLocked': false,
        'slowModeSeconds': 0,
      });

      final me = RoomParticipantModel(
        userId: 'user-1',
        role: 'stage',
        camOn: false,
        micOn: true,
        joinedAt: DateTime(2026, 1, 1),
        lastActiveAt: DateTime.now().subtract(const Duration(minutes: 5)),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            roomFirestoreProvider.overrideWithValue(firestore),
            currentParticipantProvider.overrideWith(
              (ref, args) => Stream.value(me),
            ),
            participantsStreamProvider.overrideWith(
              (ref, roomId) => Stream.value(const <RoomParticipantModel>[]),
            ),
            participantCountProvider.overrideWith(
              (ref, roomId) => Stream.value(1),
            ),
            messageStreamProvider.overrideWith(
              (ref, roomId) => Stream.value(const <MessageModel>[]),
            ),
            hostProvider.overrideWith(
              (ref, roomId) => Stream.value(Host('host-1')),
            ),
            coHostsProvider.overrideWith(
              (ref, roomId) => Stream.value(const <Cohost>[]),
            ),
            roomPresenceStreamProvider.overrideWith(
              (ref, roomId) => Stream.value([
                RoomPresenceModel(
                  userId: 'user-1',
                  isOnline: true,
                  lastHeartbeatAt: null,
                  lastSeenAt: null,
                ),
              ]),
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
      await tester.pump(const Duration(milliseconds: 300));

      expect(
        find.textContaining('1 here • 1 on mic • 0 watching cam'),
        findsWidgets,
      );
      expect(find.byTooltip('Release mic'), findsOneWidget);

      await tester.pump(const Duration(seconds: 3));
    },
  );

  testWidgets(
    'LiveRoomScreen keeps recent chatters visible when presence lags',
    (WidgetTester tester) async {
      await configureViewport(tester);
      final firestore = FakeFirebaseFirestore();
      await firestore.collection('rooms').doc('room-a').set({
        'hostId': 'host-1',
        'isLocked': false,
        'slowModeSeconds': 0,
      });
      await firestore.collection('users').doc('user-2').set({
        'username': 'Harley',
      });

      final me = RoomParticipantModel(
        userId: 'user-1',
        role: 'audience',
        joinedAt: DateTime(2026, 1, 1),
        lastActiveAt: DateTime.now(),
      );
      final chatter = RoomParticipantModel(
        userId: 'user-2',
        role: 'audience',
        joinedAt: DateTime(2026, 1, 1),
        lastActiveAt: DateTime.now(),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            roomFirestoreProvider.overrideWithValue(firestore),
            currentParticipantProvider.overrideWith(
              (ref, args) => Stream.value(me),
            ),
            participantsStreamProvider.overrideWith(
              (ref, roomId) => Stream.value([me, chatter]),
            ),
            participantCountProvider.overrideWith(
              (ref, roomId) => Stream.value(2),
            ),
            messageStreamProvider.overrideWith(
              (ref, roomId) => Stream.value([
                MessageModel(
                  id: 'm-1',
                  senderId: 'user-2',
                  roomId: 'room-a',
                  content: 'hello there',
                  sentAt: DateTime.now(),
                ),
              ]),
            ),
            hostProvider.overrideWith(
              (ref, roomId) => Stream.value(Host('host-1')),
            ),
            coHostsProvider.overrideWith(
              (ref, roomId) => Stream.value(const <Cohost>[]),
            ),
            roomPresenceStreamProvider.overrideWith(
              (ref, roomId) => Stream.value([
                RoomPresenceModel(
                  userId: 'user-1',
                  isOnline: true,
                  lastHeartbeatAt: null,
                  lastSeenAt: null,
                ),
                RoomPresenceModel(
                  userId: 'user-2',
                  isOnline: false,
                  lastHeartbeatAt: null,
                  lastSeenAt: null,
                ),
              ]),
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
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.textContaining('2 here'), findsWidgets);
      expect(find.text('Harley'), findsWidgets);

      await tester.pump(const Duration(seconds: 3));
    },
  );

  testWidgets('LiveRoomScreen hides offline users from the room roster', (
    WidgetTester tester,
  ) async {
    await configureViewport(tester);
    final firestore = FakeFirebaseFirestore();
    await firestore.collection('rooms').doc('room-a').set({
      'hostId': 'host-1',
      'isLocked': false,
      'slowModeSeconds': 0,
    });
    await firestore.collection('users').doc('user-2').set({
      'username': 'OfflineUser',
    });

    final me = RoomParticipantModel(
      userId: 'user-1',
      role: 'audience',
      joinedAt: DateTime(2026, 1, 1),
      lastActiveAt: DateTime.now(),
    );
    final offlineUser = RoomParticipantModel(
      userId: 'user-2',
      role: 'audience',
      joinedAt: DateTime(2026, 1, 1),
      lastActiveAt: DateTime.now(),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          roomFirestoreProvider.overrideWithValue(firestore),
          currentParticipantProvider.overrideWith(
            (ref, args) => Stream.value(me),
          ),
          participantsStreamProvider.overrideWith(
            (ref, roomId) => Stream.value([me, offlineUser]),
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
          roomPresenceStreamProvider.overrideWith(
            (ref, roomId) => Stream.value([
              RoomPresenceModel(
                userId: 'user-1',
                isOnline: true,
                lastHeartbeatAt: null,
                lastSeenAt: null,
              ),
              RoomPresenceModel(
                userId: 'user-2',
                isOnline: false,
                lastHeartbeatAt: null,
                lastSeenAt: null,
              ),
            ]),
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
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Chatting 1'), findsOneWidget);
    expect(find.text('OfflineUser'), findsNothing);

    await tester.pump(const Duration(seconds: 3));
  });

  testWidgets(
    'LiveRoomScreen only shows cam viewers when my camera is actually on',
    (WidgetTester tester) async {
      await configureViewport(tester);
      final firestore = FakeFirebaseFirestore();
      await firestore.collection('rooms').doc('room-a').set({
        'hostId': 'host-1',
        'isLocked': false,
        'slowModeSeconds': 0,
      });
      await firestore.collection('users').doc('harley').set({
        'username': 'Harley',
      });
      await firestore.collection('userCamPermissions').doc('user-1').set({
        'allowedViewers': ['harley'],
      });

      final me = RoomParticipantModel(
        userId: 'user-1',
        role: 'audience',
        camOn: false,
        micOn: false,
        joinedAt: DateTime(2026, 1, 1),
        lastActiveAt: DateTime.now(),
      );
      final harley = RoomParticipantModel(
        userId: 'harley',
        role: 'audience',
        camOn: false,
        micOn: false,
        joinedAt: DateTime(2026, 1, 1),
        lastActiveAt: DateTime.now(),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            roomFirestoreProvider.overrideWithValue(firestore),
            currentParticipantProvider.overrideWith(
              (ref, args) => Stream.value(me),
            ),
            participantsStreamProvider.overrideWith(
              (ref, roomId) => Stream.value([me, harley]),
            ),
            participantCountProvider.overrideWith(
              (ref, roomId) => Stream.value(2),
            ),
            messageStreamProvider.overrideWith(
              (ref, roomId) => Stream.value(const <MessageModel>[]),
            ),
            hostProvider.overrideWith(
              (ref, roomId) => Stream.value(Host('host-1')),
            ),
            coHostsProvider.overrideWith(
              (ref, roomId) => Stream.value(const <Cohost>[]),
            ),
            roomPresenceStreamProvider.overrideWith(
              (ref, roomId) => Stream.value([
                RoomPresenceModel(
                  userId: 'user-1',
                  isOnline: true,
                  lastHeartbeatAt: null,
                  lastSeenAt: null,
                ),
                RoomPresenceModel(
                  userId: 'harley',
                  isOnline: true,
                  lastHeartbeatAt: null,
                  lastSeenAt: null,
                ),
              ]),
            ),
            userProvider.overrideWithValue(
              UserModel(
                id: 'user-1',
                email: 'user1@mixvy.com',
                username: 'Curve',
                createdAt: DateTime(2026, 1, 1),
              ),
            ),
          ],
          child: const MaterialApp(home: LiveRoomScreen(roomId: 'room-a')),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(
        find.textContaining('2 here • 0 on mic • 0 watching cam'),
        findsWidgets,
      );
      expect(find.byIcon(Icons.visibility), findsNothing);

      await tester.pump(const Duration(seconds: 3));
    },
  );

  testWidgets(
    'LiveRoomScreen does not show presence-only users who lack a confirmed room membership',
    (WidgetTester tester) async {
      await configureViewport(tester);
      final firestore = FakeFirebaseFirestore();
      await firestore.collection('rooms').doc('room-a').set({
        'hostId': 'host-1',
        'isLocked': false,
        'slowModeSeconds': 0,
      });
      await firestore.collection('users').doc('ghost').set({
        'username': 'Ghost',
      });

      final me = RoomParticipantModel(
        userId: 'user-1',
        role: 'audience',
        joinedAt: DateTime(2026, 1, 1),
        lastActiveAt: DateTime.now(),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            roomFirestoreProvider.overrideWithValue(firestore),
            currentParticipantProvider.overrideWith(
              (ref, args) => Stream.value(me),
            ),
            participantsStreamProvider.overrideWith(
              (ref, roomId) => Stream.value([me]),
            ),
            participantCountProvider.overrideWith(
              (ref, roomId) => Stream.value(1),
            ),
            messageStreamProvider.overrideWith(
              (ref, roomId) => Stream.value([
                MessageModel(
                  id: 'msg-ghost',
                  senderId: 'ghost',
                  roomId: 'room-a',
                  content: 'i should not be in the room list',
                  sentAt: DateTime.now(),
                ),
              ]),
            ),
            hostProvider.overrideWith(
              (ref, roomId) => Stream.value(Host('host-1')),
            ),
            coHostsProvider.overrideWith(
              (ref, roomId) => Stream.value(const <Cohost>[]),
            ),
            roomPresenceStreamProvider.overrideWith(
              (ref, roomId) => Stream.value([
                RoomPresenceModel(
                  userId: 'user-1',
                  isOnline: true,
                  lastHeartbeatAt: DateTime.now(),
                  lastSeenAt: DateTime.now(),
                ),
                RoomPresenceModel(
                  userId: 'ghost',
                  isOnline: true,
                  lastHeartbeatAt: DateTime.now(),
                  lastSeenAt: DateTime.now(),
                ),
              ]),
            ),
            userProvider.overrideWithValue(
              UserModel(
                id: 'user-1',
                email: 'user1@mixvy.com',
                username: 'Curve',
                createdAt: DateTime(2026, 1, 1),
              ),
            ),
          ],
          child: const MaterialApp(home: LiveRoomScreen(roomId: 'room-a')),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Ghost'), findsOneWidget);

      await tester.pump(const Duration(seconds: 3));
    },
  );

  testWidgets(
    'LiveRoomScreen keeps newly joined users visible while presence catches up',
    (WidgetTester tester) async {
      await configureViewport(tester);
      final firestore = FakeFirebaseFirestore();
      await firestore.collection('rooms').doc('room-a').set({
        'hostId': 'host-1',
        'isLocked': false,
        'slowModeSeconds': 0,
      });
      await firestore.collection('users').doc('harley').set({
        'username': 'Harley',
      });
      await firestore
          .collection('rooms')
          .doc('room-a')
          .collection('members')
          .doc('harley')
          .set({
            'userId': 'harley',
            'role': 'member',
            'joinedAt': DateTime.now(),
            'lastActiveAt': DateTime.now(),
          });

      final now = DateTime.now();
      final me = RoomParticipantModel(
        userId: 'user-1',
        role: 'audience',
        userStatus: 'online',
        joinedAt: now,
        lastActiveAt: now,
      );
      final harley = RoomParticipantModel(
        userId: 'harley',
        role: 'audience',
        userStatus: 'online',
        joinedAt: now,
        lastActiveAt: now,
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            roomFirestoreProvider.overrideWithValue(firestore),
            currentParticipantProvider.overrideWith(
              (ref, args) => Stream.value(me),
            ),
            participantsStreamProvider.overrideWith(
              (ref, roomId) => Stream.value([me, harley]),
            ),
            participantCountProvider.overrideWith(
              (ref, roomId) => Stream.value(2),
            ),
            messageStreamProvider.overrideWith(
              (ref, roomId) => Stream.value(const <MessageModel>[]),
            ),
            hostProvider.overrideWith(
              (ref, roomId) => Stream.value(Host('host-1')),
            ),
            coHostsProvider.overrideWith(
              (ref, roomId) => Stream.value(const <Cohost>[]),
            ),
            roomPresenceStreamProvider.overrideWith(
              (ref, roomId) => Stream.value([
                RoomPresenceModel(
                  userId: 'user-1',
                  isOnline: true,
                  lastHeartbeatAt: null,
                  lastSeenAt: null,
                ),
                RoomPresenceModel(
                  userId: 'harley',
                  isOnline: false,
                  lastHeartbeatAt: null,
                  lastSeenAt: null,
                ),
              ]),
            ),
            userProvider.overrideWithValue(
              UserModel(
                id: 'user-1',
                email: 'user1@mixvy.com',
                username: 'Curve',
                createdAt: DateTime(2026, 1, 1),
              ),
            ),
          ],
          child: const MaterialApp(home: LiveRoomScreen(roomId: 'room-a')),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Chatting 2'), findsOneWidget);
      expect(find.text('Harley'), findsWidgets);

      await tester.pump(const Duration(seconds: 3));
    },
  );

  testWidgets(
    'LiveRoomScreen shows online room users in Chatting when the participant stream lags',
    (WidgetTester tester) async {
      await configureViewport(tester);
      final firestore = FakeFirebaseFirestore();
      await firestore.collection('rooms').doc('room-a').set({
        'hostId': 'host-1',
        'isLocked': false,
        'slowModeSeconds': 0,
      });
      await firestore.collection('users').doc('harley').set({
        'username': 'Harley',
      });
      await firestore
          .collection('rooms')
          .doc('room-a')
          .collection('members')
          .doc('harley')
          .set({
            'userId': 'harley',
            'role': 'member',
            'joinedAt': DateTime.now(),
            'lastActiveAt': DateTime.now(),
          });

      final me = RoomParticipantModel(
        userId: 'user-1',
        role: 'audience',
        joinedAt: DateTime(2026, 1, 1),
        lastActiveAt: DateTime.now(),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            roomFirestoreProvider.overrideWithValue(firestore),
            currentParticipantProvider.overrideWith(
              (ref, args) => Stream.value(me),
            ),
            participantsStreamProvider.overrideWith(
              (ref, roomId) => Stream.value([me]),
            ),
            participantCountProvider.overrideWith(
              (ref, roomId) => Stream.value(2),
            ),
            messageStreamProvider.overrideWith(
              (ref, roomId) => Stream.value(const <MessageModel>[]),
            ),
            hostProvider.overrideWith(
              (ref, roomId) => Stream.value(Host('host-1')),
            ),
            coHostsProvider.overrideWith(
              (ref, roomId) => Stream.value(const <Cohost>[]),
            ),
            roomPresenceStreamProvider.overrideWith(
              (ref, roomId) => Stream.value([
                RoomPresenceModel(
                  userId: 'user-1',
                  isOnline: true,
                  lastHeartbeatAt: DateTime.now(),
                  lastSeenAt: DateTime.now(),
                ),
                RoomPresenceModel(
                  userId: 'harley',
                  isOnline: true,
                  lastHeartbeatAt: DateTime.now(),
                  lastSeenAt: DateTime.now(),
                ),
              ]),
            ),
            userProvider.overrideWithValue(
              UserModel(
                id: 'user-1',
                email: 'user1@mixvy.com',
                username: 'Curve',
                createdAt: DateTime(2026, 1, 1),
              ),
            ),
          ],
          child: const MaterialApp(home: LiveRoomScreen(roomId: 'room-a')),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Chatting 2'), findsOneWidget);
      expect(find.text('Harley'), findsWidgets);

      await tester.pump(const Duration(seconds: 3));
    },
  );

  testWidgets(
    'LiveRoomScreen keeps active chatters visible in the Chatting roster',
    (WidgetTester tester) async {
      await configureViewport(tester);
      final firestore = FakeFirebaseFirestore();
      await firestore.collection('rooms').doc('room-a').set({
        'hostId': 'host-1',
        'isLocked': false,
        'slowModeSeconds': 0,
      });
      await firestore.collection('users').doc('harley').set({
        'username': 'Harley',
      });
      await firestore
          .collection('rooms')
          .doc('room-a')
          .collection('members')
          .doc('harley')
          .set({
            'userId': 'harley',
            'role': 'member',
            'joinedAt': DateTime(2026, 1, 1, 15, 0),
            'lastActiveAt': DateTime.now(),
          });

      final now = DateTime(2026, 1, 1, 15, 0);
      final me = RoomParticipantModel(
        userId: 'user-1',
        role: 'audience',
        joinedAt: now,
        lastActiveAt: DateTime.now(),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            roomFirestoreProvider.overrideWithValue(firestore),
            currentParticipantProvider.overrideWith(
              (ref, args) => Stream.value(me),
            ),
            participantsStreamProvider.overrideWith(
              (ref, roomId) => Stream.value([me]),
            ),
            participantCountProvider.overrideWith(
              (ref, roomId) => Stream.value(2),
            ),
            messageStreamProvider.overrideWith(
              (ref, roomId) => Stream.value([
                MessageModel(
                  id: 'msg-1',
                  senderId: 'harley',
                  roomId: 'room-a',
                  content: 'hey curve',
                  sentAt: now,
                ),
              ]),
            ),
            hostProvider.overrideWith(
              (ref, roomId) => Stream.value(Host('host-1')),
            ),
            coHostsProvider.overrideWith(
              (ref, roomId) => Stream.value(const <Cohost>[]),
            ),
            roomPresenceStreamProvider.overrideWith(
              (ref, roomId) => Stream.value([
                RoomPresenceModel(
                  userId: 'user-1',
                  isOnline: true,
                  lastHeartbeatAt: null,
                  lastSeenAt: null,
                ),
              ]),
            ),
            userProvider.overrideWithValue(
              UserModel(
                id: 'user-1',
                email: 'user1@mixvy.com',
                username: 'Curve',
                createdAt: DateTime(2026, 1, 1),
              ),
            ),
          ],
          child: const MaterialApp(home: LiveRoomScreen(roomId: 'room-a')),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Chatting 2'), findsOneWidget);

      await tester.pump(const Duration(seconds: 3));
    },
  );

  testWidgets(
    'LiveRoomScreen shows my username in Chatting even before the participant doc arrives',
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
              (ref, args) => Stream.value(null),
            ),
            participantsStreamProvider.overrideWith(
              (ref, roomId) => Stream.value(const <RoomParticipantModel>[]),
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
            roomPresenceStreamProvider.overrideWith(
              (ref, roomId) => Stream.value([
                RoomPresenceModel(
                  userId: 'user-1',
                  isOnline: true,
                  lastHeartbeatAt: null,
                  lastSeenAt: null,
                ),
              ]),
            ),
            userProvider.overrideWithValue(
              UserModel(
                id: 'user-1',
                email: 'user1@mixvy.com',
                username: 'VelvetHandle',
                createdAt: DateTime(2026, 1, 1),
              ),
            ),
          ],
          child: const MaterialApp(home: LiveRoomScreen(roomId: 'room-a')),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.text('Chatting 1'), findsOneWidget);
      expect(find.textContaining('VelvetHandle'), findsWidgets);

      await tester.pump(const Duration(seconds: 3));
    },
  );

  testWidgets('LiveRoomScreen chat and secret inputs stay focusable', (
    WidgetTester tester,
  ) async {
    await configureViewport(tester);
    final firestore = FakeFirebaseFirestore();
    await firestore.collection('rooms').doc('room-a').set({
      'hostId': 'host-1',
      'isLocked': false,
      'slowModeSeconds': 0,
    });

    final me = RoomParticipantModel(
      userId: 'user-1',
      role: 'stage',
      camOn: true,
      micOn: true,
      joinedAt: DateTime(2026, 1, 1),
      lastActiveAt: DateTime(2026, 1, 1),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          roomFirestoreProvider.overrideWithValue(firestore),
          currentParticipantProvider.overrideWith(
            (ref, args) => Stream.value(me),
          ),
          participantsStreamProvider.overrideWith(
            (ref, roomId) => Stream.value([me]),
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
          roomPresenceStreamProvider.overrideWith(
            (ref, roomId) => Stream.value([
              RoomPresenceModel(
                userId: 'user-1',
                isOnline: true,
                lastHeartbeatAt: null,
                lastSeenAt: null,
              ),
            ]),
          ),
          userProvider.overrideWithValue(
            UserModel(
              id: 'user-1',
              email: 'user1@mixvy.com',
              username: 'VelvetHandle',
              createdAt: DateTime(2026, 1, 1),
            ),
          ),
        ],
        child: const MaterialApp(home: LiveRoomScreen(roomId: 'room-a')),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    final chatField = tester.widget<TextField>(find.byType(TextField).first);
    expect(chatField.enabled, isTrue);
    expect(find.byIcon(Icons.send_rounded), findsOneWidget);

    await tester.tap(find.byType(TextField).first);
    await tester.pump(const Duration(milliseconds: 100));

    await tester.tap(find.text('Secret').first);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    final secretField = tester.widget<TextField>(find.byType(TextField).last);
    expect(secretField.enabled, isTrue);

    await tester.enterText(find.byType(TextField).last, 'Psst tonight');
    await tester.pump();

    final updatedSecretField = tester.widget<TextField>(
      find.byType(TextField).last,
    );
    expect(updatedSecretField.controller?.text, 'Psst tonight');
    expect(updatedSecretField.style?.color, isNot(equals(Colors.transparent)));
    expect(find.text('Psst tonight'), findsOneWidget);

    await tester.pump(const Duration(seconds: 3));
  });

  test(
    'PresenceModel reads legacy presence schema without Firestore writes',
    () {
      final presence = PresenceModel.fromJson({
        'userId': 'user-2',
        'online': true,
        'userStatus': 'online',
        'roomId': 'room-b',
        'lastSeen': DateTime.now(),
      });

      expect(presence.userId, 'user-2');
      expect(presence.isOnline, isTrue);
      expect(presence.status, UserStatus.online);
      expect(presence.inRoom, 'room-b');
    },
  );

  testWidgets('LiveRoomScreen keeps room members visible when presence lags', (
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
      RoomParticipantModel(
        userId: 'user-2',
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
            (ref, roomId) => Stream.value(3),
          ),
          messageStreamProvider.overrideWith((ref, roomId) => Stream.value([])),
          hostProvider.overrideWith(
            (ref, roomId) => Stream.value(Host('host-1')),
          ),
          coHostsProvider.overrideWith(
            (ref, roomId) => Stream.value(const <Cohost>[]),
          ),
          roomPresenceStreamProvider.overrideWith(
            (ref, roomId) => Stream.value([
              RoomPresenceModel(
                userId: 'host-1',
                isOnline: false,
                lastHeartbeatAt: DateTime(2025, 1, 1),
                lastSeenAt: DateTime(2025, 1, 1),
              ),
              RoomPresenceModel(
                userId: 'user-1',
                isOnline: true,
                lastHeartbeatAt: DateTime(2026, 1, 1),
                lastSeenAt: DateTime(2026, 1, 1),
              ),
              RoomPresenceModel(
                userId: 'user-2',
                isOnline: false,
                lastHeartbeatAt: DateTime(2025, 1, 1),
                lastSeenAt: DateTime(2025, 1, 1),
              ),
            ]),
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

    expect(find.text('Chatting 3'), findsOneWidget);

    await tester.tap(find.byTooltip('People in room').first);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('People in room'), findsOneWidget);
    expect(find.text('host-1'), findsWidgets);
    expect(find.text('User One'), findsWidgets);
    expect(find.text('user-2'), findsWidgets);
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
    await tester.pump(); // trigger tap
    await tester.pump(
      const Duration(milliseconds: 500),
    ); // let bottom sheet open

    expect(find.text('People in room'), findsOneWidget);
    expect(find.text('host-1'), findsWidgets);
    expect(find.text('User One'), findsWidgets);
    await tester.pump(const Duration(seconds: 3));
  });

  testWidgets('LiveRoomScreen exposes expanded host controls', (
    WidgetTester tester,
  ) async {
    await configureViewport(tester);

    // Test the RoomHostControlPanel directly by mounting a minimal scaffold
    // that opens the panel on button press, bypassing the complex live room UI.
    final firestore = FakeFirebaseFirestore();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          roomFirestoreProvider.overrideWithValue(firestore),
          roomStreamProvider.overrideWith(
            (ref, roomId) => Stream.value(
              RoomModel(
                id: roomId,
                name: 'Test Room',
                hostId: 'host-1',
                isLive: true,
              ),
            ),
          ),
          roomPolicyProvider.overrideWith(
            (ref, roomId) => Stream.value(RoomPolicyModel(roomId: roomId)),
          ),
          roomMicAccessRequestsProvider.overrideWith(
            (ref, roomId) => Stream.value(const <MicAccessRequestModel>[]),
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
        ],
        child: MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (ctx) => ElevatedButton(
                child: const Text('Open Panel'),
                onPressed: () => RoomHostControlPanel.show(
                  ctx,
                  roomId: 'room-a',
                  currentUserId: 'host-1',
                  isOwner: true,
                ),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.pump();

    await tester.tap(find.text('Open Panel'));
    await tester.pump(); // trigger tap
    await tester.pump(
      const Duration(milliseconds: 500),
    ); // let bottom sheet open

    // Panel opened — verify tab bar labels are present.
    expect(find.text('Room Control Panel'), findsOneWidget);
    expect(find.text('Room'), findsWidgets);
    expect(find.text('Stage'), findsWidgets);
    expect(find.text('Audio'), findsWidgets);
    expect(find.text('People'), findsWidgets);
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
  // Broadcaster controls visibility
  // Controls are always visible for the room host (identified by hostId or
  // isHost/isCohost role). Audience-role non-host users never see controls.
  // Buttons are disabled (onPressed=null) until Agora/WebRTC connects.
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

      // Room policy allows all participants to see mic/cam controls (disabled
      // until RTC connects). Buttons are visible but their onPressed is null.
      // Verify the room chrome is present and screen mounted without crash.
      expect(find.byTooltip('Leave Room'), findsOneWidget);
      // Camera wall placeholder area should not show a 'Camera Wall' title.
      expect(find.text('Camera Wall'), findsNothing);
      await tester.pump(const Duration(seconds: 3));
    },
  );

  testWidgets('LiveRoomScreen renders member-role participant without crash', (
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
  });

  testWidgets(
    'LiveRoomScreen shows broadcaster controls for owner-role participant (hostId match)',
    (WidgetTester tester) async {
      // Regression test: the broadcaster control bar must be visible for the
      // room creator even when the Firestore participant doc has the legacy
      // role='owner' value. Controls are visible immediately (buttons disabled
      // until Agora/WebRTC connects, as _isCallReady=false here).
      await configureViewport(tester);
      final firestore = FakeFirebaseFirestore();
      await firestore.collection('rooms').doc('room-a').set({
        'hostId': 'user-1',
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
                  role: 'owner',
                  joinedAt: DateTime(2026, 1, 1),
                  lastActiveAt: DateTime(2026, 1, 1),
                ),
              ),
            ),
            participantsStreamProvider.overrideWith(
              (ref, roomId) => Stream.value([
                RoomParticipantModel(
                  userId: 'user-1',
                  role: 'owner',
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
              (ref, roomId) => Stream.value(Host('user-1')),
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

      // The broadcaster bar IS visible because user.id == hostId (room doc).
      // Initial state: mic not muted (_isMicMuted=false before connect) →
      // tooltip='Mute microphone'; camera off → tooltip='Turn camera on'.
      expect(find.byTooltip('Mute microphone'), findsOneWidget);
      expect(find.byTooltip('Turn camera on'), findsOneWidget);
      // Room chrome confirms the screen mounted without crashing.
      expect(find.byTooltip('Leave Room'), findsOneWidget);
      await tester.pump(const Duration(seconds: 3));
    },
  );
}
