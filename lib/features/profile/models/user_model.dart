import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String id;
  final String email;
  final String username;
  final String? avatarUrl;
  final String? introVideoUrl;
  final String? bio;
  final List<String> interests;
  final DateTime createdAt;
  final int coinBalance;
  final String membershipLevel;
  final List<String> followers;

  UserModel({
    required this.id,
    required this.email,
    required this.username,
    this.avatarUrl,
    this.introVideoUrl,
    this.bio,
    this.interests = const [],
    required this.createdAt,
    this.coinBalance = 0,
    this.membershipLevel = 'basic',
    this.followers = const [],
  });

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
        id: json['id'] ?? json['uid'] ?? '',
        email: json['email'] ?? '',
        username: json['username'] ?? json['displayName'] ?? '',
        avatarUrl: json['avatarUrl'],
        introVideoUrl: json['introVideoUrl'],
        bio: json['bio'],
        interests: List<String>.from(json['interests'] ?? []),
        createdAt: (json['createdAt'] is Timestamp)
            ? (json['createdAt'] as Timestamp).toDate()
            : DateTime.tryParse(json['createdAt']?.toString() ?? '') ?? DateTime.now(),
        coinBalance: json['coinBalance'] ?? 0,
        membershipLevel: json['membershipLevel'] ?? 'basic',
        followers: List<String>.from(json['followers'] ?? []),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'email': email,
        'username': username,
        'avatarUrl': avatarUrl,
        'introVideoUrl': introVideoUrl,
        'bio': bio,
        'interests': interests,
        'createdAt': createdAt.toIso8601String(),
        'coinBalance': coinBalance,
        'membershipLevel': membershipLevel,
        'followers': followers,
      };

  factory UserModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) =>
      UserModel.fromJson(doc.data() ?? {});
}
