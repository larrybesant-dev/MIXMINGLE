import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mixmingle/models/user_profile.dart';

// Stable provider stubs for normalization
final currentUserProfileProvider = StateProvider<UserProfile?>((ref) => null);
final currentUserProvider = StateProvider<String?>((ref) => null);
final hasCompletedOnboardingProvider = StateProvider<bool>((ref) => false);
final conversationListProvider = StateProvider<List<String>>((ref) => []);
final fileShareServiceProvider = Provider((ref) => null); // Replace null with FileShareService if available
final userProfileProvider = FutureProvider.family<UserProfile?, String>((ref, userId) async {
  // placeholder until service is wired
  return null;
});
final presenceProvider = StateProvider<bool>((ref) => false);

