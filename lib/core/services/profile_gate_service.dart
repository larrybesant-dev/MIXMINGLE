import 'dart:developer' as developer;

import 'package:cloud_firestore/cloud_firestore.dart';

class ProfileGateService {
  ProfileGateService._();

  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static Future<bool> isProfileComplete(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (!doc.exists) return false;

      final data = doc.data() ?? <String, dynamic>{};
      final username = (data['username'] as String?)?.trim() ?? '';
      final email = (data['email'] as String?)?.trim() ?? '';
      return username.isNotEmpty && email.isNotEmpty;
    } catch (error, stackTrace) {
      developer.log(
        'Failed to evaluate profile completeness for $uid',
        name: 'ProfileGateService',
        error: error,
        stackTrace: stackTrace,
      );
      return true;
    }
  }
}
