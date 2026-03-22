import '../core/error_handler.dart';
import '../core/logger.dart';
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
					       createdAt: DateTime.now(),
				       );
			       }
			       return null;
		       } catch (e) {
			       ErrorHandler.handle(e);
			       Logger.log('Sign up error: $e');
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
		       } catch (e) {
			       ErrorHandler.handle(e);
			       Logger.log('Sign in error: $e');
			       return null;
		       }
	}
	Future<void> signOut() async {
		try {
			await _auth.signOut();
		} catch (e) {
			ErrorHandler.handle(e);
			Logger.log('Sign out error: $e');
		}
	}

	Future<UserModel?> getCurrentUser() async {
		try {
			final user = _auth.currentUser;
			if (user == null) return null;
			final userData = await _firestore.collection('users').doc(user.uid).get();
			if (!userData.exists) return null;
			return UserModel.fromJson(userData.data()!);
		} catch (e) {
			ErrorHandler.handle(e);
			Logger.log('Get current user error: $e');
			return null;
		}
	}
}
}
