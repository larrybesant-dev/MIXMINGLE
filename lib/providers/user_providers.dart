import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mixmingle/models/user_profile.dart';

// Stable provider stubs for normalization
final currentUserProfileProvider = StateProvider.autoDispose<UserProfile?>((ref) => null);
final currentUserProvider = StateProvider.autoDispose<String?>((ref) => null);
final hasCompletedOnboardingProvider = StateProvider.autoDispose<bool>((ref) => false);
final conversationListProvider = StateProvider.autoDispose<List<String>>((ref) => []);
final fileShareServiceProvider = Provider((ref) => null); // Replace null with FileShareService if available
final userProfileProvider = FutureProvider.family<UserProfile?, String>((ref, userId) async {
  // placeholder until service is wired
  return null;
});
final presenceProvider = StateProvider.autoDispose<bool>((ref) => false);

