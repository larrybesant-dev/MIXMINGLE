import 'package:cloud_firestore/cloud_firestore.dart';

  class UserProfile {
    final String uid;
    final String? displayName;
    final String? nickname;
    final String? bio;
    final String? photoUrl;
    final String? coverPhotoUrl;
    final String? presenceStatus;
    final bool? ageVerified;
    final bool? onboardingComplete;
    final int? birthYear;
    final List<String>? lookingFor;
    final String? relationshipType;
    final List<String>? preferredGenders;
    final int? minAgePreference;
    final int? maxAgePreference;
    final List<String>? galleryPhotos;
    final List<String>? galleryVideos;
    final List<String>? lifestylePrompts;
    final Map<String, int>? vibeHistory;
    final int? followersCount;
    final int? followingCount;
    final int? roomsHostedCount;
    final String? vibeTag;
    final List<String>? interests;
    final List<String>? musicGenres;
    final List<String>? musicTastes;
    final Map<String, String>? socialLinks;
    final bool? isPremium;
    final bool? isVip;
    final bool? isCreatorBadge;
    final bool? isCreatorEnabled;
    final bool? isPhotoVerified;
    final String? countryCode;
    final bool? isIdVerified;
    final bool? isBoosted;
    final double? communityRating;
    final int? totalRoomsJoined;
    final bool? twoFactorEnabled;
    final List<String>? badgeIds;
    final List<String>? computedTags;
    final double? energyScore;
    final int? eventsAttended;
    final int? mutualsCount;
    final String? location;
    final Timestamp? createdAt;
    final Timestamp? updatedAt;

    UserProfile({
      required this.uid,
      this.displayName,
      this.nickname,
      this.bio,
      this.photoUrl,
      this.coverPhotoUrl,
      this.presenceStatus,
      this.ageVerified,
      this.onboardingComplete,
      this.birthYear,
      this.lookingFor,
      this.relationshipType,
      this.preferredGenders,
      this.minAgePreference,
      this.maxAgePreference,
      this.galleryPhotos,
      this.galleryVideos,
      this.lifestylePrompts,
      this.vibeHistory,
      this.followersCount,
      this.followingCount,
      this.roomsHostedCount,
      this.vibeTag,
      this.interests,
      this.musicGenres,
      this.musicTastes,
      this.socialLinks,
      this.isPremium,
      this.isVip,
      this.isCreatorBadge,
      this.isCreatorEnabled,
      this.isPhotoVerified,
      this.countryCode,
      this.isIdVerified,
      this.isBoosted,
      this.communityRating,
      this.totalRoomsJoined,
      this.twoFactorEnabled,
      this.badgeIds,
      this.computedTags,
      this.energyScore,
      this.eventsAttended,
      this.mutualsCount,
      this.location,
      this.createdAt,
      this.updatedAt,
    });

    factory UserProfile.fromMap(Map<String, dynamic>? data, String uid) {
            Map<String, int>? _mapStringIntFrom(dynamic raw) {
              if (raw == null) return null;
              if (raw is Map) {
                return raw.map((k, v) => MapEntry(k.toString(), v is int ? v : (v is num ? v.toInt() : 0)));
              }
              return null;
            }
      if (data == null) {
        return UserProfile(uid: uid);
      }

      List<String>? _listFrom(dynamic raw) {
        if (raw == null) return null;
        if (raw is List) return raw.map((e) => e.toString()).toList();
        return null;
      }
      Map<String, String>? _mapStringStringFrom(dynamic raw) {
        if (raw == null) return null;
        if (raw is Map) {
          return raw.map((k, v) => MapEntry(k.toString(), v?.toString() ?? ''));
        }
        return null;
      }
      int? _intFrom(dynamic raw) {
        if (raw == null) return null;
        if (raw is int) return raw;
        if (raw is num) return raw.toInt();
        return null;
      }
      double? _doubleFrom(dynamic raw) {
        if (raw == null) return null;
        if (raw is double) return raw;
        if (raw is num) return raw.toDouble();
        return null;
      }
      Timestamp? _ts(dynamic raw) {
        if (raw is Timestamp) return raw;
        return null;
      }

      return UserProfile(
        uid: uid,
        displayName: data['displayName'] as String?,
        nickname: data['nickname'] as String?,
        bio: data['bio'] as String?,
        photoUrl: data['photoUrl'] as String?,
        coverPhotoUrl: data['coverPhotoUrl'] as String?,
        presenceStatus: data['presenceStatus'] as String?,
        ageVerified: data['ageVerified'] as bool?,
        onboardingComplete: data['onboardingComplete'] as bool?,
        birthYear: _intFrom(data['birthYear']),
        lookingFor: _listFrom(data['lookingFor']),
        relationshipType: data['relationshipType'] as String?,
        preferredGenders: _listFrom(data['preferredGenders']),
        minAgePreference: _intFrom(data['minAgePreference']),
        maxAgePreference: _intFrom(data['maxAgePreference']),
        galleryPhotos: _listFrom(data['galleryPhotos']),
        galleryVideos: _listFrom(data['galleryVideos']),
        lifestylePrompts: _listFrom(data['lifestylePrompts']),
        vibeHistory: _mapStringIntFrom(data['vibeHistory']),
        followersCount: _intFrom(data['followersCount']),
        followingCount: _intFrom(data['followingCount']),
        roomsHostedCount: _intFrom(data['roomsHostedCount']),
        vibeTag: data['vibeTag'] as String?,
        interests: _listFrom(data['interests']),
        musicGenres: _listFrom(data['musicGenres']),
        musicTastes: _listFrom(data['musicTastes']),
        socialLinks: _mapStringStringFrom(data['socialLinks']),
        isPremium: data['isPremium'] as bool?,
        isVip: data['isVip'] as bool?,
        isCreatorBadge: data['isCreatorBadge'] as bool?,
        isCreatorEnabled: data['isCreatorEnabled'] as bool?,
        isPhotoVerified: data['isPhotoVerified'] as bool?,
        countryCode: data['countryCode'] as String?,
        isIdVerified: data['isIdVerified'] as bool?,
        isBoosted: data['isBoosted'] as bool?,
        communityRating: _doubleFrom(data['communityRating']),
        totalRoomsJoined: _intFrom(data['totalRoomsJoined']),
        twoFactorEnabled: data['twoFactorEnabled'] as bool?,
        badgeIds: _listFrom(data['badgeIds']),
        computedTags: _listFrom(data['computedTags']),
        energyScore: _doubleFrom(data['energyScore']),
        eventsAttended: _intFrom(data['eventsAttended']),
        mutualsCount: _intFrom(data['mutualsCount']),
        location: data['location'] as String?,
        createdAt: _ts(data['createdAt']),
        updatedAt: _ts(data['updatedAt']),
      );
    }

    Map<String, dynamic> toMap({bool includeTimestamps = true}) {
      final map = <String, dynamic>{
        'displayName': displayName,
        'nickname': nickname,
        'bio': bio,
        'photoUrl': photoUrl,
        'coverPhotoUrl': coverPhotoUrl,
        'presenceStatus': presenceStatus,
        'ageVerified': ageVerified,
        'onboardingComplete': onboardingComplete,
        'birthYear': birthYear,
        'lookingFor': lookingFor,
        'relationshipType': relationshipType,
        'preferredGenders': preferredGenders,
        'minAgePreference': minAgePreference,
        'maxAgePreference': maxAgePreference,
        'galleryPhotos': galleryPhotos,
        'galleryVideos': galleryVideos,
        'lifestylePrompts': lifestylePrompts,
        'followersCount': followersCount,
        'followingCount': followingCount,
        'roomsHostedCount': roomsHostedCount,
        'vibeTag': vibeTag,
        'interests': interests,
        'musicGenres': musicGenres,
        'musicTastes': musicTastes,
        'socialLinks': socialLinks,
        'isPremium': isPremium,
        'isVip': isVip,
        'isCreatorBadge': isCreatorBadge,
        'isCreatorEnabled': isCreatorEnabled,
        'isPhotoVerified': isPhotoVerified,
        'countryCode': countryCode,
        'isIdVerified': isIdVerified,
        'isBoosted': isBoosted,
        'communityRating': communityRating,
        'totalRoomsJoined': totalRoomsJoined,
        'twoFactorEnabled': twoFactorEnabled,
        'badgeIds': badgeIds,
        'computedTags': computedTags,
        'energyScore': energyScore,
        'eventsAttended': eventsAttended,
        'mutualsCount': mutualsCount,
        'location': location,
      };

      if (includeTimestamps) {
        map['createdAt'] = createdAt ?? FieldValue.serverTimestamp();
        map['updatedAt'] = FieldValue.serverTimestamp();
      } else {
        if (createdAt != null) map['createdAt'] = createdAt;
        if (updatedAt != null) map['updatedAt'] = updatedAt;
      }

      return map;
    }
  // --- Computed property getters for business logic compatibility ---

  /// Returns the user's vibe history or an empty list if null.
  /// Returns the user's vibe history as a map or an empty map if null.
  Map<String, int> get vibeHistoryOrEmpty => vibeHistory ?? <String, int>{};

  /// Returns the user's top vibe or an empty string if null.
  String get topVibeOrEmpty => vibeTag ?? '';

  /// Returns the count of the user's top vibe or zero if not available.
  int get topVibeCountOrZero => vibeTag != null && vibeTag!.isNotEmpty ? 1 : 0;

  /// Returns the number of rooms hosted or zero if null.
  int get roomsHostedCountOrZero => roomsHostedCount ?? 0;

  /// Returns the total number of rooms joined or zero if null.
  int get totalRoomsJoinedOrZero => totalRoomsJoined ?? 0;

  /// Returns the number of events attended or zero if null.
  int get eventsAttendedOrZero => eventsAttended ?? 0;

  /// Returns the user's community rating or zero if null.
  double get communityRatingOrZero => communityRating ?? 0.0;

  /// Returns the user's followers count or zero if null.
  int get followersCountOrZero => followersCount ?? 0;

  /// Returns the user's energy score or zero if null.
  double get energyScoreOrZero => energyScore ?? 0.0;
}
