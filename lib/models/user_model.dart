


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
  final int vipLevel;
  final List<String> badges;

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
    this.vipLevel = 0,
    this.badges = const [],
  });

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
        id: _stringOrEmpty(json['id'] ?? json['uid']),
        email: _stringOrEmpty(json['email']),
        username: _stringOrEmpty(json['username']),
        avatarUrl: _stringOrNull(json['avatarUrl']),
        coverPhotoUrl: _stringOrNull(json['coverPhotoUrl']),
        bio: _stringOrNull(json['bio']),
        aboutMe: _stringOrNull(json['aboutMe']),
        age: (json['age'] as num?)?.toInt(),
        gender: _stringOrNull(json['gender']),
        location: _stringOrNull(json['location']),
        relationshipStatus: _stringOrNull(json['relationshipStatus']),
        interests: _stringList(json['interests']),
        createdAt: (json['createdAt'] is Timestamp)
            ? (json['createdAt'] as Timestamp).toDate()
            : DateTime.tryParse(json['createdAt']?.toString() ?? '') ?? DateTime.now(),
        coinBalance: ((json['balance'] ?? json['coinBalance']) as num?)?.toInt() ?? 0,
        membershipLevel: _stringOrEmpty(json['membershipLevel'], fallback: 'basic'),
        followers: _stringList(json['followers']),
        camViewPolicy: _stringOrEmpty(json['camViewPolicy'], fallback: 'approvedOnly'),
        adultModeEnabled: _boolOr(json['adultModeEnabled'], fallback: false),
        adultConsentAccepted: _boolOr(json['adultConsentAccepted'], fallback: false),
        themeId: _stringOrEmpty(json['themeId'], fallback: 'midnight'),
        vipLevel: (json['vipLevel'] as num?)?.toInt() ?? 0,
        badges: _stringList(json['badges']),
      );

  static bool _boolOr(dynamic value, {required bool fallback}) {
    if (value is bool) {
      return value;
    }
    if (value is num) {
      return value != 0;
    }
    if (value is String) {
      final normalized = value.trim().toLowerCase();
      if (normalized == 'true' || normalized == '1' || normalized == 'yes') {
        return true;
      }
      if (normalized == 'false' || normalized == '0' || normalized == 'no') {
        return false;
      }
    }
    return fallback;
  }

  static String? _stringOrNull(dynamic value) {
    if (value == null) return null;
    if (value is String) {
      final trimmed = value.trim();
      return trimmed.isEmpty ? null : trimmed;
    }
    return value.toString().trim().isEmpty ? null : value.toString().trim();
  }

  static String _stringOrEmpty(dynamic value, {String fallback = ''}) {
    final parsed = _stringOrNull(value);
    return parsed ?? fallback;
  }

  static List<String> _stringList(dynamic value) {
    if (value is! List) {
      return const <String>[];
    }
    return value
        .map((item) => _stringOrNull(item))
        .whereType<String>()
        .toSet()
        .toList(growable: false);
  }

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
      UserModel.fromJson((doc.data() as Map<String, dynamic>?) ?? const <String, dynamic>{});
}
