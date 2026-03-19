import 'package:flutter_test/flutter_test.dart';
import 'package:mixvy/features/profile/profile_controller.dart';
import 'package:mixvy/models/user_model.dart';

void main() {
  group('ProfileController', () {
    late ProfileController controller;

    setUp(() {
      controller = ProfileController();
    });

    test('fetchProfile sets user state', () async {
      await controller.fetchProfile('user123');
      expect(controller.state, isA<UserModel>());
      expect(controller.state?.id, 'user123');
    });

    test('updateProfile updates user state', () async {
      final user = UserModel(
        id: 'user456',
        username: 'testuser',
        email: 'test@mixvy.com',
        avatarUrl: '',
        coinBalance: 10,
        membershipLevel: 'Premium',
        followers: [],
      );
      await controller.updateProfile(user);
      expect(controller.state?.id, 'user456');
      expect(controller.state?.membershipLevel, 'Premium');
    });
  });
}
