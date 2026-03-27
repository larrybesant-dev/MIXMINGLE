import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../presentation/screens/google_sign_in_helper_stub.dart';

class AuthState {
  final bool isLoading;
  final String? error;
  final String? uid;

  const AuthState({this.isLoading = false, this.error, this.uid});

  AuthState copyWith({bool? isLoading, String? error, String? uid}) {
    return AuthState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      uid: uid ?? this.uid,
    );
  }
}

final authControllerProvider = NotifierProvider<AuthController, AuthState>(
  () => AuthController(),
);


class AuthController extends Notifier<AuthState> {

    Future<void> signInWithGoogle() async {
      state = state.copyWith(isLoading: true, error: null);
      try {
        await getGoogleSignInHelper().signInWithGoogle();
        state = state.copyWith(isLoading: false, uid: _auth.currentUser?.uid);
      } catch (e) {
        state = state.copyWith(isLoading: false, error: e.toString());
      }
    }
  final FirebaseAuth _auth;

  AuthController({FirebaseAuth? auth}) : _auth = auth ?? FirebaseAuth.instance;

  @override
  AuthState build() {
    _auth.authStateChanges().listen((user) {
      state = state.copyWith(uid: user?.uid);
    });
    return AuthState(uid: _auth.currentUser?.uid);
  }

  Future<void> signup(String email, String password) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final cred = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      state = state.copyWith(isLoading: false, uid: cred.user?.uid);
    } on FirebaseAuthException catch (e) {
      final errorMessage = _getReadableError(e.code);
      state = state.copyWith(isLoading: false, error: errorMessage);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: "Unexpected error: $e");
    }
  }

  Future<void> login(String email, String password) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final normalizedEmail = email.trim();

      final cred = await _auth.signInWithEmailAndPassword(
        email: normalizedEmail,
        password: password.trim(),
      );
      state = state.copyWith(isLoading: false, uid: cred.user?.uid);
    } on FirebaseAuthException catch (e) {
      state = state.copyWith(isLoading: false, error: _getReadableError(e.code));
    } catch (e) {
      state = state.copyWith(isLoading: false, error: "Unexpected error: $e");
    }
  }

  String _getReadableError(String code) {
    switch (code) {
      case 'invalid-credential':
        return 'Invalid email or password. If this account was created with Google, use Google Sign-In';
      case 'invalid-login-credentials':
        return 'Invalid email or password';
      case 'user-not-found':
        return 'No account found with this email';
      case 'wrong-password':
        return 'Incorrect password';
      case 'invalid-email':
        return 'Invalid email address';
      case 'user-disabled':
        return 'This account has been disabled';
      case 'too-many-requests':
        return 'Too many login attempts. Try again later';
      case 'email-already-in-use':
        return 'Email already in use';
      case 'weak-password':
        return 'Password is too weak';
      default:
        return 'Login failed: $code';
    }
  }

  Future<void> logout() async {
    await _auth.signOut();
    state = state.copyWith(uid: null);
  }

  Future<void> resetPassword(String email) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _auth.sendPasswordResetEmail(email: email);
      state = state.copyWith(isLoading: false);
    } on FirebaseAuthException catch (e) {
      final errorMessage = _getReadableError(e.code);
      state = state.copyWith(isLoading: false, error: errorMessage);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: "Unexpected error: $e");
    }
  }
}
