import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class EmailVerificationService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Send email verification to current user
  Future<void> sendEmailVerification() async {
    User? user = _auth.currentUser;
    if (user != null && !user.emailVerified) {
      await user.sendEmailVerification();
    }
  }

  /// Check if current user's email is verified
  bool isEmailVerified() {
    User? user = _auth.currentUser;
    return user?.emailVerified ?? false;
  }

  /// Reload user data and check verification status
  Future<bool> reloadAndCheckVerification() async {
    User? user = _auth.currentUser;
    if (user != null) {
      await user.reload();
      user = _auth.currentUser;
      return user?.emailVerified ?? false;
    }
    return false;
  }

  /// Update user verification status in Firestore
  Future<void> updateVerificationStatusInFirestore() async {
    User? user = _auth.currentUser;
    if (user != null) {
      await _firestore.collection('users').doc(user.uid).update({
        'emailVerified': user.emailVerified,
        'verificationUpdatedAt': FieldValue.serverTimestamp(),
      });
    }
  }

  /// Check verification periodically (call this in a timer)
  Future<void> checkVerificationPeriodically() async {
    if (await reloadAndCheckVerification()) {
      await updateVerificationStatusInFirestore();
      // Navigate to home or show success message
    }
  }
}


