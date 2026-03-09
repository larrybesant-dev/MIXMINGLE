import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../services/social_graph_service.dart';

final friendsProvider = FutureProvider.family<List<String>, String>((ref, userId) async {
  final service = SocialGraphService();
  return await service.getFriends(userId);
});

final followersProvider = FutureProvider.family<List<String>, String>((ref, userId) async {
  final service = SocialGraphService();
  return await service.getFollowers(userId);
});

final followingProvider = FutureProvider.family<List<String>, String>((ref, userId) async {
  final service = SocialGraphService();
  return await service.getFollowing(userId);
});

final suggestedUsersProvider = FutureProvider.family<List<String>, String>((ref, userId) async {
  // TODO: Implement suggested users logic
  return [];
});
