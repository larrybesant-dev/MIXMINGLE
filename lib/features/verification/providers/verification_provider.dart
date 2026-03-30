import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

bool _asBool(dynamic value, {required bool fallback}) {
  if (value is bool) {
    return value;
  }
  if (value is num) {
    return value != 0;
  }
  if (value is String) {
    final normalized = value.trim().toLowerCase();
    if (normalized == 'true' || normalized == '1' || normalized == 'yes') {
      return true;
    }
    if (normalized == 'false' || normalized == '0' || normalized == 'no') {
      return false;
    }
  }
  return fallback;
}

final firestoreProvider = Provider<FirebaseFirestore>((ref) {
  return FirebaseFirestore.instance;
});
// Check if user is verified
final userVerificationProvider =
    StreamProvider.family<bool, String>((ref, userId) {
  final firestore = ref.watch(firestoreProvider);

  return firestore
      .collection('users')
      .doc(userId)
      .snapshots()
      .map((snapshot) {
    if (!snapshot.exists) return false;
    return _asBool(snapshot.data()?['isVerified'], fallback: false);
  });
});

// Get all verified users (for admin purposes)
final verifiedUsersProvider = StreamProvider<List<String>>((ref) {
  final firestore = ref.watch(firestoreProvider);

  return firestore
      .collection('users')
      .where('isVerified', isEqualTo: true)
      .snapshots()
      .map((snapshot) =>
          snapshot.docs.map((doc) => doc.id).toList());
});

// Verification controller (admin only)
class VerificationController {
  final FirebaseFirestore _firestore;

  VerificationController({required FirebaseFirestore firestore})
      : _firestore = firestore;

  Future<void> verifyUser({
    required String userId,
    required String verifiedBy,
  }) async {
    await _firestore.collection('users').doc(userId).update({
      'isVerified': true,
      'verifiedAt': FieldValue.serverTimestamp(),
      'verifiedBy': verifiedBy,
    });
  }

  Future<void> unverifyUser({required String userId}) async {
    await _firestore.collection('users').doc(userId).update({
      'isVerified': false,
      'verifiedAt': FieldValue.delete(),
      'verifiedBy': FieldValue.delete(),
    });
  }
}

final verificationControllerProvider = Provider<VerificationController>((ref) {
  return VerificationController(firestore: ref.watch(firestoreProvider));
});
