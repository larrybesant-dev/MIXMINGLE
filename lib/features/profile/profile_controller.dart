
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'models/user_model.dart';

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

final profileControllerProvider = NotifierProvider<ProfileController, ProfileState>(
  () => ProfileController(),
);

class ProfileController extends Notifier<ProfileState> {
  @override
  ProfileState build() => const ProfileState();

  Future<void> updateProfile(ProfileState profile) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final userId = profile.username ?? '';
      final userRef = FirebaseFirestore.instance.collection('users').doc(userId);
      await userRef.update({
        'username': profile.username,
        'email': profile.email,
        'avatarUrl': profile.avatarUrl,
        'coinBalance': profile.coinBalance,
        'membershipLevel': profile.membershipLevel,
        'followers': profile.followers,
      });
      state = profile.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> fetchProfile(String userId) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(userId).get();
      if (!userDoc.exists) {
        state = state.copyWith(isLoading: false, error: 'User not found');
        return;
      }
      final user = UserModel.fromFirestore(userDoc);
      state = state.copyWith(
        isLoading: false,
        username: user.username,
        email: user.email,
        avatarUrl: user.avatarUrl,
        coinBalance: user.coinBalance,
        membershipLevel: user.membershipLevel,
        followers: user.followers,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }
}
