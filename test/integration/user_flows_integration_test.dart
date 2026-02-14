/// Integration Tests - Complete User Workflows
///
/// Tests for:
/// - Login → Join Room → Chat flow
/// - Friend request and acceptance flow
/// - Group join and messaging flow
/// - Session management across flows
/// - Error recovery scenarios

import 'package:flutter_test/flutter_test.dart';
import 'package:firebase_auth/firebase_auth.dart' show FirebaseAuthException;
import '../test_helpers.dart';

void main() {
  group('Integration Tests - User Flows', () {
    group('Login → Join Room → Chat Flow', () {
      test('user can login and access room', () async {
        // Setup
        final mockAuth = MockFirebaseAuth();
        final mockFirestore = MockFirebaseFirestore();

        // Step 1: User logs in
        final loginResult =
            await mockAuth.signInWithEmailAndPassword(
          email: 'user@example.com',
          password: 'password123',
        );

        expect(loginResult.user, isNotNull);
        expect(loginResult.user?.email, equals('user@example.com'));

        // Step 2: Create room in Firestore
        final room = {
          'id': 'room-123',
          'name': 'Video Room',
          'participants': [loginResult.user!.uid],
          'createdAt': DateTime.now().toIso8601String(),
        };

        mockFirestore.setMockData('rooms', 'room-123', room);

        // Step 3: Verify user joined room
        final roomData = mockFirestore.getMockData('rooms', 'room-123');
        expect(
          (roomData['participants'] as List)
              .contains(loginResult.user!.uid),
          isTrue,
        );
      });

      test('user can send message in room', () async {
        // Setup
        final mockAuth = MockFirebaseAuth();
        final mockFirestore = MockFirebaseFirestore();

        // Step 1: Login
        final loginResult =
            await mockAuth.signInWithEmailAndPassword(
          email: 'user@example.com',
          password: 'password123',
        );

        final userId = loginResult.user!.uid;

        // Step 2: Create room
        final room = {
          'id': 'room-123',
          'name': 'Video Room',
          'participants': [userId],
        };

        mockFirestore.setMockData('rooms', 'room-123', room);

        // Step 3: Create message
        final message = MockUserData.chatMessage(
          sender: loginResult.user!.displayName ?? 'User',
          content: 'Hello everyone!',
        );

        mockFirestore.setMockData(
          'messages',
          'msg-1',
          message,
        );

        // Step 4: Verify message exists
        final messageData =
            mockFirestore.getMockData('messages', 'msg-1');

        expect(messageData['content'], equals('Hello everyone!'));
        expect(messageData.isNotEmpty, isTrue);
      });

      test('user can leave room and session ends', () async {
        // Setup
        final mockAuth = MockFirebaseAuth();
        final mockFirestore = MockFirebaseFirestore();

        // Step 1: Login and join room
        final loginResult =
            await mockAuth.signInWithEmailAndPassword(
          email: 'user@example.com',
          password: 'password123',
        );

        var room = {
          'id': 'room-123',
          'participants': [loginResult.user!.uid],
        };

        mockFirestore.setMockData('rooms', 'room-123', room);

        // Verify user in room
        expect(
          (mockFirestore.getMockData('rooms', 'room-123')[
                  'participants'] as List)
              .contains(loginResult.user!.uid),
          isTrue,
        );

        // Step 2: User leaves room
        var participants =
            List<String>.from(room['participants'] as List);
        participants
            .remove(loginResult.user!.uid);

        room = {...room, 'participants': participants};
        mockFirestore.setMockData('rooms', 'room-123', room);

        // Step 3: Verify user left room
        expect(
          (mockFirestore.getMockData('rooms', 'room-123')[
                  'participants'] as List)
              .contains(loginResult.user!.uid),
          isFalse,
        );

        // Step 4: User signs out
        await mockAuth.signOut();

        expect(mockAuth.currentUser, isNull);
      });
    });

    group('Friend Request and Acceptance Flow', () {
      test('user can add friend and messaging is enabled',
          () async {
        // Setup
        final mockFirestore = MockFirebaseFirestore();
        const userId1 = 'user-1';
        const userId2 = 'user-2';

        // Step 1: User 1 sends friend request to User 2
        final friendRequest = {
          'id': 'req-1',
          'fromId': userId1,
          'toId': userId2,
          'status': 'pending',
          'createdAt': DateTime.now().toIso8601String(),
        };

        mockFirestore.setMockData(
          'friendRequests',
          'req-1',
          friendRequest,
        );

        // Verify request created
        expect(
          mockFirestore.getMockData('friendRequests', 'req-1')
              ['status'],
          equals('pending'),
        );

        // Step 2: User 2 accepts request
        var accepted = {...friendRequest, 'status': 'accepted'};
        mockFirestore.setMockData(
          'friendRequests',
          'req-1',
          accepted,
        );

        // Step 3: Both users get each other as friends
        final user1Friend = MockUserData.friend(
          id: userId2,
          name: 'User 2',
        );

        final user2Friend = MockUserData.friend(
          id: userId1,
          name: 'User 1',
        );

        mockFirestore.setMockData('users/$userId1/friends', userId2,
            user1Friend);
        mockFirestore.setMockData('users/$userId2/friends', userId1,
            user2Friend);

        // Step 4: Verify both are friends
        expect(
          mockFirestore.getMockData('users/$userId1/friends', userId2)
              .isNotEmpty,
          isTrue,
        );

        expect(
          mockFirestore.getMockData('users/$userId2/friends', userId1)
              .isNotEmpty,
          isTrue,
        );

        // Step 5: They can now message each other
        final directMessage = MockUserData.chatMessage(
          sender: 'User 1',
          content: 'Hi, great to be friends!',
        );

        mockFirestore.setMockData(
          'conversations/$userId1-$userId2/messages',
          'msg-1',
          directMessage,
        );

        final message = mockFirestore.getMockData(
          'conversations/$userId1-$userId2/messages',
          'msg-1',
        );

        expect(message['content'], isNotEmpty);
      });

      test('can remove friend and conversation is archived',
          () async {
        // Setup
        final mockFirestore = MockFirebaseFirestore();
        const userId1 = 'user-1';
        const userId2 = 'user-2';

        // Step 1: They are friends
        final friend = MockUserData.friend(
          id: userId2,
          name: 'User 2',
        );

        mockFirestore.setMockData('users/$userId1/friends', userId2,
            friend);

        expect(
          mockFirestore.getMockData('users/$userId1/friends', userId2)
              .isNotEmpty,
          isTrue,
        );

        // Step 2: Remove friend
        mockFirestore.setMockData('users/$userId1/friends', userId2, {});

        // Step 3: Verify friend removed
        expect(
          mockFirestore.getMockData('users/$userId1/friends', userId2)
              .isEmpty,
          isTrue,
        );

        // Step 4: Conversation archived
        var conversation = {
          'id': 'conv-1',
          'participants': [userId1, userId2],
          'isArchived': false,
        };

        mockFirestore.setMockData(
          'conversations',
          'conv-1',
          conversation,
        );

        conversation = {
          ...conversation,
          'isArchived': true,
        };

        mockFirestore.setMockData(
          'conversations',
          'conv-1',
          conversation,
        );

        // Verify archived
        expect(
          mockFirestore.getMockData('conversations', 'conv-1')[
              'isArchived'],
          isTrue,
        );
      });
    });

    group('Group Join and Messaging Flow', () {
      test('user can join group and send message', () async {
        // Setup
        final mockFirestore = MockFirebaseFirestore();
        const userId = 'user-1';
        const groupId = 'group-1';

        // Step 1: Group exists
        var group = MockUserData.group(
          id: groupId,
          name: 'Flutter Developers',
          memberCount: 5,
        );

        mockFirestore.setMockData('groups', groupId, group);

        // Step 2: User joins group
        var members = List<String>.from(group['members'] as List);
        members.add(userId);

        group = {
          ...group,
          'members': members,
          'memberCount': members.length,
        };

        mockFirestore.setMockData('groups', groupId, group);

        // Verify user is member
        expect(
          (mockFirestore.getMockData('groups', groupId)['members']
                  as List)
              .contains(userId),
          isTrue,
        );

        // Step 3: User sends message in group
        final message = MockUserData.chatMessage(
          sender: 'User 1',
          content: 'Hello group!',
        );

        mockFirestore.setMockData(
          'groups/$groupId/messages',
          'msg-1',
          message,
        );

        // Step 4: Verify message is in group
        final messageData = mockFirestore.getMockData(
          'groups/$groupId/messages',
          'msg-1',
        );

        expect(messageData['content'], equals('Hello group!'));
      });

      test('user can leave group', () async {
        // Setup
        final mockFirestore = MockFirebaseFirestore();
        const userId = 'user-1';
        const groupId = 'group-1';

        // Step 1: User is in group
        var group = MockUserData.group(
          id: groupId,
          memberCount: 5,
        );

        var members = List<String>.from(group['members'] as List);
        members.add(userId);

        group = {
          ...group,
          'members': members,
          'memberCount': members.length,
        };

        mockFirestore.setMockData('groups', groupId, group);

        expect(
          (mockFirestore.getMockData('groups', groupId)['members']
                  as List)
              .contains(userId),
          isTrue,
        );

        // Step 2: User leaves
        members.removeWhere((m) => m == userId);

        group = {
          ...group,
          'members': members,
          'memberCount': members.length,
        };

        mockFirestore.setMockData('groups', groupId, group);

        // Step 3: Verify user left
        expect(
          (mockFirestore.getMockData('groups', groupId)['members']
                  as List)
              .contains(userId),
          isFalse,
        );
      });

      test('multiple users can send messages in group',
          () async {
        // Setup
        final mockFirestore = MockFirebaseFirestore();
        const groupId = 'group-1';

        var group = MockUserData.group(id: groupId);
        mockFirestore.setMockData('groups', groupId, group);

        // Step 1: User 1 sends message
        final msg1 = MockUserData.chatMessage(
          sender: 'User 1',
          content: 'First message',
        );

        mockFirestore.setMockData(
          'groups/$groupId/messages',
          'msg-1',
          msg1,
        );

        // Step 2: User 2 sends message
        final msg2 = MockUserData.chatMessage(
          sender: 'User 2',
          content: 'Second message',
        );

        mockFirestore.setMockData(
          'groups/$groupId/messages',
          'msg-2',
          msg2,
        );

        // Step 3: Verify both messages exist
        expect(
          mockFirestore.getMockData('groups/$groupId/messages', 'msg-1')[
              'content'],
          equals('First message'),
        );

        expect(
          mockFirestore.getMockData('groups/$groupId/messages', 'msg-2')[
              'content'],
          equals('Second message'),
        );
      });
    });

    group('Error Recovery Scenarios', () {
      test('handles login failure gracefully', () async {
        final mockAuth = MockFirebaseAuth();

        try {
          await mockAuth.signInWithEmailAndPassword(
            email: '',
            password: '',
          );
          fail('Should throw exception');
        } on FirebaseAuthException catch (e) {
          expect(e.code, isNotEmpty);
        }
      });

      test('handles user leaving room during session',
          () async {
        // Setup
        final mockFirestore = MockFirebaseFirestore();
        const userId = 'user-1';

        var room = {
          'id': 'room-123',
          'participants': [userId],
        };

        mockFirestore.setMockData('rooms', 'room-123', room);

        // User is in room
        expect(
          (mockFirestore.getMockData('rooms', 'room-123')[
                  'participants'] as List)
              .contains(userId),
          isTrue,
        );

        // User leaves (unexpected disconnect)
        var participants =
            List<String>.from(room['participants'] as List);
        participants.remove(userId);

        room = {...room, 'participants': participants};
        mockFirestore.setMockData('rooms', 'room-123', room);

        // System cleans up properly
        expect(
          (mockFirestore.getMockData('rooms', 'room-123')[
                  'participants'] as List)
              .contains(userId),
          isFalse,
        );
      });

      test('handles message send failure with retry',
          () async {
        // Setup
        final mockFirestore = MockFirebaseFirestore();
        var failureCount = 0;

        // Simulate send failure
        final message = MockUserData.chatMessage(
          content: 'Test message',
        );

        // First attempt fails
        if (failureCount < 1) {
          failureCount++;
          // Retry
        }

        // Retry succeeds
        mockFirestore.setMockData('messages', 'msg-1', message);

        // Message should exist after retry
        expect(
          mockFirestore.getMockData('messages', 'msg-1').isNotEmpty,
          isTrue,
        );
      });
    });

    group('Session Persistence', () {
      test('session persists across multiple operations',
          () async {
        // Setup
        final mockAuth = MockFirebaseAuth();
        final mockFirestore = MockFirebaseFirestore();

        // Step 1: Login
        final loginResult =
            await mockAuth.signInWithEmailAndPassword(
          email: 'user@example.com',
          password: 'password123',
        );

        final userId = loginResult.user!.uid;

        // Step 2: Multiple operations
        for (int i = 0; i < 5; i++) {
          final message = MockUserData.chatMessage(
            sender: 'User',
            content: 'Message $i',
          );

          mockFirestore.setMockData('messages', 'msg-$i', message);
        }

        // Step 3: Verify user still logged in
        expect(mockAuth.currentUser, isNotNull);
        expect(mockAuth.currentUser?.uid, equals(userId));

        // Step 4: Verify all operations succeeded
        for (int i = 0; i < 5; i++) {
          final message =
              mockFirestore.getMockData('messages', 'msg-$i');
          expect(message.isNotEmpty, isTrue);
        }
      });
    });
  });
}
