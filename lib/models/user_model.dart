


import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String id;
  final String email;
  final String username;
  final String? avatarUrl;
  final String? coverPhotoUrl;
  final String? bio;
  final String? aboutMe;
  final int? age;
  final String? gender;
  final String? location;
  final String? relationshipStatus;
  final List<String> interests;
  final DateTime createdAt;
  final int coinBalance;
  final String membershipLevel;
  final List<String> followers;
  final String camViewPolicy;
  final bool adultModeEnabled;
  final bool adultConsentAccepted;
  final String themeId;

  UserModel({
    required this.id,
    required this.email,
    required this.username,
    this.avatarUrl,
    this.coverPhotoUrl,
    this.bio,
    this.aboutMe,
    this.age,
    this.gender,
    this.location,
    this.relationshipStatus,
    this.interests = const [],
    required this.createdAt,
    this.coinBalance = 0,
    this.membershipLevel = 'basic',
    this.followers = const [],
    this.camViewPolicy = 'approvedOnly',
    this.adultModeEnabled = false,
    this.adultConsentAccepted = false,
    this.themeId = 'midnight',
  });

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
        id: json['id'] ?? json['uid'] ?? '',
        email: json['email'] ?? '',
        username: json['username'] ?? json['displayName'] ?? '',
        avatarUrl: json['avatarUrl'],
        coverPhotoUrl: json['coverPhotoUrl'],
        bio: json['bio'],
        aboutMe: json['aboutMe'],
        age: (json['age'] as num?)?.toInt(),
        gender: json['gender'],
        location: json['location'],
        relationshipStatus: json['relationshipStatus'],
        interests: List<String>.from(json['interests'] ?? []),
        createdAt: (json['createdAt'] is Timestamp)
            ? (json['createdAt'] as Timestamp).toDate()
            : DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
        coinBalance: ((json['balance'] ?? json['coinBalance']) as num?)?.toInt() ?? 0,
        membershipLevel: json['membershipLevel'] ?? 'basic',
        followers: List<String>.from(json['followers'] ?? []),
        camViewPolicy: json['camViewPolicy'] ?? 'approvedOnly',
        adultModeEnabled: json['adultModeEnabled'] as bool? ?? false,
        adultConsentAccepted: json['adultConsentAccepted'] as bool? ?? false,
        themeId: json['themeId'] ?? 'midnight',
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'email': email,
        'username': username,
        'avatarUrl': avatarUrl,
        'coverPhotoUrl': coverPhotoUrl,
        'bio': bio,
        'aboutMe': aboutMe,
        'age': age,
        'gender': gender,
        'location': location,
        'relationshipStatus': relationshipStatus,
        'interests': interests,
        'createdAt': createdAt.toIso8601String(),
        'coinBalance': coinBalance,
        'membershipLevel': membershipLevel,
        'followers': followers,
        'camViewPolicy': camViewPolicy,
        'adultModeEnabled': adultModeEnabled,
        'adultConsentAccepted': adultConsentAccepted,
        'themeId': themeId,
      };

  factory UserModel.fromFirestore(DocumentSnapshot doc) =>
      UserModel.fromJson(doc.data() as Map<String, dynamic>);
}
