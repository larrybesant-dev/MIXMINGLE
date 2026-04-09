import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mixvy/core/providers/firebase_providers.dart';
import '../../models/user_model.dart';

/// Top 10 users by coinBalance — displayed on the dashboard leaderboard strip.
final leaderboardProvider =
    StreamProvider.autoDispose<List<UserModel>>((ref) {
  return ref.watch(firestoreProvider)
      .collection('users')
      .orderBy('coinBalance', descending: true)
      .limit(10)
      .snapshots()
      .map((snap) =>
          snap.docs.map((d) => UserModel.fromFirestore(d)).toList());
});
