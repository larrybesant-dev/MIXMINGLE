import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mixvy/features/room/providers/message_providers.dart';
import 'package:mixvy/features/room/providers/room_firestore_provider.dart';
import 'package:mixvy/models/user_model.dart';
import 'package:mixvy/presentation/providers/user_provider.dart';

void main() {
  group('Room launch checklist', () {
    test('live room UI files do not import Firebase directly', () {
      final uiTargets = <String>[
        'lib/presentation/screens/live_room_screen.dart',
        'lib/features/stories/widgets/stories_row.dart',
      ];

      final roomWidgetDir = Directory('lib/features/room/widgets');
      if (roomWidgetDir.existsSync()) {
        uiTargets.addAll(
          roomWidgetDir
              .listSync(recursive: true)
              .whereType<File>()
              .where((file) => file.path.endsWith('.dart'))
              .map((file) => file.path.replaceAll(r'\', '/')),
        );
      }

      final forbiddenPatterns = <String>[
        "package:cloud_firestore/cloud_firestore.dart",
        "package:cloud_functions/cloud_functions.dart",
        "package:firebase_database/firebase_database.dart",
        'FirebaseFirestore.instance',
        'FirebaseFunctions.instance',
        'FirebaseDatabase.instance',
      ];

      final violations = <String>[];
      for (final path in uiTargets.toSet()) {
        final file = File(path);
        if (!file.existsSync()) {
          continue;
        }
        final content = file.readAsStringSync();
        final matched = forbiddenPatterns
            .where((pattern) => content.contains(pattern))
            .toList(growable: false);
        if (matched.isNotEmpty) {
          violations.add('$path -> ${matched.join(', ')}');
        }
      }

      expect(
        violations,
        isEmpty,
        reason:
            'UI layer must stay reactive-only. Violations: ${violations.join(' | ')}',
      );
    });

    test('room chat stream stays chronologically ordered', () async {
      final firestore = FakeFirebaseFirestore();
      final container = ProviderContainer(
        overrides: [
          roomFirestoreProvider.overrideWithValue(firestore),
          userProvider.overrideWithValue(
            UserModel(
              id: 'user-1',
              email: 'user1@mixvy.com',
              username: 'User One',
              createdAt: DateTime(2026, 1, 1),
            ),
          ),
        ],
      );
      addTearDown(container.dispose);

      final roommessage = firestore
          .collection('rooms')
          .doc('room-a')
          .collection('messages');

      await roommessage.doc('m2').set({
        'senderId': 'user-2',
        'roomId': 'room-a',
        'content': 'second',
        'sentAt': Timestamp.fromDate(DateTime(2026, 1, 1, 12, 0, 2)),
      });
      await roommessage.doc('m1').set({
        'senderId': 'user-3',
        'roomId': 'room-a',
        'content': 'first',
        'sentAt': Timestamp.fromDate(DateTime(2026, 1, 1, 12, 0, 1)),
      });
      await roommessage.doc('m3').set({
        'senderId': 'user-4',
        'roomId': 'room-a',
        'content': 'third',
        'sentAt': Timestamp.fromDate(DateTime(2026, 1, 1, 12, 0, 3)),
      });

      final message = await container.read(
        messagetreamProvider('room-a').future,
      );

      expect(
        message.map((message) => message.content).toList(growable: false),
        <String>['first', 'second', 'third'],
      );
    });
  });
}
