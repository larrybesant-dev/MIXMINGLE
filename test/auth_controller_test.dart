import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mixvy/features/auth/controllers/auth_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mocktail/mocktail.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'test_helpers.dart';

void main() {
  setUpAll(() async {
    await testSetup();
  });

  group('AuthController', () {
    late ProviderContainer container;
    late User? currentUser;

    setUp(() {
      currentUser = mockUser;
      when(() => mockAuth.currentUser).thenAnswer((_) => currentUser);
      when(
        () => mockAuth.signInWithEmailAndPassword(
          email: any(named: 'email'),
          password: any(named: 'password'),
        ),
      ).thenAnswer((_) async {
        currentUser = mockUser;
        emitAuthState(mockUser);
        return mockUserCredential;
      });
      when(
        () => mockAuth.createUserWithEmailAndPassword(
          email: any(named: 'email'),
          password: any(named: 'password'),
        ),
      ).thenAnswer((_) async {
        currentUser = mockUser;
        emitAuthState(mockUser);
        return mockUserCredential;
      });
      when(() => mockAuth.signOut()).thenAnswer((_) async {
        currentUser = null;
        emitAuthState(null);
      });

      container = ProviderContainer(
        overrides: [
          authControllerProvider.overrideWith(
            () => AuthController(
              auth: mockAuth,
              unregisterToken: () async {},
            ),
          ),
        ],
      );
    });

    test('login sets user state', () async {
      final controller = container.read(authControllerProvider.notifier);
      await controller.login('test@example.com', 'password');
      final state = container.read(authControllerProvider);
      expect(state.uid, isNotNull);
      expect(state.error, isNull);
    });

    test('logout clears user state', () async {
      final controller = container.read(authControllerProvider.notifier);
      await controller.login('test@example.com', 'password');
      await controller.logout();
      // Wait for the authStateChanges stream to emit null and update state
      for (int i = 0; i < 20; i++) {
        final state = container.read(authControllerProvider);
        if (state.uid == null) {
          break;
        }
        await Future.delayed(const Duration(milliseconds: 10));
      }
      final state = container.read(authControllerProvider);
      expect(state.uid, isNull);
    });

    test('signup sets user state', () async {
      final controller = container.read(authControllerProvider.notifier);
      await controller.signup('new@example.com', 'password');
      final state = container.read(authControllerProvider);
      expect(state.uid, isNotNull);
      expect(state.error, isNull);
    });
  });
}
