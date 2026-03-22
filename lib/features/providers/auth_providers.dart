import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';

final firebaseAuthProvider = Provider<FirebaseAuth>((ref) {
  return FirebaseAuth.instance;
});

final authControllerProvider = NotifierProvider<AuthController, AuthState>(
  () => AuthController(),
);

class AuthState {
  final bool isLoading;
  final String? error;
  final User? user;

  AuthState({
    this.isLoading = false,
    this.error,
    this.user,
  });

  AuthState copyWith({
    bool? isLoading,
    String? error,
    User? user,
  }) {
    return AuthState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      user: user ?? this.user,
    );
  }
}

class AuthController extends Notifier<AuthState> {
  late final FirebaseAuth _auth;

  @override
  AuthState build() {
    _auth = FirebaseAuth.instance;
    _auth.authStateChanges().listen((user) {
      state = state.copyWith(user: user);
    });
    return AuthState();
  }

  Future<void> login(String email, String password) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
      state = state.copyWith(isLoading: false);
    } on FirebaseAuthException catch (e) {
      state = state.copyWith(isLoading: false, error: e.message);
    }
  }

  Future<void> signup(String email, String password) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _auth.createUserWithEmailAndPassword(email: email, password: password);
      state = state.copyWith(isLoading: false);
    } on FirebaseAuthException catch (e) {
      state = state.copyWith(isLoading: false, error: e.message);
    }
  }

  Future<void> logout() async {
    await _auth.signOut();
  }
}
