import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mixvy/models/user_model.dart';
import 'package:mixvy/presentation/providers/friend_provider.dart';
import 'package:mixvy/presentation/providers/user_provider.dart';
import 'package:mixvy/presentation/screens/friend_list_screen.dart';

void main() {
  testWidgets('FriendListScreen renders friends and suggestions', (tester) async {
    final firestore = FakeFirebaseFirestore();
    await firestore.collection('users').doc('user-1').set({
      'uid': 'user-1',
      'email': 'user1@mixvy.dev',
      'username': 'User One',
      'friends': ['user-2'],
    });
    await firestore.collection('users').doc('user-2').set({
      'uid': 'user-2',
      'email': 'user2@mixvy.dev',
      'username': 'User Two',
    });
    await firestore.collection('users').doc('user-3').set({
      'uid': 'user-3',
      'email': 'guest@mixvy.dev',
      'username': 'Guest Person',
    });
    await firestore.collection('users').doc('user-4').set({
      'uid': 'user-4',
      'email': 'requested@mixvy.dev',
      'username': 'Requested Person',
    });
    await firestore.collection('users').doc('user-5').set({
      'uid': 'user-5',
      'email': 'available@mixvy.dev',
      'username': 'Available Person',
    });
    await firestore.collection('friend_requests').doc('incoming-1').set({
      'fromUserId': 'user-3',
      'toUserId': 'user-1',
      'status': 'pending',
      'createdAt': DateTime(2026, 1, 2),
    });
    await firestore.collection('friend_requests').doc('outgoing-1').set({
      'fromUserId': 'user-1',
      'toUserId': 'user-4',
      'status': 'pending',
      'createdAt': DateTime(2026, 1, 3),
    });

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          friendFirestoreProvider.overrideWithValue(firestore),
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
    await tester.pump(const Duration(milliseconds: 150));

    expect(find.text('Pending requests'), findsOneWidget);
    expect(find.text('Guest Person'), findsOneWidget);
    expect(find.text('Accept'), findsOneWidget);
    expect(find.text('Decline'), findsOneWidget);
    expect(find.text('Your friends'), findsOneWidget);
    expect(find.text('User Two'), findsOneWidget);
    expect(find.text('People you may know'), findsOneWidget);
    expect(find.text('Available Person'), findsOneWidget);
    expect(find.text('Add'), findsOneWidget);
    expect(find.text('Requested'), findsNothing);
    expect(find.text('Remove'), findsOneWidget);
  });
}