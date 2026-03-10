
export 'providers.dart';
export 'user_providers.dart';
export 'social_providers.dart';
export 'unread_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';

final firebaseAuthProvider = Provider<FirebaseAuth>((ref) => FirebaseAuth.instance);

/// Auth state provider (Firebase user stream)
final authStateProvider = StreamProvider<User?>((ref) {
  return ref.read(firebaseAuthProvider).authStateChanges();
});

/// Current user provider (User object)
final currentUserProvider = StreamProvider<User?>((ref) {
  return ref.read(firebaseAuthProvider).userChanges();
});
