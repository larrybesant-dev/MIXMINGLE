import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/social_graph_service.dart';

final trendingRoomsProvider = StreamProvider<List<dynamic>>((ref) async* {
  yield [];
});

final newRoomsProvider = StreamProvider<List<dynamic>>((ref) async* {
  yield [];
});

final recommendedRoomsProvider = StreamProvider.family<List<dynamic>, String>((ref, userId) async* {
  yield [];
});

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
  return service.isFriend(params['userId']!, params['currentUserId']!);
});
