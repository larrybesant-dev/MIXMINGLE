import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<UserModel?> signIn(String email, String password) async {
    try {
      final userCredential = await _auth.signInWithEmailAndPassword(email: email, password: password);
      final userDoc = await _firestore.collection('users').doc(userCredential.user!.uid).get();
      return UserModel.fromFirestore(userDoc);
    } catch (e) {
      return null;
    }
  }

  Future<UserModel?> register(String email, String password, String username) async {
    try {
      final userCredential = await _auth.createUserWithEmailAndPassword(email: email, password: password);
      final user = UserModel(
        id: userCredential.user!.uid,
        username: username,
        email: email,
        avatarUrl: '',
        coinBalance: 0,
        membershipLevel: 'Free',
        followers: [],
      );
      await _firestore.collection('users').doc(user.id).set(user.toMap());
      return user;
    } catch (e) {
      return null;
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }
}
