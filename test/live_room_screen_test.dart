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
  testWidgets('LiveRoomScreen shows login prompt when user is missing', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          userProvider.overrideWithValue(null),
        ],
        child: const MaterialApp(
          home: LiveRoomScreen(roomId: 'room-a'),
        ),
      ),
    );

    expect(find.text('Please log in.'), findsOneWidget);
  });

  testWidgets('LiveRoomScreen renders joined audience state', (
    WidgetTester tester,
  ) async {
    final firestore = FakeFirebaseFirestore();
    await firestore.collection('rooms').doc('room-a').set({
      'hostId': 'host-1',
      'isLocked': false,
      'slowModeSeconds': 0,
    });
    await firestore.collection('rooms').doc('room-a').collection('participants').doc('user-1').set({
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
          participantCountProvider.overrideWith((ref, roomId) => Stream.value(1)),
          messageStreamProvider.overrideWith((ref, roomId) => Stream.value([])),
          hostProvider.overrideWith((ref, roomId) => Stream.value(Host('host-1'))),
          coHostsProvider.overrideWith((ref, roomId) => Stream.value(const <Cohost>[])),
          userProvider.overrideWithValue(
            UserModel(
              id: 'user-1',
              email: 'user1@mixvy.com',
              username: 'User One',
              createdAt: DateTime(2026, 1, 1),
            ),
          ),
        ],
        child: const MaterialApp(
          home: LiveRoomScreen(roomId: 'room-a'),
        ),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.text('No messages yet.'), findsOneWidget);
    expect(find.textContaining('1 in room'), findsOneWidget);
    expect(find.text('Send'), findsOneWidget);
    expect(find.text('Leave Room'), findsOneWidget);
  });
}