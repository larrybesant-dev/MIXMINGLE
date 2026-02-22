
import 'package:cloud_firestore/cloud_firestore.dart';

class UserProfile {
  final String id;
  final String email;
  final String? displayName;
  final String? nickname;
  final String? photoUrl;
  final String? coverPhotoUrl;
  final List<String>? galleryPhotos;
  final List<String>? interests;
  final String? location;
  final double? latitude;
  final double? longitude;
  final DateTime? birthday;
  final String? gender;
  final String? pronouns;
  final String? bio;
  final List<String>? lookingFor; // friends, dating, networking, activity partners
  final String? relationshipType; // casual, serious, long-term
  final int? minAgePreference;
  final int? maxAgePreference;
  final List<String>? preferredGenders;
  final Map<String, String>? personalityPrompts; // "My ideal day...", "A green flag..."
  final List<String>? musicTastes;
  final Map<String, bool>? lifestylePrompts; // smoking, drinking, fitness, pets, kids
  final bool? isPhotoVerified;
  final bool? isPhoneVerified;
  final bool? isEmailVerified;
  final bool? isIdVerified;
  final Map<String, String>? socialLinks; // Instagram, TikTok, Snapchat, X/Twitter
  final bool? verifiedOnlyMode;
  final bool? privateMode;
  final int followersCount;
  final int followingCount;
  final String? presenceStatus; // online, offline, in_room, in_event
  final DateTime createdAt;
  final DateTime updatedAt;

  UserProfile({
    required this.id,
    required this.email,
    this.displayName,
    this.nickname,
    this.photoUrl,
    this.coverPhotoUrl,
    this.galleryPhotos,
    this.interests,
    this.location,
    this.latitude,
    this.longitude,
    this.birthday,
    this.gender,
    this.pronouns,
    this.bio,
    this.lookingFor,
    this.relationshipType,
    this.minAgePreference,
    this.maxAgePreference,
    this.preferredGenders,
    this.personalityPrompts,
    this.musicTastes,
    this.lifestylePrompts,
    this.isPhotoVerified,
    this.isPhoneVerified,
    this.isEmailVerified,
    this.isIdVerified,
    this.socialLinks,
    this.verifiedOnlyMode,
    this.privateMode,
    this.followersCount = 0,
    this.followingCount = 0,
    this.presenceStatus,
    required this.createdAt,
    required this.updatedAt,
  });

  // Computed property for age
  int? get age {
    if (birthday == null) return null;
    final now = DateTime.now();
    final birthYear = birthday!.year;
    final birthMonth = birthday!.month;
    final birthDay = birthday!.day;
    int age = now.year - birthYear;
    if (now.month < birthMonth || (now.month == birthMonth && now.day < birthDay)) {
      age--;
    }
    return age;
  }

  // Convenience getters for backward compatibility
  List<String> get photos => galleryPhotos ?? [];
  String? get profileImageUrl => photoUrl;
  String? get username => displayName ?? nickname;
  bool get isOnline => false; // Default to false, override with presence data

  factory UserProfile.fromMap(Map<String, dynamic> map) {
    return UserProfile(
      id: map['id'] as String,
      email: map['email'] as String,
      displayName: map['displayName'] as String?,
      nickname: map['nickname'] as String?,
      photoUrl: map['photoUrl'] as String?,
      coverPhotoUrl: map['coverPhotoUrl'] as String?,
      galleryPhotos: (map['galleryPhotos'] as List<dynamic>?)?.cast<String>(),
      interests: (map['interests'] as List<dynamic>?)?.cast<String>(),
      location: map['location'] as String?,
      latitude: map['latitude'] as double?,
      longitude: map['longitude'] as double?,
      birthday: map['birthday'] != null ? (map['birthday'] as Timestamp).toDate() : null,
      gender: map['gender'] as String?,
      pronouns: map['pronouns'] as String?,
      bio: map['bio'] as String?,
      lookingFor: (map['lookingFor'] as List<dynamic>?)?.cast<String>(),
      relationshipType: map['relationshipType'] as String?,
      minAgePreference: map['minAgePreference'] as int?,
      maxAgePreference: map['maxAgePreference'] as int?,
      preferredGenders: (map['preferredGenders'] as List<dynamic>?)?.cast<String>(),
      personalityPrompts: (map['personalityPrompts'] as Map<String, dynamic>?)?.cast<String, String>(),
      musicTastes: (map['musicTastes'] as List<dynamic>?)?.cast<String>(),
      lifestylePrompts: (map['lifestylePrompts'] as Map<String, dynamic>?)?.cast<String, bool>(),
      isPhotoVerified: map['isPhotoVerified'] as bool?,
      isPhoneVerified: map['isPhoneVerified'] as bool?,
      isEmailVerified: map['isEmailVerified'] as bool?,
      isIdVerified: map['isIdVerified'] as bool?,
      socialLinks: (map['socialLinks'] as Map<String, dynamic>?)?.cast<String, String>(),
      verifiedOnlyMode: map['verifiedOnlyMode'] as bool?,
      privateMode: map['privateMode'] as bool?,
      followersCount: map['followersCount'] as int? ?? 0,
      followingCount: map['followingCount'] as int? ?? 0,
      presenceStatus: map['presenceStatus'] as String?,
      createdAt: map['createdAt'] is Timestamp
          ? (map['createdAt'] as Timestamp).toDate()
          : DateTime.parse(map['createdAt'] as String),
      updatedAt: map['updatedAt'] is Timestamp
          ? (map['updatedAt'] as Timestamp).toDate()
          : DateTime.parse(map['updatedAt'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'email': email,
      'displayName': displayName,
      'nickname': nickname,
      'photoUrl': photoUrl,
      'coverPhotoUrl': coverPhotoUrl,
      'galleryPhotos': galleryPhotos,
      'interests': interests,
      'location': location,
      'latitude': latitude,
      'longitude': longitude,
      'birthday': birthday != null ? Timestamp.fromDate(birthday!) : null,
      'gender': gender,
      'pronouns': pronouns,
      'bio': bio,
      'lookingFor': lookingFor,
      'relationshipType': relationshipType,
      'minAgePreference': minAgePreference,
      'maxAgePreference': maxAgePreference,
      'preferredGenders': preferredGenders,
      'personalityPrompts': personalityPrompts,
      'musicTastes': musicTastes,
      'lifestylePrompts': lifestylePrompts,
      'isPhotoVerified': isPhotoVerified,
      'isPhoneVerified': isPhoneVerified,
      'isEmailVerified': isEmailVerified,
      'isIdVerified': isIdVerified,
      'socialLinks': socialLinks,
      'verifiedOnlyMode': verifiedOnlyMode,
      'privateMode': privateMode,
      'followersCount': followersCount,
      'followingCount': followingCount,
      'presenceStatus': presenceStatus,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  UserProfile copyWith({
    String? displayName,
    String? nickname,
    String? photoUrl,
    String? coverPhotoUrl,
    List<String>? galleryPhotos,
    List<String>? interests,
    String? location,
    double? latitude,
    double? longitude,
    DateTime? birthday,
    String? gender,
    String? bio,
    DateTime? updatedAt,
  }) {
    return UserProfile(
      id: id,
      email: email,
      displayName: displayName ?? this.displayName,
      nickname: nickname ?? this.nickname,
      photoUrl: photoUrl ?? this.photoUrl,
      coverPhotoUrl: coverPhotoUrl ?? this.coverPhotoUrl,
      galleryPhotos: galleryPhotos ?? this.galleryPhotos,
      interests: interests ?? this.interests,
      location: location ?? this.location,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      birthday: birthday ?? this.birthday,
      gender: gender ?? this.gender,
      bio: bio ?? this.bio,
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }
}


