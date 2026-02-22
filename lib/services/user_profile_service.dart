// lib/services/user_profile_service.dart

import '../models/user_profile_model.dart';

class UserProfileService {
  final Map<String, UserProfileModel> _profiles = {};

  UserProfileModel? getProfile(String userId) => _profiles[userId];

  void setProfile(UserProfileModel profile) {
    _profiles[profile.userId] = profile;
  }
}
