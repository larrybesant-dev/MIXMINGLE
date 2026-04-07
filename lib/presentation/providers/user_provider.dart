import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/auth/controllers/auth_controller.dart';
import '../../features/profile/profile_controller.dart';
import '../../models/user_model.dart';

final userProvider = Provider<UserModel?>((ref) {
	final authState = ref.watch(authControllerProvider);
	final profileState = ref.watch(profileControllerProvider);
	final firebaseUser = FirebaseAuth.instance.currentUser;
	final uid = authState.uid ?? firebaseUser?.uid;

	if (uid == null) {
		return null;
	}

	// Prefer loaded profile data; fall back to a generic placeholder.
	// Never use firebaseUser.displayName — that can expose a real name
	// from Google Sign-In. The userId guard is relaxed: if the profile has
	// a non-empty username we use it regardless — the controller may finish
	// loading before it writes back userId to state.
	final profileUsername = profileState.username?.trim();
	final resolvedUsername = (profileUsername?.isNotEmpty == true)
		? profileUsername!
		: null;

	final profileAvatar = (profileState.userId == uid || profileState.userId == null)
			&& (profileState.avatarUrl?.isNotEmpty == true)
		? profileState.avatarUrl
		: firebaseUser?.photoURL;

	return UserModel(
		id: uid,
		email: firebaseUser?.email ?? '',
		username: resolvedUsername ?? 'MixVy User',
		avatarUrl: profileAvatar,
		createdAt: DateTime.now(),
	);
});
