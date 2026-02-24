
import 'package:cloud_firestore/cloud_firestore.dart';

/// The active mode displayed at top of profile.
enum ProfileMode { social, dating, creator, eventHost }

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

  // ── Profile Mode (Layer Router) ─────────────────────────────
  final ProfileMode profileMode;

  // ── Layer 1 extras: Attraction ──────────────────────────────
  final bool isPremium;
  final bool isCreatorBadge;

  // ── Layer 2: Live Presence ──────────────────────────────────
  final int roomsHostedCount;
  final double avgRoomRating;
  final String? topCategory;
  final int eventsHostingCount;
  final String? activeRoomId;

  // ── Layer 3: Social Proof ───────────────────────────────────
  final int mutualsCount;
  final int eventsAttended;
  final double communityRating;
  final int totalRoomsJoined;

  // ── Layer 4: Creator Monetization (18+) ─────────────────────
  final bool isCreatorEnabled;
  final bool is18PlusVerified;       // age-verified gate, required for adult content
  final bool isAdultContentEnabled;  // explicit content flag, 18+ only
  final double? subscriptionPrice;   // monthly USD
  final int subscriberCount;
  final String? creatorHeadline;
  final bool hasPaidRooms;
  final bool hasContentVault;
  final double totalEarnings;        // private – only shown to owner

  // ── Layer 5: Safety / Control ────────────────────────────────
  final String dmRestriction;        // 'everyone' | 'followers' | 'nobody'
  final bool hideDistance;
  final bool hideFollowers;
  final bool restrictRoomInvites;
  final bool twoFactorEnabled;

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
    // new fields
    this.profileMode = ProfileMode.social,
    this.isPremium = false,
    this.isCreatorBadge = false,
    this.roomsHostedCount = 0,
    this.avgRoomRating = 0.0,
    this.topCategory,
    this.eventsHostingCount = 0,
    this.activeRoomId,
    this.mutualsCount = 0,
    this.eventsAttended = 0,
    this.communityRating = 0.0,
    this.totalRoomsJoined = 0,
    this.isCreatorEnabled = false,
    this.is18PlusVerified = false,
    this.isAdultContentEnabled = false,
    this.subscriptionPrice,
    this.subscriberCount = 0,
    this.creatorHeadline,
    this.hasPaidRooms = false,
    this.hasContentVault = false,
    this.totalEarnings = 0.0,
    this.dmRestriction = 'everyone',
    this.hideDistance = false,
    this.hideFollowers = false,
    this.restrictRoomInvites = false,
    this.twoFactorEnabled = false,
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
    ProfileMode parseMode(String? v) {
      switch (v) {
        case 'dating': return ProfileMode.dating;
        case 'creator': return ProfileMode.creator;
        case 'eventHost': return ProfileMode.eventHost;
        default: return ProfileMode.social;
      }
    }

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
      // new fields
      profileMode: parseMode(map['profileMode'] as String?),
      isPremium: map['isPremium'] as bool? ?? false,
      isCreatorBadge: map['isCreatorBadge'] as bool? ?? false,
      roomsHostedCount: map['roomsHostedCount'] as int? ?? 0,
      avgRoomRating: (map['avgRoomRating'] as num?)?.toDouble() ?? 0.0,
      topCategory: map['topCategory'] as String?,
      eventsHostingCount: map['eventsHostingCount'] as int? ?? 0,
      activeRoomId: map['activeRoomId'] as String?,
      mutualsCount: map['mutualsCount'] as int? ?? 0,
      eventsAttended: map['eventsAttended'] as int? ?? 0,
      communityRating: (map['communityRating'] as num?)?.toDouble() ?? 0.0,
      totalRoomsJoined: map['totalRoomsJoined'] as int? ?? 0,
      isCreatorEnabled: map['isCreatorEnabled'] as bool? ?? false,
      is18PlusVerified: map['is18PlusVerified'] as bool? ?? false,
      isAdultContentEnabled: map['isAdultContentEnabled'] as bool? ?? false,
      subscriptionPrice: (map['subscriptionPrice'] as num?)?.toDouble(),
      subscriberCount: map['subscriberCount'] as int? ?? 0,
      creatorHeadline: map['creatorHeadline'] as String?,
      hasPaidRooms: map['hasPaidRooms'] as bool? ?? false,
      hasContentVault: map['hasContentVault'] as bool? ?? false,
      totalEarnings: (map['totalEarnings'] as num?)?.toDouble() ?? 0.0,
      dmRestriction: map['dmRestriction'] as String? ?? 'everyone',
      hideDistance: map['hideDistance'] as bool? ?? false,
      hideFollowers: map['hideFollowers'] as bool? ?? false,
      restrictRoomInvites: map['restrictRoomInvites'] as bool? ?? false,
      twoFactorEnabled: map['twoFactorEnabled'] as bool? ?? false,
    );
  }

  // ── Public profile: safe to expose to any authenticated user ──
  Map<String, dynamic> toPublicMap() {
    return {
      'id': id,
      'displayName': displayName,
      'nickname': nickname,
      'photoUrl': photoUrl,
      'coverPhotoUrl': coverPhotoUrl,
      'galleryPhotos': galleryPhotos,
      'interests': interests,
      'location': location,           // city-level only, no lat/lng
      'gender': gender,
      'pronouns': pronouns,
      'bio': bio,
      'socialLinks': socialLinks,
      'followersCount': followersCount,
      'followingCount': followingCount,
      'presenceStatus': presenceStatus,
      'profileMode': profileMode.name,
      'isPremium': isPremium,
      'isCreatorBadge': isCreatorBadge,
      'isCreatorEnabled': isCreatorEnabled,
      'creatorHeadline': creatorHeadline,
      'subscriberCount': subscriberCount,
      'hasPaidRooms': hasPaidRooms,
      'hasContentVault': hasContentVault,
      'roomsHostedCount': roomsHostedCount,
      'avgRoomRating': avgRoomRating,
      'topCategory': topCategory,
      'eventsHostingCount': eventsHostingCount,
      'activeRoomId': activeRoomId,
      'mutualsCount': mutualsCount,
      'eventsAttended': eventsAttended,
      'communityRating': communityRating,
      'totalRoomsJoined': totalRoomsJoined,
      'isPhotoVerified': isPhotoVerified,
      'isPhoneVerified': isPhoneVerified,
      'isEmailVerified': isEmailVerified,
      'isIdVerified': isIdVerified,
      'is18PlusVerified': is18PlusVerified,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  // ── Private profile: owner-only sensitive data ──
  Map<String, dynamic> toPrivateMap() {
    return {
      'userId': id,
      'email': email,
      'isAdultContentEnabled': isAdultContentEnabled,
      'subscriptionPrice': subscriptionPrice,
      'totalEarnings': totalEarnings,
      'dmRestriction': dmRestriction,
      'hideDistance': hideDistance,
      'hideFollowers': hideFollowers,
      'restrictRoomInvites': restrictRoomInvites,
      'twoFactorEnabled': twoFactorEnabled,
      'verifiedOnlyMode': verifiedOnlyMode,
      'privateMode': privateMode,
      'latitude': latitude,
      'longitude': longitude,
      // Dating preferences — private
      'lookingFor': lookingFor,
      'relationshipType': relationshipType,
      'minAgePreference': minAgePreference,
      'maxAgePreference': maxAgePreference,
      'preferredGenders': preferredGenders,
      'birthday': birthday != null ? Timestamp.fromDate(birthday!) : null,
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
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
      // new fields
      'profileMode': profileMode.name,
      'isPremium': isPremium,
      'isCreatorBadge': isCreatorBadge,
      'roomsHostedCount': roomsHostedCount,
      'avgRoomRating': avgRoomRating,
      'topCategory': topCategory,
      'eventsHostingCount': eventsHostingCount,
      'activeRoomId': activeRoomId,
      'mutualsCount': mutualsCount,
      'eventsAttended': eventsAttended,
      'communityRating': communityRating,
      'totalRoomsJoined': totalRoomsJoined,
      'isCreatorEnabled': isCreatorEnabled,
      'is18PlusVerified': is18PlusVerified,
      'isAdultContentEnabled': isAdultContentEnabled,
      'subscriptionPrice': subscriptionPrice,
      'subscriberCount': subscriberCount,
      'creatorHeadline': creatorHeadline,
      'hasPaidRooms': hasPaidRooms,
      'hasContentVault': hasContentVault,
      // NOTE: totalEarnings is never exposed in public profile reads
      'dmRestriction': dmRestriction,
      'hideDistance': hideDistance,
      'hideFollowers': hideFollowers,
      'restrictRoomInvites': restrictRoomInvites,
      'twoFactorEnabled': twoFactorEnabled,
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
    ProfileMode? profileMode,
    bool? isPremium,
    bool? isCreatorBadge,
    int? roomsHostedCount,
    double? avgRoomRating,
    String? topCategory,
    int? eventsHostingCount,
    String? activeRoomId,
    int? mutualsCount,
    int? eventsAttended,
    double? communityRating,
    int? totalRoomsJoined,
    bool? isCreatorEnabled,
    bool? is18PlusVerified,
    bool? isAdultContentEnabled,
    double? subscriptionPrice,
    int? subscriberCount,
    String? creatorHeadline,
    bool? hasPaidRooms,
    bool? hasContentVault,
    double? totalEarnings,
    String? dmRestriction,
    bool? hideDistance,
    bool? hideFollowers,
    bool? restrictRoomInvites,
    bool? twoFactorEnabled,
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
      profileMode: profileMode ?? this.profileMode,
      isPremium: isPremium ?? this.isPremium,
      isCreatorBadge: isCreatorBadge ?? this.isCreatorBadge,
      roomsHostedCount: roomsHostedCount ?? this.roomsHostedCount,
      avgRoomRating: avgRoomRating ?? this.avgRoomRating,
      topCategory: topCategory ?? this.topCategory,
      eventsHostingCount: eventsHostingCount ?? this.eventsHostingCount,
      activeRoomId: activeRoomId ?? this.activeRoomId,
      mutualsCount: mutualsCount ?? this.mutualsCount,
      eventsAttended: eventsAttended ?? this.eventsAttended,
      communityRating: communityRating ?? this.communityRating,
      totalRoomsJoined: totalRoomsJoined ?? this.totalRoomsJoined,
      isCreatorEnabled: isCreatorEnabled ?? this.isCreatorEnabled,
      is18PlusVerified: is18PlusVerified ?? this.is18PlusVerified,
      isAdultContentEnabled: isAdultContentEnabled ?? this.isAdultContentEnabled,
      subscriptionPrice: subscriptionPrice ?? this.subscriptionPrice,
      subscriberCount: subscriberCount ?? this.subscriberCount,
      creatorHeadline: creatorHeadline ?? this.creatorHeadline,
      hasPaidRooms: hasPaidRooms ?? this.hasPaidRooms,
      hasContentVault: hasContentVault ?? this.hasContentVault,
      totalEarnings: totalEarnings ?? this.totalEarnings,
      dmRestriction: dmRestriction ?? this.dmRestriction,
      hideDistance: hideDistance ?? this.hideDistance,
      hideFollowers: hideFollowers ?? this.hideFollowers,
      restrictRoomInvites: restrictRoomInvites ?? this.restrictRoomInvites,
      twoFactorEnabled: twoFactorEnabled ?? this.twoFactorEnabled,
    );
  }
}

