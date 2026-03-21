import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
	final FirebaseAuth _auth = FirebaseAuth.instance;
	final FirebaseFirestore _firestore = FirebaseFirestore.instance;

	Future<UserModel?> signUp(String email, String password, String username) async {
		try {
			final credential = await _auth.createUserWithEmailAndPassword(email: email, password: password);
			final user = credential.user;
			if (user != null) {
				await _firestore.collection('users').doc(user.uid).set({
					'id': user.uid,
					'username': username,
					'email': email,
					'createdAt': FieldValue.serverTimestamp(),
				});
				return UserModel(
					id: user.uid,
					username: username,
					email: email,
					avatarUrl: '',
					coinBalance: 0,
					membershipLevel: 'Free',
					followers: [],
					createdAt: DateTime.now(), // This should be updated after fetching from Firestore if needed
				);
			}
			return null;
		} catch (_) {
			return null;
		}
	}

	Future<UserModel?> signIn(String email, String password) async {
		try {
			final credential = await _auth.signInWithEmailAndPassword(email: email, password: password);
			final user = credential.user;
			if (user != null) {
				final userData = await _firestore.collection('users').doc(user.uid).get();
				return UserModel.fromJson(userData.data()!);
			}
			return null;
		} catch (_) {
			return null;
		}
	}
}
	Future<void> signOut() async {
		// TODO: Implement supabase logic or import supabase client
		// await supabase.auth.signOut();
	}

	Future<UserModel?> getCurrentUser() async {
		// TODO: Implement supabase logic or import supabase client
		// final user = supabase.auth.currentUser;
		// if (user == null) return null;
		// final userData = await supabase.from('users').select().eq('id', user.id).single();
		// return UserModel.fromJson(userData);
		// TODO: Implement userData logic
		return null;
		// TODO: Complete this class or function
		// }
}
