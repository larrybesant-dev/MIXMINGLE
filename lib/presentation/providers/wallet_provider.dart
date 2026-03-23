import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

final walletProvider = StreamProvider<double>((ref) {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) {
    return const Stream<double>.value(0);
  }
  final docStream = FirebaseFirestore.instance
      .collection('users')
      .doc(user.uid)
      .snapshots();
  return docStream.map((doc) {
    final data = doc.data();
    if (data == null || data['balance'] == null) return 0.0;
    return (data['balance'] as num).toDouble();
  });
});
