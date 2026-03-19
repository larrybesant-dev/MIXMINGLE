import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/user_model.dart';
import 'auth_service.dart';

class AuthController extends StateNotifier<UserModel?> {
		String? error;
	final AuthService _authService = AuthService();
	AuthController() : super(null);

	Future<void> login(String email, String password) async {
		try {
			final user = await _authService.login(email, password);
			if (user != null) {
				state = UserModel(
				  id: user.uid,
				  username: user.displayName ?? '',
				  email: user.email ?? '',
				  avatarUrl: user.photoURL ?? '',
				  coinBalance: 0,
				  membershipLevel: 'Free',
				  followers: [],
				);
				error = null;
			} else {
				error = 'Login failed';
			}
		} catch (e) {
			error = e.toString();
		}
	}
	Future<void> logout() async {
		try {
			await _authService.logout();
			state = null;
			error = null;
		} catch (e) {
			error = e.toString();
		}
	}
	Future<void> register(String email, String password) async {
		try {
			final user = await _authService.register(email, password);
			if (user != null) {
				state = UserModel(
				  id: user.uid,
				  username: user.displayName ?? '',
				  email: user.email ?? '',
				  avatarUrl: user.photoURL ?? '',
				  coinBalance: 0,
				  membershipLevel: 'Free',
				  followers: [],
				);
				error = null;
			} else {
				error = 'Registration failed';
			}
		} catch (e) {
			error = e.toString();
		}
	}
}
// Empty Dart file for auth_controller.dart
