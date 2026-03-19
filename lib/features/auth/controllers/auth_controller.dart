import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../repository/auth_repository.dart';
import '../providers/auth_providers.dart';
import '../state/auth_state.dart';

class AuthController extends StateNotifier<AuthState> {
  final AuthRepository _repo;

  AuthController(this._repo) : super(AuthState());

  Future<void> login(String email, String password) async {
    state = state.copyWith(isLoading: true, error: null);

    final result = await _repo.login(email, password);

    if (result != null && result.length > 20) {
      // UID returned
      state = state.copyWith(isLoading: false, uid: result);
    } else {
      // Error returned
      state = state.copyWith(isLoading: false, error: result);
    }
  }

  Future<void> signup(String email, String password) async {
    state = state.copyWith(isLoading: true, error: null);

    final result = await _repo.signup(email, password);

    if (result != null && result.length > 20) {
      state = state.copyWith(isLoading: false, uid: result);
    } else {
      state = state.copyWith(isLoading: false, error: result);
    }
  }

  Future<void> resetPassword(String email) async {
    state = state.copyWith(isLoading: true, error: null);

    final result = await _repo.resetPassword(email);

    state = state.copyWith(isLoading: false, error: result);
  }

  Future<void> logout() async {
    await _repo.logout();
    state = AuthState();
  }

  Future<void> sendEmailVerification() async {
    await _repo.sendEmailVerification();
  }
}
