import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod/riverpod.dart';
import '../services/friends_service.dart';
import '../models/friend_model.dart';

final friendsProvider = StreamProvider.family<List<Friend>, String>((ref, userId) {
  return FriendsService().streamFriends(userId);
});
