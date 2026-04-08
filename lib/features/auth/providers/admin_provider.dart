import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Streams the `admin` boolean field from the current user's Firestore doc.
/// Returns `false` when there is no signed-in user or the field is absent.
final isAdminProvider = StreamProvider<bool>((ref) {
  final uid = FirebaseAuth.instance.currentUser?.uid;
  if (uid == null) return Stream.value(false);

  return FirebaseFirestore.instance
      .collection('users')
      .doc(uid)
      .snapshots()
      .map((snap) {
        final data = snap.data();
        if (data == null) return false;
        final raw = data['admin'];
        if (raw is bool) return raw;
        if (raw is int) return raw != 0;
        return false;
      });
});
