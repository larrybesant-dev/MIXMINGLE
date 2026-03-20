import 'package:flutter_riverpod/flutter_riverpod.dart';

class ProfileState {
  final bool isLoading;
  final String? error;
  final String? username;
  final String? email;
  final String? avatarUrl;
  final int coinBalance;
  final String? membershipLevel;
  final List<String> followers;

  const ProfileState({
    this.isLoading = false,
    this.error,
    this.username,
    this.email,
    this.avatarUrl,
    this.coinBalance = 0,
    this.membershipLevel,
    this.followers = const [],
  });

  ProfileState copyWith({
    bool? isLoading,
    String? error,
    String? username,
    String? email,
    String? avatarUrl,
    int? coinBalance,
    String? membershipLevel,
    List<String>? followers,
  }) {
    return ProfileState(
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      username: username ?? this.username,
      email: email ?? this.email,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      coinBalance: coinBalance ?? this.coinBalance,
      membershipLevel: membershipLevel ?? this.membershipLevel,
      followers: followers ?? this.followers,
    );
  }
}

class ProfileController extends StateNotifier<ProfileState> {
  ProfileController() : super(const ProfileState());

  Future<void> fetchProfile(String userId) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      // Replace with real API call
      state = state.copyWith(
        isLoading: false,
        username: 'username',
        email: 'user@example.com',
        avatarUrl: '',
        coinBalance: 0,
        membershipLevel: 'Free',
        followers: [],
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> updateProfile(ProfileState profile) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      // Replace with real API call
      state = profile.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }
}

final profileControllerProvider = StateNotifierProvider<ProfileController, ProfileState>((ref) {
  return ProfileController();
});
// Empty Dart file for profile_controller.dart
