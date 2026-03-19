import 'package:flutter_test/flutter_test.dart';
import 'package:mixvy/features/auth/auth_controller.dart';
import 'package:mixvy/models/user_model.dart';

void main() {
  group('AuthController', () {
    late AuthController controller;

    setUp(() {
      controller = AuthController();
    });

    test('login sets user state', () async {
      await controller.login('test@example.com', 'password');
      expect(controller.state, isA<UserModel>());
      expect(controller.state?.email, 'test@example.com');
    });

    test('logout clears user state', () async {
      await controller.login('test@example.com', 'password');
      await controller.logout();
      expect(controller.state, isNull);
    });

    test('register sets user state', () async {
      await controller.register('new@example.com', 'password');
      expect(controller.state?.email, 'new@example.com');
    });
  });
}
