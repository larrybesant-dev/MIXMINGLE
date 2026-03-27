import 'dart:async';
import 'dart:developer' as developer;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../presentation/screens/google_sign_in_helper.dart';

class AuthState {
  final bool isLoading;
  final String? error;
  final String? uid;

  static const Object _unset = Object();

  const AuthState({this.isLoading = false, this.error, this.uid});

  AuthState copyWith({
    bool? isLoading,
    Object? error = _unset,
    Object? uid = _unset,
  }) {
    return AuthState(
      isLoading: isLoading ?? this.isLoading,
      error: identical(error, _unset) ? this.error : error as String?,
      uid: identical(uid, _unset) ? this.uid : uid as String?,
    );
  }
}

final authControllerProvider = NotifierProvider<AuthController, AuthState>(
  () => AuthController(),
);


class AuthController extends Notifier<AuthState> {
  final GoogleSignInHelper _googleSignInHelper = getGoogleSignInHelper();

  StreamSubscription<User?>? _authStateSubscription;

    Future<void> signInWithGoogle() async {
      state = state.copyWith(isLoading: true, error: null);
      try {
        await _googleSignInHelper.signInWithGoogle();
        state = state.copyWith(isLoading: false, uid: _auth.currentUser?.uid);
      } on FirebaseAuthException catch (e, st) {
        _logAuthException(e, st, context: 'google-sign-in');
        state = state.copyWith(isLoading: false, error: _getReadableError(e.code));
      } catch (e) {
        state = state.copyWith(isLoading: false, error: e.toString());
      }
    }
  final FirebaseAuth _auth;

  AuthController({FirebaseAuth? auth}) : _auth = auth ?? FirebaseAuth.instance;

  @override
  AuthState build() {
    _authStateSubscription?.cancel();
    _authStateSubscription = _auth.authStateChanges().listen((user) {
      state = state.copyWith(uid: user?.uid);
    });

    unawaited(_completeRedirectSignInIfNeeded());

    ref.onDispose(() {
      _authStateSubscription?.cancel();
    });

    return AuthState(uid: _auth.currentUser?.uid);
  }

  Future<void> _completeRedirectSignInIfNeeded() async {
    try {
      await _googleSignInHelper.completePendingRedirectSignIn();
      final uid = _auth.currentUser?.uid;
      if (uid != null) {
        state = state.copyWith(uid: uid, error: null);
      }
    } on FirebaseAuthException catch (e, st) {
      _logAuthException(e, st, context: 'redirect-result');
      state = state.copyWith(error: _getReadableError(e.code));
    } catch (_) {
      // Ignore non-auth redirect completion errors to avoid noisy startup failures.
    }
  }

  Future<void> signup(String email, String password) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final cred = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      state = state.copyWith(isLoading: false, uid: cred.user?.uid);
    } on FirebaseAuthException catch (e, st) {
      _logAuthException(e, st, context: 'signup');
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
    } on FirebaseAuthException catch (e, st) {
      _logAuthException(e, st, context: 'login');
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
      case 'account-exists-with-different-credential':
        return 'Account exists with another sign-in method. Try a different provider.';
      case 'popup-blocked':
      case 'popup-closed-by-user':
      case 'web-context-cancelled':
        return 'Sign-in was cancelled. Please try again.';
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
    } on FirebaseAuthException catch (e, st) {
      _logAuthException(e, st, context: 'reset-password');
      final errorMessage = _getReadableError(e.code);
      state = state.copyWith(isLoading: false, error: errorMessage);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: "Unexpected error: $e");
    }
  }

  void _logAuthException(
    FirebaseAuthException e,
    StackTrace stackTrace, {
    required String context,
  }) {
    developer.log(
      'FirebaseAuthException in $context: ${e.code}',
      name: 'AuthController',
      error: e,
      stackTrace: stackTrace,
    );
  }
}
