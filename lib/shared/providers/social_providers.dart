import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/user_profile.dart';
import '../../services/user/profile_service.dart';

/// Provider to fetch recommended users for a given user ID.
final recommendedUsersProvider = FutureProvider.family<List<UserProfile>, String>((ref, userId) async {
  final profileService = ProfileService();
  // Replace with real recommendation logic
  return await profileService.getRecommendedUsers(userId);
});
