import 'package:flutter_test/flutter_test.dart';
import 'package:mixmingle/features/profile/user_profile.dart';

void main() {
  group('UserProfile', () {
    test('copyWith returns updated profile', () {
      final profile = UserProfile(
        id: '1',
        displayName: 'Test User',
        avatarUrl: 'url',
        bio: 'bio',
      );
      final updated = profile.copyWith(displayName: 'New Name');
      expect(updated.displayName, 'New Name');
      expect(updated.avatarUrl, 'url');
    });
  });
}
