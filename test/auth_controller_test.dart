import 'package:flutter_test/flutter_test.dart';
import 'package:mixvy/features/auth/controllers/auth_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'test_helpers.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:mocktail/mocktail.dart';

void main() {
  setUpAll(() async {
    await testSetup();
  });

  group('AuthController', () {
    late ProviderContainer container;
    setUp(() {
      container = ProviderContainer(
        overrides: [
          authControllerProvider.overrideWith(() => AuthController(auth: mockAuth)),
        ],
      );
    });

    test('login sets user state', () async {
      final controller = container.read(authControllerProvider.notifier);
      await controller.login('test@example.com', 'password');
      final state = container.read(authControllerProvider);
      expect(state.uid, isNotNull);
      expect(state.error, isNull);
    }, skip: skipIntegrationTests);

    test('logout clears user state', () async {
      final controller = container.read(authControllerProvider.notifier);
      await controller.login('test@example.com', 'password');
      await controller.logout();
      // Wait for the authStateChanges stream to emit null and update state
      bool isNullUid = false;
      for (int i = 0; i < 20; i++) {
        final state = container.read(authControllerProvider);
        if (state.uid == null) {
          isNullUid = true;
          break;
        }
        await Future.delayed(const Duration(milliseconds: 10));
      }
      final state = container.read(authControllerProvider);
      expect(state.uid, isNull);
    }, skip: skipIntegrationTests);

    test('signup sets user state', () async {
      final controller = container.read(authControllerProvider.notifier);
      await controller.signup('new@example.com', 'password');
      final state = container.read(authControllerProvider);
      expect(state.uid, isNotNull);
      expect(state.error, isNull);
    }, skip: skipIntegrationTests);
  });
}
