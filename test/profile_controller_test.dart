import 'package:flutter_test/flutter_test.dart';
import 'package:mixvy/features/profile/profile_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() {
  group('ProfileController', () {
    late ProviderContainer container;
    setUp(() {
      container = ProviderContainer();
    });

    test('fetchProfile sets profile state', () async {
      final controller = container.read(profileControllerProvider.notifier);
      await controller.fetchProfile('user123');
      final state = container.read(profileControllerProvider);
      expect(state.username, 'username');
      expect(state.email, 'user@example.com');
    });

    test('updateProfile updates profile state', () async {
      final controller = container.read(profileControllerProvider.notifier);
      final newState = ProfileState(
        username: 'testuser',
        email: 'test@mixvy.com',
        avatarUrl: '',
        coinBalance: 10,
        membershipLevel: 'Premium',
        followers: [],
      );
      await controller.updateProfile(newState);
      final state = container.read(profileControllerProvider);
      expect(state.username, 'testuser');
      expect(state.membershipLevel, 'Premium');
    });
  });
}
