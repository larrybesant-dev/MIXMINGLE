import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mixvy/features/friends/models/friend_roster_entry.dart';
import 'package:mixvy/features/friends/models/friendship_model.dart';
import 'package:mixvy/features/friends/providers/friends_providers.dart';
import 'package:mixvy/models/presence_model.dart';
import 'package:mixvy/models/user_model.dart';
import 'package:mixvy/presentation/providers/user_provider.dart';
import 'package:mixvy/presentation/screens/friend_list_screen.dart';

void main() {
  testWidgets('FriendListScreen renders online, in-room, and offline sections', (tester) async {
    final now = DateTime.now();
    final roster = <FriendRosterEntry>[
      FriendRosterEntry(
        friendship: FriendshipModel(
          id: 'user-1_user-2',
          userA: 'user-1',
          userB: 'user-2',
          status: 'accepted',
          requestedBy: 'user-1',
          createdAt: DateTime(2026, 1, 2),
        ),
        user: UserModel(
          id: 'user-2',
          email: 'user2@mixvy.dev',
          username: 'User Two',
          createdAt: DateTime(2026, 1, 2),
        ),
        presence: PresenceModel(
          userId: 'user-2',
          isOnline: true,
          inRoom: null,
          lastSeen: now,
          status: UserStatus.online,
        ),
      ),
      FriendRosterEntry(
        friendship: FriendshipModel(
          id: 'user-1_user-3',
          userA: 'user-1',
          userB: 'user-3',
          status: 'accepted',
          requestedBy: 'user-1',
          createdAt: DateTime(2026, 1, 3),
        ),
        user: UserModel(
          id: 'user-3',
          email: 'user3@mixvy.dev',
          username: 'Room Friend',
          createdAt: DateTime(2026, 1, 3),
        ),
        presence: PresenceModel(
          userId: 'user-3',
          isOnline: true,
          inRoom: 'room-123',
          lastSeen: now,
          status: UserStatus.online,
        ),
      ),
      FriendRosterEntry(
        friendship: FriendshipModel(
          id: 'user-1_user-4',
          userA: 'user-1',
          userB: 'user-4',
          status: 'accepted',
          requestedBy: 'user-1',
          createdAt: DateTime(2026, 1, 4),
        ),
        user: UserModel(
          id: 'user-4',
          email: 'user4@mixvy.dev',
          username: 'Offline Friend',
          createdAt: DateTime(2026, 1, 4),
        ),
        presence: PresenceModel(
          userId: 'user-4',
          isOnline: false,
          inRoom: null,
          lastSeen: now.subtract(const Duration(hours: 2)),
          status: UserStatus.offline,
        ),
      ),
    ];

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          friendRosterProvider.overrideWith((ref) => Stream.value(roster)),
          currentUserPresenceProvider.overrideWith(
            (ref) => Stream.value(
              PresenceModel(
                userId: 'user-1',
                isOnline: true,
                inRoom: 'my-room',
                lastSeen: now,
                status: UserStatus.online,
              ),
            ),
          ),
          userProvider.overrideWithValue(
            UserModel(
              id: 'user-1',
              email: 'user1@mixvy.dev',
              username: 'User One',
              createdAt: DateTime(2026, 1, 1),
            ),
          ),
        ],
        child: const MaterialApp(home: FriendListScreen()),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.text('ONLINE'), findsOneWidget);
    expect(find.text('IN ROOMS'), findsOneWidget);
    expect(find.text('OFFLINE'), findsOneWidget);
    expect(find.text('User Two'), findsOneWidget);
    expect(find.text('Room Friend'), findsOneWidget);
    expect(find.text('Offline Friend'), findsOneWidget);
    expect(find.text('Invite'), findsOneWidget);
    expect(find.text('Join Room'), findsOneWidget);
    expect(find.textContaining('Last seen'), findsOneWidget);
  });
}
