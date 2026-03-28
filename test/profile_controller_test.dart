import 'package:firebase_auth/firebase_auth.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mixvy/features/profile/profile_controller.dart';
import 'package:mocktail/mocktail.dart';

class MockFirebaseAuth extends Mock implements FirebaseAuth {}

class MockUser extends Mock implements User {}

void main() {
  late FakeFirebaseFirestore firestore;
  late MockFirebaseAuth auth;
  late MockUser user;

  setUp(() {
    firestore = FakeFirebaseFirestore();
    auth = MockFirebaseAuth();
    user = MockUser();

    when(() => auth.currentUser).thenReturn(user);
    when(() => user.uid).thenReturn('user123');
    when(() => user.email).thenReturn('user@example.com');
    when(() => user.displayName).thenReturn('username');
    when(() => user.photoURL).thenReturn('');
    when(() => user.reload()).thenAnswer((_) async {});
    when(() => user.updateDisplayName(any())).thenAnswer((_) async {});
    when(() => user.updatePhotoURL(any())).thenAnswer((_) async {});
  });

  group('ProfileController', () {
    test('fetchProfile loads the Firestore user document', () async {
      await firestore.collection('users').doc('user123').set({
        'id': 'user123',
        'username': 'username',
        'email': 'user@example.com',
        'avatarUrl': '',
        'coinBalance': 10,
        'membershipLevel': 'Premium',
        'followers': <String>[],
        'createdAt': DateTime(2026, 1, 1).toIso8601String(),
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

      final snapshot = await firestore.collection('users').doc('user123').get();
      final data = snapshot.data();
      expect(data, isNotNull);
      expect(data!['username'], 'testuser');
      expect(data['email'], 'test@mixvy.com');

      final state = container.read(profileControllerProvider);
      expect(state.userId, 'user123');
      expect(state.username, 'testuser');
      expect(state.error, isNull);
    });
  });
}
