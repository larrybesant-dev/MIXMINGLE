import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/auth/controllers/auth_controller.dart';
import '../../features/profile/profile_controller.dart';
import '../../models/user_model.dart';

bool _looksLikePersonalName(String value) {
  final normalized = value.trim();
  if (normalized.isEmpty) {
    return false;
  }

  if (normalized.contains('@')) {
    return true;
  }

  final parts = normalized
      .split(RegExp(r'\s+'))
      .where((part) => part.isNotEmpty)
      .toList(growable: false);
  final wordPattern = RegExp(r"^[A-Za-z][A-Za-z'’-]*$");
  return parts.length >= 2 && parts.every(wordPattern.hasMatch);
}

String resolvePublicUsername({
  required String uid,
  String? profileUsername,
  String? authDisplayName,
}) {
  final normalizedUid = uid.trim();
  final normalizedProfile = profileUsername?.trim() ?? '';
  final normalizedDisplayName = authDisplayName?.trim() ?? '';

  final matchesAuthDisplayName =
      normalizedProfile.isNotEmpty &&
      normalizedDisplayName.isNotEmpty &&
      normalizedProfile.toLowerCase() == normalizedDisplayName.toLowerCase();
  final looksPersonal = _looksLikePersonalName(normalizedProfile);

  if (normalizedProfile.isNotEmpty &&
      !matchesAuthDisplayName &&
      !looksPersonal) {
    return normalizedProfile;
  }

  if (normalizedUid.isEmpty) {
    return 'MixVy User';
  }

  final compactUid = normalizedUid
      .replaceAll(RegExp(r'[^A-Za-z0-9]'), '')
      .toUpperCase();
  final suffix = compactUid.isEmpty
      ? ''
      : compactUid.substring(0, compactUid.length < 4 ? compactUid.length : 4);
  return suffix.isEmpty ? 'MixVy User' : 'Guest $suffix';
}

final userProvider = Provider<UserModel?>((ref) {
  final authState = ref.watch(authControllerProvider);
  final profileState = ref.watch(profileControllerProvider);
  final firebaseUser = FirebaseAuth.instance.currentUser;
  final uid = authState.uid ?? firebaseUser?.uid;

  if (uid == null) {
    return null;
  }

  final resolvedUsername = resolvePublicUsername(
    uid: uid,
    profileUsername: profileState.username,
    authDisplayName: firebaseUser?.displayName,
  );

  final profileAvatar =
      (profileState.userId == uid || profileState.userId == null) &&
          (profileState.avatarUrl?.isNotEmpty == true)
      ? profileState.avatarUrl
      : firebaseUser?.photoURL;

  return UserModel(
    id: uid,
    email: firebaseUser?.email ?? '',
    username: resolvedUsername,
    avatarUrl: profileAvatar,
    createdAt: DateTime.now(),
  );
});
