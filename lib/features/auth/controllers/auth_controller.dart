import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthState {
  final bool isLoading;
  final String? error;
  final String? uid;

  const AuthState({
    this.isLoading = false,
    this.error,
    this.uid,
  });

  AuthState copyWith({
    bool? isLoading,
    String? error,
    String? uid,
  }) {
    return AuthState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      uid: uid ?? this.uid,
    );
  }
}

final authControllerProvider = StateNotifierProvider<AuthController, AuthState>(
  (ref) => AuthController(FirebaseAuth.instance),
);


class AuthController extends StateNotifier<AuthState> {
  final FirebaseAuth _auth;

  AuthController(this._auth) : super(AuthState(uid: _auth.currentUser?.uid)) {
    _auth.authStateChanges().listen((user) {
      state = state.copyWith(uid: user?.uid);
    });
  }


  Future<void> signup(String email, String password) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final cred = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      state = state.copyWith(isLoading: false, uid: cred.user?.uid);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> login(String email, String password) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final cred = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      state = state.copyWith(isLoading: false, uid: cred.user?.uid);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> logout() async {
    await FirebaseAuth.instance.signOut();
    state = state.copyWith(uid: null);
  }
  
  Future<void> resetPassword(String email) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }
}
