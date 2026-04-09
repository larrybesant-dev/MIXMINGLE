import 'dart:async';
import 'dart:developer' as developer;
import 'package:flutter/foundation.dart' show kIsWeb;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../presentation/screens/google_sign_in_helper.dart';
import '../../../presentation/screens/apple_sign_in_helper.dart';
import '../../../services/push_messaging_service.dart';
import '../../../services/presence_service.dart';
import '../../../models/presence_model.dart';

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
  final GoogleSignInHelper _googleSignInHelper;
  final AppleSignInHelper _appleSignInHelper;

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
  final FirebaseFirestore? _firestore;
  final PresenceService? _presenceService;
  final Future<void> Function()? _unregisterToken;

  AuthController({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
    PresenceService? presenceService,
    Future<void> Function()? unregisterToken,
    GoogleSignInHelper? googleSignInHelper,
    AppleSignInHelper? appleSignInHelper,
  })  : _auth = auth ?? FirebaseAuth.instance,
        _firestore = firestore,
        _presenceService = presenceService,
        _unregisterToken = unregisterToken,
        _googleSignInHelper = googleSignInHelper ?? getGoogleSignInHelper(),
        _appleSignInHelper = appleSignInHelper ?? getAppleSignInHelper();

  @override
  AuthState build() {
    _authStateSubscription?.cancel();
    _authStateSubscription = _auth.authStateChanges().listen((user) {
      state = state.copyWith(uid: user?.uid, isLoading: false, error: null);
      // Update global presence on auth change.
      if (user != null) {
        (_presenceService ?? PresenceService()).setStatus(user.uid, UserStatus.online).ignore();
      }
    });

    unawaited(_configureWebPersistence());
    unawaited(_repairInvalidCachedSession());
    unawaited(_completeRedirectSignInIfNeeded());

    ref.onDispose(() {
      _authStateSubscription?.cancel();
    });

    return AuthState(isLoading: true, uid: _auth.currentUser?.uid);
  }

  Future<void> _configureWebPersistence() async {
    if (!kIsWeb) {
      return;
    }

    try {
      await _auth.setPersistence(Persistence.LOCAL);
    } on FirebaseAuthException catch (e, st) {
      _logAuthException(e, st, context: 'set-persistence');
    } catch (e, st) {
      developer.log(
        'Failed to configure web auth persistence',
        name: 'AuthController',
        error: e,
        stackTrace: st,
      );
    }
  }

  Future<void> _repairInvalidCachedSession() async {
    final user = _auth.currentUser;
    if (user == null) {
      return;
    }

    try {
      // Force a network refresh on web so a stale emulator token in localStorage
      // is caught eagerly before the router renders the home screen.
      await user.getIdToken(kIsWeb);
    } on FirebaseAuthException catch (e, st) {
      _logAuthException(e, st, context: 'cached-session-validation');
      if (_isInvalidSessionError(e.code)) {
        await _auth.signOut();
        state = state.copyWith(uid: null, error: null);
      }
    } catch (e, st) {
      developer.log(
        'Non-Firebase error while validating cached session',
        name: 'AuthController',
        error: e,
        stackTrace: st,
      );
      await _auth.signOut();
      state = state.copyWith(uid: null, error: null);
    }
  }

  bool _isInvalidSessionError(String code) {
    switch (code) {
      case 'user-token-expired':
      case 'invalid-user-token':
      case 'user-disabled':
      case 'user-not-found':
      case 'invalid-credential':
      case 'requires-recent-login':
        return true;
      default:
        return false;
    }
  }

  Future<void> _completeRedirectSignInIfNeeded() async {
    try {
      await _googleSignInHelper.completePendingRedirectSignIn();
      await _appleSignInHelper.completePendingRedirectSignIn();
      final uid = _auth.currentUser?.uid;
      if (uid != null) {
        await _ensureUserDocument(_auth.currentUser!);
        state = state.copyWith(uid: uid, isLoading: false, error: null);
      }
    } on FirebaseAuthException catch (e, st) {
      _logAuthException(e, st, context: 'redirect-result');
      state = state.copyWith(
        isLoading: false,
        error: _getReadableError(e.code),
      );
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
      if (cred.user != null) {
        await _ensureUserDocument(cred.user!);
      }
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
      if (cred.user != null) {
        await _ensureUserDocument(cred.user!);
      }
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
      case 'canceled':
        return 'Sign-in was cancelled. Please try again.';
      case 'email-already-in-use':
        return 'Email already in use';
      case 'weak-password':
        return 'Password is too weak';
      default:
        return 'Login failed: $code';
    }
  }

  Future<void> signInWithApple() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _appleSignInHelper.signInWithApple();
      final user = _auth.currentUser;
      if (user != null) {
        await _ensureUserDocument(user);
      }
      state = state.copyWith(isLoading: false, uid: user?.uid);
    } on FirebaseAuthException catch (e, st) {
      _logAuthException(e, st, context: 'apple-sign-in');
      state = state.copyWith(isLoading: false, error: _getReadableError(e.code));
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> signInAsGuest() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final result = await _auth.signInAnonymously();
      final user = result.user;
      if (user != null) {
        await _ensureUserDocument(user);
      }
      state = state.copyWith(isLoading: false, uid: user?.uid);
    } on FirebaseAuthException catch (e, st) {
      _logAuthException(e, st, context: 'guest-sign-in');
      state = state.copyWith(isLoading: false, error: _getReadableError(e.code));
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> logout() async {
    final uid = _auth.currentUser?.uid;
    if (uid != null) {
      (_presenceService ?? PresenceService()).setStatus(uid, UserStatus.offline).ignore();
    }
    await (_unregisterToken?.call() ?? PushMessagingService.instance.unregisterCurrentToken());
    await _auth.signOut();
    state = state.copyWith(isLoading: false, uid: null, error: null);
  }

  Future<void> _ensureUserDocument(User user) async {
    final firestore = _firestore ?? _tryResolveFirestore();
    if (firestore == null) {
      return;
    }

    try {
      await firestore.collection('users').doc(user.uid).set({
        'id': user.uid,
        'username': user.displayName ?? '',
        'usernameLower': (user.displayName ?? '').toLowerCase(),
        'email': user.email ?? '',
        'avatarUrl': user.photoURL,
        'updatedAt': FieldValue.serverTimestamp(),
        'createdAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e, st) {
      developer.log(
        'Failed to ensure user document for ${user.uid}',
        name: 'AuthController',
        error: e,
        stackTrace: st,
      );
    }
  }

  FirebaseFirestore? _tryResolveFirestore() {
    try {
      return FirebaseFirestore.instance;
    } catch (_) {
      return null;
    }
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
