import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/models.dart';

class FriendService {
  final supabase = Supabase.instance.client;

  Future<void> sendFriendRequest(String fromUserId, String toUserId) async {
    await supabase.from('friend_requests').insert({
      'from_user_id': fromUserId,
      'to_user_id': toUserId,
      'status': 'pending',
    });
  }

  Future<void> acceptFriendRequest(String requestId) async {
    await supabase.from('friend_requests').update({'status': 'accepted'}).eq('id', requestId);
  }

  Future<List<UserModel>> getFriends(String userId) async {
    final response = await supabase.from('friends').select().eq('user_id', userId);
    return (response as List).map((u) => UserModel.fromJson(u)).toList();
  }
}
