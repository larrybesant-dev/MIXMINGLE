import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  Stream<User?> get authStateChanges => FirebaseAuth.instance.authStateChanges();

  /// Automated Firestore profile repair for signed-in user
  Future<void> repairUserProfile(User user) async {
    final docRef = FirebaseFirestore.instance.collection('users').doc(user.uid);
    final doc = await docRef.get();
    final now = DateTime.now();
    final profileData = {
      'uid': user.uid,
      'username': user.displayName ?? '',
      'email': user.email ?? '',
      'photoUrl': user.photoURL ?? '',
      'createdAt': Timestamp.fromDate(
        doc.exists
          ? (doc.data()?['createdAt'] as Timestamp?)?.toDate() ?? now
          : now),
      'ageVerified': doc.exists ? (doc.data()?['ageVerified'] ?? false) : false,
      'onboardingComplete': doc.exists ? (doc.data()?['onboardingComplete'] ?? false) : false,
      'bio': doc.exists ? (doc.data()?['bio'] ?? '') : '',
      'location': doc.exists ? (doc.data()?['location'] ?? '') : '',
    };
    await docRef.set(profileData, SetOptions(merge: true));
    debugPrint('✅ Firestore profile repaired for UID ${user.uid}');
  }
}
