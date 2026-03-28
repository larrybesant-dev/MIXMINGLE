import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String id;
  final String email;
  final String username;
  final String? avatarUrl;
  final String? coverPhotoUrl;
  final List<String> galleryUrls;
  final String? introVideoUrl;
  final String? bio;
  final String? aboutMe;
  final int? age;
  final String? gender;
  final String? location;
  final String? relationshipStatus;
  final String? vibePrompt;
  final String? firstDatePrompt;
  final String? musicTastePrompt;
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
    this.galleryUrls = const [],
    this.introVideoUrl,
    this.bio,
    this.aboutMe,
    this.age,
    this.gender,
    this.location,
    this.relationshipStatus,
    this.vibePrompt,
    this.firstDatePrompt,
    this.musicTastePrompt,
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
        galleryUrls: List<String>.from(json['galleryUrls'] ?? const []),
        introVideoUrl: json['introVideoUrl'],
        bio: json['bio'],
        aboutMe: json['aboutMe'],
        age: (json['age'] as num?)?.toInt(),
        gender: json['gender'],
        location: json['location'],
        relationshipStatus: json['relationshipStatus'],
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
        'galleryUrls': galleryUrls,
        'introVideoUrl': introVideoUrl,
        'bio': bio,
        'aboutMe': aboutMe,
        'age': age,
        'gender': gender,
        'location': location,
        'relationshipStatus': relationshipStatus,
        'vibePrompt': vibePrompt,
        'firstDatePrompt': firstDatePrompt,
        'musicTastePrompt': musicTastePrompt,
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

  factory UserModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) =>
      UserModel.fromJson(doc.data() ?? {});
}
