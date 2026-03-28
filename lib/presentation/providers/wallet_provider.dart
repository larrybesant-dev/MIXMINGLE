import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

final walletProvider = StreamProvider<double>((ref) {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) {
    return Stream<double>.value(0);
  }
  final docStream = FirebaseFirestore.instance
      .collection('users')
      .doc(user.uid)
      .snapshots();
  return docStream.map((doc) {
    final data = doc.data();
    if (data == null) return 0.0;
    final rawBalance = data['balance'] ?? data['coinBalance'];
    if (rawBalance == null) return 0.0;
    return (rawBalance as num).toDouble();
  });
});
