
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'models/user_model.dart';

class ProfileState {
  final bool isLoading;
  final String? error;
  final String? userId;
  final String? username;
  final String? email;
  final String? avatarUrl;
  final String? introVideoUrl;
  final String? bio;
  final List<String> interests;
  final int coinBalance;
  final String? membershipLevel;
  final List<String> followers;

  static const Object _unset = Object();

  const ProfileState({
    this.isLoading = false,
    this.error,
    this.userId,
    this.username,
    this.email,
    this.avatarUrl,
    this.introVideoUrl,
    this.bio,
    this.interests = const [],
    this.coinBalance = 0,
    this.membershipLevel,
    this.followers = const [],
  });

  ProfileState copyWith({
    bool? isLoading,
    Object? error = _unset,
    Object? userId = _unset,
    Object? username = _unset,
    Object? email = _unset,
    Object? avatarUrl = _unset,
    Object? introVideoUrl = _unset,
    Object? bio = _unset,
    List<String>? interests,
    int? coinBalance,
    Object? membershipLevel = _unset,
    List<String>? followers,
  }) {
    return ProfileState(
      isLoading: isLoading ?? this.isLoading,
      error: identical(error, _unset) ? this.error : error as String?,
      userId: identical(userId, _unset) ? this.userId : userId as String?,
      username: identical(username, _unset) ? this.username : username as String?,
      email: identical(email, _unset) ? this.email : email as String?,
      avatarUrl: identical(avatarUrl, _unset) ? this.avatarUrl : avatarUrl as String?,
      introVideoUrl: identical(introVideoUrl, _unset) ? this.introVideoUrl : introVideoUrl as String?,
        bio: identical(bio, _unset) ? this.bio : bio as String?,
        interests: interests ?? this.interests,
      coinBalance: coinBalance ?? this.coinBalance,
      membershipLevel: identical(membershipLevel, _unset)
          ? this.membershipLevel
          : membershipLevel as String?,
      followers: followers ?? this.followers,
    );
  }
}

final profileControllerProvider = NotifierProvider<ProfileController, ProfileState>(
  () => ProfileController(),
);

class ProfileController extends Notifier<ProfileState> {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  ProfileController({FirebaseFirestore? firestore, FirebaseAuth? auth})
      : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  @override
  ProfileState build() {
    final user = _auth.currentUser;
    return ProfileState(
      userId: user?.uid,
      email: user?.email,
      username: user?.displayName,
      avatarUrl: user?.photoURL,
      introVideoUrl: null,
      bio: null,
      interests: const [],
    );
  }

  Future<void> loadCurrentProfile() async {
    await fetchProfile(_auth.currentUser?.uid);
  }

  Future<void> updateProfile(ProfileState profile) async {
    state = state.copyWith(isLoading: true, error: null);

    final user = _auth.currentUser;
    final userId = profile.userId ?? user?.uid;
    if (userId == null || userId.isEmpty) {
      state = state.copyWith(isLoading: false, error: 'No signed-in user');
      return;
    }

    try {
      final userRef = _firestore.collection('users').doc(userId);
      final normalizedUsername = (profile.username ?? '').trim();
      final normalizedEmail = (profile.email ?? user?.email ?? '').trim();
      final normalizedAvatar = (profile.avatarUrl ?? '').trim();
      final normalizedVideo = (profile.introVideoUrl ?? '').trim();
      final normalizedBio = (profile.bio ?? '').trim();
      final normalizedInterests = profile.interests
          .map((item) => item.trim().toLowerCase())
          .where((item) => item.isNotEmpty)
          .toSet()
          .toList();
      await userRef.set({
        'id': userId,
        'username': normalizedUsername,
        'email': normalizedEmail,
        'avatarUrl': normalizedAvatar.isEmpty ? null : normalizedAvatar,
        'introVideoUrl': normalizedVideo.isEmpty ? null : normalizedVideo,
        'bio': normalizedBio.isEmpty ? null : normalizedBio,
        'interests': normalizedInterests,
        'coinBalance': profile.coinBalance,
        'membershipLevel': profile.membershipLevel ?? 'free',
        'followers': profile.followers,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      state = profile.copyWith(
        isLoading: false,
        error: null,
        userId: userId,
        username: normalizedUsername,
        email: normalizedEmail,
        avatarUrl: normalizedAvatar.isEmpty ? null : normalizedAvatar,
        introVideoUrl: normalizedVideo.isEmpty ? null : normalizedVideo,
        bio: normalizedBio.isEmpty ? null : normalizedBio,
        interests: normalizedInterests,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> fetchProfile(String? userId) async {
    final resolvedUserId = userId ?? _auth.currentUser?.uid;
    if (resolvedUserId == null || resolvedUserId.isEmpty) {
      state = state.copyWith(isLoading: false, error: 'No signed-in user');
      return;
    }

    state = state.copyWith(isLoading: true, error: null);

    try {
      final userDoc = await _firestore.collection('users').doc(resolvedUserId).get();
      if (!userDoc.exists) {
        final currentUser = _auth.currentUser;
        state = state.copyWith(
          isLoading: false,
          error: null,
          userId: resolvedUserId,
          username: currentUser?.displayName,
          email: currentUser?.email,
          avatarUrl: currentUser?.photoURL,
          introVideoUrl: null,
          bio: null,
          interests: const [],
        );
        return;
      }

      final user = UserModel.fromFirestore(userDoc);
      state = state.copyWith(
        isLoading: false,
        error: null,
        userId: user.id.isNotEmpty ? user.id : resolvedUserId,
        username: user.username.isNotEmpty ? user.username : _auth.currentUser?.displayName,
        email: user.email.isNotEmpty ? user.email : _auth.currentUser?.email,
        avatarUrl: user.avatarUrl,
        introVideoUrl: user.introVideoUrl,
        bio: user.bio,
        interests: user.interests,
        coinBalance: user.coinBalance,
        membershipLevel: user.membershipLevel,
        followers: user.followers,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }
}
