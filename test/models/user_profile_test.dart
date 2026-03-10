import 'package:flutter_test/flutter_test.dart';
import 'package:mixmingle/models/user_profile.dart';

void main() {
  group('UserProfile', () {
    test('serialization/deserialization', () {
      final user = UserProfile(
        id: '123',
        username: 'testuser',
        displayName: 'Test User',
        photoUrl: 'http://example.com/photo.png',
        ageVerified: true,
        chatList: ['chat1', 'chat2'],
        bio: 'Hello world',
        createdAt: DateTime.parse('2026-03-09T12:00:00Z'),
        extraData: {'foo': 'bar'},
      );
      final map = user.toMap();
      final user2 = UserProfile.fromMap(map);
      expect(user2.id, user.id);
      expect(user2.username, user.username);
      expect(user2.displayName, user.displayName);
      expect(user2.photoUrl, user.photoUrl);
      expect(user2.ageVerified, user.ageVerified);
      expect(user2.chatList, user.chatList);
      expect(user2.bio, user.bio);
      expect(user2.createdAt?.toIso8601String(), user.createdAt?.toIso8601String());
      expect(user2.extraData, user.extraData);
    });
  });
      expect(profile.preferredGenders, ['any']);
      expect(profile.lifestylePrompts, {'fitness': true});
      expect(profile.isEmailVerified, isTrue);
      expect(profile.verifiedOnlyMode, isFalse);
      expect(profile.privateMode, isTrue);
      expect(profile.createdAt, DateTime(2024, 1, 1));
      expect(profile.updatedAt, DateTime(2024, 1, 2));
    });

    test('toMap emits persisted fields', () {
      final profile = UserProfile(
        id: 'user999',
        email: 'user999@example.com',
        displayName: 'User Nine',
        nickname: null,
        photoUrl: null,
        coverPhotoUrl: null,
        galleryPhotos: const ['a', 'b'],
        interests: const ['coding'],
        location: null,
        latitude: null,
        longitude: null,
        birthday: null,
        gender: 'non-binary',
        pronouns: null,
        bio: 'bio',
        lookingFor: const ['networking'],
        relationshipType: null,
        minAgePreference: null,
        maxAgePreference: null,
        preferredGenders: const ['any'],
        personalityPrompts: const {'prompt': 'answer'},
        musicTastes: const ['rock'],
        lifestylePrompts: const {'fitness': true},
        isPhotoVerified: null,
        isPhoneVerified: null,
        isEmailVerified: true,
        isIdVerified: null,
        socialLinks: const {'instagram': 'ig'},
        verifiedOnlyMode: null,
        privateMode: null,
        createdAt: DateTime(2024, 2, 1),
        updatedAt: DateTime(2024, 2, 2),
      );

      final map = profile.toMap();

      expect(map['id'], 'user999');
      expect(map['email'], 'user999@example.com');
      expect(map['displayName'], 'User Nine');
      expect(map['galleryPhotos'], ['a', 'b']);
      expect(map['interests'], ['coding']);
      expect(map['musicTastes'], ['rock']);
      expect(map['personalityPrompts'], {'prompt': 'answer'});
      expect(map['socialLinks'], {'instagram': 'ig'});
      expect(map['isEmailVerified'], isTrue);
      expect(map['createdAt'], isA<Timestamp>());
      expect(map['updatedAt'], isA<Timestamp>());
    });

    test('convenience getters mirror core fields', () {
      final profile = UserProfile(
        id: 'user1',
        email: 'user1@example.com',
        displayName: 'Display',
        nickname: 'Nick',
        photoUrl: 'photo',
        coverPhotoUrl: null,
        galleryPhotos: const ['photo'],
        interests: const [],
        location: null,
        latitude: null,
        longitude: null,
        birthday: null,
        gender: null,
        pronouns: null,
        bio: null,
        lookingFor: null,
        relationshipType: null,
        minAgePreference: null,
        maxAgePreference: null,
        preferredGenders: null,
        personalityPrompts: null,
        musicTastes: null,
        lifestylePrompts: null,
        isPhotoVerified: null,
        isPhoneVerified: null,
        isEmailVerified: null,
        isIdVerified: null,
        socialLinks: null,
        verifiedOnlyMode: null,
        privateMode: null,
        createdAt: DateTime(2024, 1, 1),
        updatedAt: DateTime(2024, 1, 2),
      );

      expect(profile.photos, ['photo']);
      expect(profile.profileImageUrl, 'photo');
      expect(profile.username, 'Display');
      expect(profile.isOnline, isFalse);
    });
  });
}
