import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
	final String id;
	final String username;
	final String email;
	final String avatarUrl;
	final int coinBalance;
	final String membershipLevel;
	final List<String> followers;

	UserModel({
		required this.id,
		required this.username,
		required this.email,
		required this.avatarUrl,
		required this.coinBalance,
		required this.membershipLevel,
		required this.followers,
	});

	factory UserModel.fromFirestore(DocumentSnapshot doc) {
		final data = doc.data() as Map<String, dynamic>;
		return UserModel(
			id: doc.id,
			username: data['username'] ?? '',
			email: data['email'] ?? '',
			avatarUrl: data['avatarUrl'] ?? '',
			coinBalance: data['coinBalance'] ?? 0,
			membershipLevel: data['membershipLevel'] ?? 'Free',
			followers: List<String>.from(data['followers'] ?? []),
		);
	}

	Map<String, dynamic> toMap() {
		return {
			'username': username,
			'email': email,
			'avatarUrl': avatarUrl,
			'coinBalance': coinBalance,
			'membershipLevel': membershipLevel,
			'followers': followers,
		};
	}
}
