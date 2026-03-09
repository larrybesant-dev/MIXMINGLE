import '../../../services/social_graph_service.dart';

class FriendsService {
  final SocialGraphService _service = SocialGraphService();

  Future<List<String>> getFriends(String userId) async {
    return await _service.getFriends(userId);
  }

  Future<List<String>> getFollowers(String userId) async {
    return await _service.getFollowers(userId);
  }

  Future<List<String>> getFollowing(String userId) async {
    return await _service.getFollowing(userId);
  }

  Future<List<String>> getSuggestedUsers(String userId) async {
    // TODO: Implement suggested users logic
    return [];
  }
}
