import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/models.dart';

class AuthService {
	final supabase = Supabase.instance.client;

	Future<UserModel?> signUp(String email, String password, String username) async {
		try {
			final response = await supabase.auth.signUp(email: email, password: password);
			if (response.user != null) {
				await supabase.from('users').insert({
					'id': response.user!.id,
					'username': username,
					'email': email,
				});
				return UserModel(
					id: response.user!.id,
					username: username,
					email: email,
					avatarUrl: '',
					coinBalance: 0,
					membershipLevel: 'Free',
					followers: [],
				);
			}
			return null;
		} catch (_) {
			return null;
		}
	}

	Future<UserModel?> signIn(String email, String password) async {
		try {
			final response = await supabase.auth.signInWithPassword(email: email, password: password);
			if (response.user != null) {
				final userData = await supabase.from('users').select().eq('id', response.user!.id).single();
				return UserModel.fromJson(userData);
			}
			return null;
		} catch (_) {
			return null;
		}
	}

	Future<void> signOut() async {
		await supabase.auth.signOut();
	}

	Future<UserModel?> getCurrentUser() async {
		final user = supabase.auth.currentUser;
		if (user == null) return null;
		final userData = await supabase.from('users').select().eq('id', user.id).single();
		return UserModel.fromJson(userData);
	}
}
