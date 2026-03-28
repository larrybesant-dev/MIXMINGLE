import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String id;
  final String email;
  final String username;
  final String? avatarUrl;
  final List<String> galleryUrls;
  final String? introVideoUrl;
  final String? bio;
  final String? vibePrompt;
  final String? firstDatePrompt;
  final String? musicTastePrompt;
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
    this.galleryUrls = const [],
    this.introVideoUrl,
    this.bio,
    this.vibePrompt,
    this.firstDatePrompt,
    this.musicTastePrompt,
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
        galleryUrls: List<String>.from(json['galleryUrls'] ?? const []),
        introVideoUrl: json['introVideoUrl'],
        bio: json['bio'],
        vibePrompt: json['vibePrompt'],
        firstDatePrompt: json['firstDatePrompt'],
        musicTastePrompt: json['musicTastePrompt'],
        interests: List<String>.from(json['interests'] ?? []),
        createdAt: (json['createdAt'] is Timestamp)
            ? (json['createdAt'] as Timestamp).toDate()
            : DateTime.tryParse(json['createdAt']?.toString() ?? '') ?? DateTime.now(),
        coinBalance: ((json['balance'] ?? json['coinBalance']) as num?)?.toInt() ?? 0,
        membershipLevel: json['membershipLevel'] ?? 'basic',
        followers: List<String>.from(json['followers'] ?? []),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'email': email,
        'username': username,
        'avatarUrl': avatarUrl,
        'galleryUrls': galleryUrls,
        'introVideoUrl': introVideoUrl,
        'bio': bio,
        'vibePrompt': vibePrompt,
        'firstDatePrompt': firstDatePrompt,
        'musicTastePrompt': musicTastePrompt,
        'interests': interests,
        'createdAt': createdAt.toIso8601String(),
        'coinBalance': coinBalance,
        'membershipLevel': membershipLevel,
        'followers': followers,
      };

  factory UserModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) =>
      UserModel.fromJson(doc.data() ?? {});
}
