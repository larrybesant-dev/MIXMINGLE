import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/social_graph_service.dart';

final socialGraphServiceProvider = Provider<SocialGraphService>((ref) => SocialGraphService());

final followersProvider = FutureProvider.family<List<String>, String>((ref, userId) {
  final service = ref.watch(socialGraphServiceProvider);
  return service.getFollowers(userId);
});

final followingProvider = FutureProvider.family<List<String>, String>((ref, userId) {
  final service = ref.watch(socialGraphServiceProvider);
  return service.getFollowing(userId);
});

final friendsProvider = FutureProvider.family<List<String>, String>((ref, userId) {
  final service = ref.watch(socialGraphServiceProvider);
  return service.getFriends(userId);
});

final isFollowingProvider = FutureProvider.family<bool, Map<String, String>>((ref, params) {
  final service = ref.watch(socialGraphServiceProvider);
  return service.isFollowing(params['userId']!, params['currentUserId']!);
});

final isFriendProvider = FutureProvider.family<bool, Map<String, String>>((ref, params) {
  final service = ref.watch(socialGraphServiceProvider);
  return service.isFriend(params['userId']!, params['currentUserId']!);
});
