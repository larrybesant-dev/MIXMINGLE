import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/user_model.dart';

/// Top 10 users by coinBalance — displayed on the dashboard leaderboard strip.
final leaderboardProvider =
    StreamProvider.autoDispose<List<UserModel>>((ref) {
  return FirebaseFirestore.instance
      .collection('users')
      .orderBy('coinBalance', descending: true)
      .limit(10)
      .snapshots()
      .map((snap) =>
          snap.docs.map((d) => UserModel.fromFirestore(d)).toList());
});
