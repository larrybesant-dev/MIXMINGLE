import '../models/user_profile_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ProfileService {
  final _profilesRef = FirebaseFirestore.instance.collection('profiles');

  Future<void> createProfile(UserProfile profile) async {
    await _profilesRef.doc(profile.id).set(profile.toMap());
  }

  Future<void> updateProfile(UserProfile profile) async {
    await _profilesRef.doc(profile.id).update(profile.toMap());
  }

  Future<UserProfile?> getProfile(String userId) async {
    final doc = await _profilesRef.doc(userId).get();
    if (doc.exists) {
      return UserProfile.fromFirestore(doc);
    }
    return null;
  }

  Stream<UserProfile?> streamProfile(String userId) {
    return _profilesRef.doc(userId).snapshots().map((doc) =>
      doc.exists ? UserProfile.fromFirestore(doc) : null);
  }
}
