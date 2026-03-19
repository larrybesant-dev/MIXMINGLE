import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/user_model.dart';
class ProfileController extends StateNotifier<UserModel?> {
    String? error;
  ProfileController() : super(null);

  Future<void> fetchProfile(String userId) async {
    try {
      // Example: Fetch user profile
      // Replace with real API call
      state = UserModel(
        id: 'user123',
        username: 'username',
        email: 'user@example.com',
        avatarUrl: '',
        coinBalance: 0,
        membershipLevel: 'Free',
        followers: [],
      );
      error = null;
    } catch (e) {
      error = e.toString();
    }
  }
  Future<void> updateProfile(UserModel user) async {
    try {
      // Example: Update user profile
      state = user;
      error = null;
    } catch (e) {
      error = e.toString();
    }
  }
  void editProfile(UserModel user) {
    try {
      state = user;
      error = null;
    } catch (e) {
      error = e.toString();
    }
  }
}
// Empty Dart file for profile_controller.dart
