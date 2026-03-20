import 'package:flutter_test/flutter_test.dart';
import 'package:mixvy/auth/auth_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() {
  group('AuthController', () {
    late ProviderContainer container;
    setUp(() {
      container = ProviderContainer();
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
