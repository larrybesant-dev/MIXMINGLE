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

    expect(find.text('Host Controls'), findsOneWidget);
    expect(find.text('Mic request queue'), findsOneWidget);
    expect(find.text('Gifts'), findsOneWidget);
    expect(find.text('Manage people'), findsOneWidget);
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
    },
  );
}
