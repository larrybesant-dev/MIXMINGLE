// ignore_for_file: subtype_of_sealed_class

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mixvy/features/profile/profile_controller.dart';
import 'package:mocktail/mocktail.dart';

class MockFirebaseFirestore extends Mock implements FirebaseFirestore {}

class MockCollectionReference extends Mock
    implements CollectionReference<Map<String, dynamic>> {}

class MockDocumentReference extends Mock
    implements DocumentReference<Map<String, dynamic>> {}

class MockDocumentSnapshot extends Mock
    implements DocumentSnapshot<Map<String, dynamic>> {}

class MockFirebaseAuth extends Mock implements FirebaseAuth {}

class MockUser extends Mock implements User {}

void main() {
  late MockFirebaseFirestore firestore;
  late MockCollectionReference usersCollection;
  late MockDocumentReference userDocument;
  late MockDocumentSnapshot userSnapshot;
  late MockFirebaseAuth auth;
  late MockUser user;

  setUpAll(() {
    registerFallbackValue(SetOptions(merge: true));
  });

  setUp(() {
    firestore = MockFirebaseFirestore();
    usersCollection = MockCollectionReference();
    userDocument = MockDocumentReference();
    userSnapshot = MockDocumentSnapshot();
    auth = MockFirebaseAuth();
    user = MockUser();

    when(() => firestore.collection('users')).thenReturn(usersCollection);
    when(() => usersCollection.doc(any())).thenReturn(userDocument);
    when(() => auth.currentUser).thenReturn(user);
    when(() => user.uid).thenReturn('user123');
    when(() => user.email).thenReturn('user@example.com');
    when(() => user.displayName).thenReturn('username');
    when(() => user.photoURL).thenReturn('');
  });

  group('ProfileController', () {
    test('fetchProfile loads the Firestore user document', () async {
      when(() => userDocument.get()).thenAnswer((_) async => userSnapshot);
      when(() => userSnapshot.exists).thenReturn(true);
      when(() => userSnapshot.data()).thenReturn({
        'id': 'user123',
        'username': 'username',
        'email': 'user@example.com',
        'avatarUrl': '',
        'coinBalance': 10,
        'membershipLevel': 'Premium',
        'followers': <String>[],
        'createdAt': Timestamp.fromDate(DateTime(2026, 1, 1)),
      });

      final container = ProviderContainer(
        overrides: [
          profileControllerProvider.overrideWith(
            () => ProfileController(firestore: firestore, auth: auth),
          ),
        ],
      );
      addTearDown(container.dispose);

      final controller = container.read(profileControllerProvider.notifier);
      await controller.fetchProfile('user123');

      final state = container.read(profileControllerProvider);
      expect(state.userId, 'user123');
      expect(state.username, 'username');
      expect(state.email, 'user@example.com');
      expect(state.membershipLevel, 'Premium');
    });

    test('updateProfile saves against the authenticated uid', () async {
      when(() => userDocument.set(any(), any())).thenAnswer((_) async {});

      final container = ProviderContainer(
        overrides: [
          profileControllerProvider.overrideWith(
            () => ProfileController(firestore: firestore, auth: auth),
          ),
        ],
      );
      addTearDown(container.dispose);

      final controller = container.read(profileControllerProvider.notifier);
      await controller.updateProfile(
        const ProfileState(
          username: 'testuser',
          email: 'test@mixvy.com',
          avatarUrl: '',
          coinBalance: 10,
          membershipLevel: 'Premium',
          followers: [],
        ),
      );

      verify(() => usersCollection.doc('user123')).called(1);

      final state = container.read(profileControllerProvider);
      expect(state.userId, 'user123');
      expect(state.username, 'testuser');
      expect(state.membershipLevel, 'Premium');
      expect(state.error, isNull);
    });
  });
}
