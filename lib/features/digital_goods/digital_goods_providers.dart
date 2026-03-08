import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'models.dart';

// Packs provider (global marketplace)
final packsProvider = StreamProvider<List<Pack>>((ref) {
  return FirebaseFirestore.instance
    .collection('packs')
    .snapshots()
    .map((snapshot) => snapshot.docs
      .map((doc) => Pack.fromJson(doc.data(), doc.id))
      .toList());
});

// User purchases provider
final userPurchasesProvider = StreamProvider.family<List<UserPurchase>, String>((ref, userId) {
  return FirebaseFirestore.instance
    .collection('users')
    .doc(userId)
    .collection('purchases')
    .snapshots()
    .map((snapshot) => snapshot.docs
      .map((doc) => UserPurchase.fromJson(doc.data()))
      .toList());
});

// User creations provider
final userCreationsProvider = StreamProvider.family<List<UserCreation>, String>((ref, userId) {
  return FirebaseFirestore.instance
    .collection('users')
    .doc(userId)
    .collection('creations')
    .snapshots()
    .map((snapshot) => snapshot.docs
      .map((doc) => UserCreation.fromJson(doc.data(), doc.id))
      .toList());
});

// User tier provider
final userTierProvider = StreamProvider.family<UserTier?, String>((ref, userId) {
  return FirebaseFirestore.instance
    .collection('users')
    .doc(userId)
    .snapshots()
    .map((doc) => doc.exists ? UserTier.fromJson(doc.data()!, doc.id) : null);
});
