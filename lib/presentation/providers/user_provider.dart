import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/auth/controllers/auth_controller.dart';
import '../../models/user_model.dart';

final userProvider = Provider<UserModel?>((ref) {
	final authState = ref.watch(authControllerProvider);
	final firebaseUser = FirebaseAuth.instance.currentUser;
	final uid = authState.uid ?? firebaseUser?.uid;

	if (uid == null) {
		return null;
	}

	return UserModel(
		id: uid,
		email: firebaseUser?.email ?? '',
		username: firebaseUser?.displayName ?? 'MixVy User',
		avatarUrl: firebaseUser?.photoURL,
		createdAt: DateTime.now(),
	);
});
