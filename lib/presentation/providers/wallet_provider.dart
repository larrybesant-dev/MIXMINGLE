import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

final walletAuthProvider = Provider<FirebaseAuth>((ref) {
  return FirebaseAuth.instance;
});

final walletFirestoreProvider = Provider<FirebaseFirestore>((ref) {
  return FirebaseFirestore.instance;
});

final walletUserIdProvider = Provider<String?>((ref) {
  return ref.watch(walletAuthProvider).currentUser?.uid;
});

final walletProvider = StreamProvider<double>((ref) {
  final userId = ref.watch(walletUserIdProvider);
  if (userId == null || userId.isEmpty) {
    return Stream<double>.value(0);
  }

  final firestore = ref.watch(walletFirestoreProvider);
  final docStream = firestore
      .collection('wallets')
      .doc(userId)
      .snapshots();

  return docStream.asyncMap((walletDoc) async {
    final walletData = walletDoc.data();
    if (walletData != null) {
      final rawWalletBalance = walletData['coinBalance'] ?? walletData['balance'];
      if (rawWalletBalance != null) {
        return (rawWalletBalance as num).toDouble();
      }
    }

    final userDoc = await firestore.collection('users').doc(userId).get();
    final userData = userDoc.data();
    if (userData == null) {
      return 0.0;
    }

    final rawUserBalance = userData['balance'] ?? userData['coinBalance'];
    if (rawUserBalance == null) {
      return 0.0;
    }

    return (rawUserBalance as num).toDouble();
  });
});
