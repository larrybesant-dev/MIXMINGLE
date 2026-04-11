import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mixvy/core/providers/firebase_providers.dart' as core_firebase;
import 'package:mixvy/features/friends/models/friend_roster_entry.dart';
import 'package:mixvy/features/friends/providers/friends_providers.dart';
import 'package:mixvy/features/messaging/panes/chat_pane_view.dart';
import 'package:mixvy/features/messaging/providers/messaging_provider.dart' as messaging;

class _DelayedMessagingController extends messaging.MessagingController {
  _DelayedMessagingController({
    required this.firestore,
    required this.sendCompleter,
  }) : super(firestore: firestore);

  final FirebaseFirestore firestore;
  final Completer<void> sendCompleter;

  @override
  Future<void> sendMessage({
    required String conversationId,
    required String senderId,
    required String senderName,
    required String? senderAvatarUrl,
    required String content,
    String? clientMessageId,
  }) async {
    await sendCompleter.future;
    return super.sendMessage(
      conversationId: conversationId,
      senderId: senderId,
      senderName: senderName,
      senderAvatarUrl: senderAvatarUrl,
      content: content,
      clientMessageId: clientMessageId,
    );
  }
}

Widget _buildChatApp({
  required FakeFirebaseFirestore firestore,
  messaging.MessagingController? controller,
}) {
  return ProviderScope(
    overrides: [
      messaging.firestoreProvider.overrideWithValue(firestore),
      core_firebase.firestoreProvider.overrideWithValue(firestore),
      friendRosterProvider.overrideWith((ref) => const Stream<List<FriendRosterEntry>>.empty()),
      if (controller != null)
        messaging.messagingControllerProvider.overrideWithValue(controller),
    ],
    child: const MaterialApp(
      home: Scaffold(
        body: ChatPaneView(
          conversationId: 'conv-1',
          userId: 'user-1',
          username: 'Test User',
          showHeader: false,
        ),
      ),
    ),
  );
}

Future<void> _seedConversation(
  FakeFirebaseFirestore firestore, {
  required DateTime createdAt,
  required DateTime lastMessageAt,
  required DateTime lastReadAt,
}) {
  return firestore.collection('conversations').doc('conv-1').set({
    'participantIds': ['user-1', 'user-2'],
    'participantNames': {
      'user-1': 'Test User',
      'user-2': 'Alice',
    },
    'type': 'direct',
    'createdAt': Timestamp.fromDate(createdAt),
    'lastMessageAt': Timestamp.fromDate(lastMessageAt),
    'lastReadAt': {
      'user-1': Timestamp.fromDate(lastReadAt),
      'user-2': Timestamp.fromDate(lastMessageAt),
    },
    'lastMessagePreview': 'Earlier message',
    'isArchived': false,
    'status': 'active',
  });
}

void main() {
  group('ChatPaneView', () {
    testWidgets('renders sent message immediately before backend write finishes', (tester) async {
      final firestore = FakeFirebaseFirestore();
      final now = DateTime.now();
      await _seedConversation(
        firestore,
        createdAt: now.subtract(const Duration(minutes: 10)),
        lastMessageAt: now.subtract(const Duration(minutes: 1)),
        lastReadAt: now.subtract(const Duration(minutes: 1)),
      );

      final sendCompleter = Completer<void>();
      final controller = _DelayedMessagingController(
        firestore: firestore,
        sendCompleter: sendCompleter,
      );

      await tester.pumpWidget(_buildChatApp(
        firestore: firestore,
        controller: controller,
      ));
      await tester.pump();

      await tester.enterText(find.byType(TextField).last, 'Instant hello');
      await tester.tap(find.byIcon(Icons.send_rounded));
      await tester.pump();

      expect(find.text('Instant hello'), findsOneWidget);
      expect(find.byTooltip('Sending'), findsOneWidget);
      expect(find.text('Message…'), findsNothing);

      final pendingSnapshot = await firestore
          .collection('conversations')
          .doc('conv-1')
          .collection('messages')
          .get();
      expect(pendingSnapshot.docs, isEmpty);

      sendCompleter.complete();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      final deliveredSnapshot = await firestore
          .collection('conversations')
          .doc('conv-1')
          .collection('messages')
          .get();
      expect(deliveredSnapshot.docs, hasLength(1));
      expect(find.text('Instant hello'), findsOneWidget);
      expect(find.byTooltip('Delivered'), findsOneWidget);
    });

    testWidgets('marks unread conversation as read when opened', (tester) async {
      final firestore = FakeFirebaseFirestore();
      final now = DateTime.now();
      final originalReadAt = now.subtract(const Duration(hours: 1));
      final lastMessageAt = now.subtract(const Duration(minutes: 2));

      await _seedConversation(
        firestore,
        createdAt: now.subtract(const Duration(days: 1)),
        lastMessageAt: lastMessageAt,
        lastReadAt: originalReadAt,
      );

      await tester.pumpWidget(_buildChatApp(firestore: firestore));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 20));

      final snapshot = await firestore.collection('conversations').doc('conv-1').get();
      final data = snapshot.data();
      expect(data, isNotNull);

      final updatedReadAt = (data!['lastReadAt'] as Map<String, dynamic>)['user-1'] as Timestamp;
      expect(updatedReadAt.toDate().isAfter(originalReadAt), isTrue);
      expect(updatedReadAt.toDate().isAfter(lastMessageAt), isTrue);
    });

    testWidgets('shows typing indicator when the other user is actively typing', (tester) async {
      final firestore = FakeFirebaseFirestore();
      final now = DateTime.now();
      await _seedConversation(
        firestore,
        createdAt: now.subtract(const Duration(hours: 1)),
        lastMessageAt: now.subtract(const Duration(minutes: 5)),
        lastReadAt: now.subtract(const Duration(minutes: 5)),
      );
      await firestore.collection('users').doc('user-2').set({
        'id': 'user-2',
        'email': 'alice@mixvy.dev',
        'username': 'Alice',
        'createdAt': Timestamp.fromDate(now.subtract(const Duration(days: 30))),
      });
      await firestore.collection('conversations').doc('conv-1').update({
        'typingStatus.user-2': Timestamp.fromDate(now),
      });

      await tester.pumpWidget(_buildChatApp(firestore: firestore));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 20));

      expect(find.text('Alice is typing…'), findsOneWidget);
    });
  });
}