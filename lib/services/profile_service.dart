import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/adult_profile_model.dart';
import '../models/profile_privacy_model.dart';

class ProfileBundle {
  const ProfileBundle({
    required this.userData,
    required this.privacy,
    required this.adultProfile,
  });

  final Map<String, dynamic> userData;
  final ProfilePrivacyModel privacy;
  final AdultProfileModel adultProfile;
}

class ProfileService {
  ProfileService({FirebaseFirestore? firestore}) : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  Future<ProfileBundle> loadProfile(String userId) async {
    final userRef = _firestore.collection('users').doc(userId);
    final privacyRef = userRef.collection('privacy').doc('settings');
    final adultRef = userRef.collection('adult_profile').doc('details');

    final results = await Future.wait([
      userRef.get(),
      privacyRef.get(),
      adultRef.get(),
    ]);

    final userSnapshot = results[0] as DocumentSnapshot<Map<String, dynamic>>;
    final privacySnapshot = results[1] as DocumentSnapshot<Map<String, dynamic>>;
    final adultSnapshot = results[2] as DocumentSnapshot<Map<String, dynamic>>;

    return ProfileBundle(
      userData: userSnapshot.data() ?? <String, dynamic>{},
      privacy: ProfilePrivacyModel.fromJson(privacySnapshot.data()),
      adultProfile: AdultProfileModel.fromJson({
        'userId': userId,
        ...?adultSnapshot.data(),
      }),
    );
  }

  Future<void> saveProfile({
    required String userId,
    required Map<String, dynamic> userData,
    required ProfilePrivacyModel privacy,
    required AdultProfileModel adultProfile,
  }) async {
    final userRef = _firestore.collection('users').doc(userId);
    final privacyRef = userRef.collection('privacy').doc('settings');
    final adultRef = userRef.collection('adult_profile').doc('details');
    final batch = _firestore.batch();

    batch.set(
      userRef,
      {
        ...userData,
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
    batch.set(
      privacyRef,
      {
        ...privacy.toJson(),
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
    batch.set(
      adultRef,
      {
        ...adultProfile.toJson(),
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );

    await batch.commit();
  }
}
