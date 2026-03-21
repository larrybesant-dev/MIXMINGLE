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

final profileControllerProvider = StateNotifierProvider<ProfileController, ProfileState>(
  (ref) => ProfileController(),
);

class ProfileController extends StateNotifier<ProfileState> {
  ProfileController() : super(const ProfileState());

  Future<void> updateProfile(ProfileState profile) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      // Replace with real API call
      state = profile.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> fetchProfile(String userId) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      // Replace with real API call
      // For test, set mock data
      state = state.copyWith(
        isLoading: false,
        username: 'username',
        email: 'user@example.com',
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }
}
