import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mix_and_mingle/shared/models/user_profile.dart';

void main() {
  group('UserProfile', () {
    test('fromMap populates profile fields', () {
      final map = {
        'id': 'user123',
        'email': 'john@example.com',
        'displayName': 'John Doe',
        'nickname': 'Johnny',
        'photoUrl': 'https://example.com/p.jpg',
        'galleryPhotos': ['https://example.com/1.jpg'],
        'interests': ['music', 'sports'],
        'location': 'NYC',
        'birthday': Timestamp.fromDate(DateTime(2000, 1, 1)),
        'bio': 'Hello world',
        'lookingFor': ['friends'],
        'preferredGenders': ['any'],
        'lifestylePrompts': {'fitness': true},
        'isEmailVerified': true,
        'verifiedOnlyMode': false,
        'privateMode': true,
        'createdAt': Timestamp.fromDate(DateTime(2024, 1, 1)),
        'updatedAt': Timestamp.fromDate(DateTime(2024, 1, 2)),
      };

      final profile = UserProfile.fromMap(map);

      expect(profile.id, 'user123');
      expect(profile.email, 'john@example.com');
      expect(profile.displayName, 'John Doe');
      expect(profile.nickname, 'Johnny');
      expect(profile.photoUrl, 'https://example.com/p.jpg');
      expect(profile.galleryPhotos, ['https://example.com/1.jpg']);
      expect(profile.interests, ['music', 'sports']);
      expect(profile.location, 'NYC');
      expect(profile.bio, 'Hello world');
      expect(profile.lookingFor, ['friends']);
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
