// lib/features/auth/repositories/i_auth_repository.dart
//
// Abstract contract for authentication operations.
// Implementations must validate UID before any write.
import 'package:firebase_auth/firebase_auth.dart';

abstract class IAuthRepository {
  /// Returns the currently signed-in user, or null.
  User? get currentUser;

  /// Sign in with email and password.
  Future<UserCredential> signInWithEmail({
    required String email,
    required String password,
  });

  /// Register with email and password.
  Future<UserCredential> registerWithEmail({
    required String email,
    required String password,
  });

  /// Sign in with Google OAuth.
  Future<UserCredential> signInWithGoogle();

  /// Sign out the current user.
  Future<void> signOut();

  /// Send a password reset e-mail.
  Future<void> sendPasswordResetEmail({required String email});

  /// Delete the current user account.
  Future<void> deleteAccount();
}
