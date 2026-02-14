// import 'package:freezed_annotation/freezed_annotation.dart';
import 'questionnaire_answers.dart';
import 'dart:math' as dart_math;

// part 'matching_profile.freezed.dart';
// part 'matching_profile.g.dart';

/// Extended user profile specifically for matching purposes
// @freezed
class MatchingProfile {
  const MatchingProfile({
    required this.userId,
    required this.displayName,
    this.photoUrl,
    required this.age,
    required this.latitude,
    required this.longitude,
    required this.answers,
    required this.lastActive,
    required this.createdAt,
    this.isActive = true,
    this.blockedUserIds = const [],
    this.likedUserIds = const [],
    this.passedUserIds = const [],
  });

  final String userId;
  final String displayName;
  final String? photoUrl;
  final int age;
  final double latitude;
  final double longitude;
  final QuestionnaireAnswers answers;
  final DateTime lastActive;
  final DateTime createdAt;
  final bool isActive;
  final List<String> blockedUserIds;
  final List<String> likedUserIds;
  final List<String> passedUserIds;

  factory MatchingProfile.fromJson(Map<String, dynamic> json) {
    return MatchingProfile(
      userId: json['userId'] as String,
      displayName: json['displayName'] as String,
      photoUrl: json['photoUrl'] as String?,
      age: json['age'] as int,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      answers: QuestionnaireAnswers.fromJson(json['answers'] as Map<String, dynamic>),
      lastActive: DateTime.parse(json['lastActive'] as String),
      createdAt: DateTime.parse(json['createdAt'] as String),
      isActive: json['isActive'] as bool? ?? true,
      blockedUserIds: List<String>.from(json['blockedUserIds'] ?? []),
      likedUserIds: List<String>.from(json['likedUserIds'] ?? []),
      passedUserIds: List<String>.from(json['passedUserIds'] ?? []),
    );
  }

  /// Check if profile is complete and ready for matching
  bool get isReadyForMatching {
    return isActive && answers.isComplete;
  }

  /// Calculate distance to another user in miles
  double distanceTo(MatchingProfile other) {
    return _calculateDistance(
      latitude,
      longitude,
      other.latitude,
      other.longitude,
    );
  }

  /// Check if user is within acceptable age range
  bool isWithinAgeRange(MatchingProfile other) {
    return other.age >= answers.minAge && other.age <= answers.maxAge;
  }

  /// Check if other user meets distance preference
  bool meetsDistancePreference(MatchingProfile other) {
    final distance = distanceTo(other);
    return distance <= _getMaxDistanceFromPreference(answers.distancePreference);
  }

  /// Check if user has been blocked
  bool hasBlocked(String userId) => blockedUserIds.contains(userId);

  /// Check if user has been liked
  bool hasLiked(String userId) => likedUserIds.contains(userId);

  /// Check if user has been passed
  bool hasPassed(String userId) => passedUserIds.contains(userId);

  /// Calculate distance between two coordinates using Haversine formula
  static double _calculateDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const double earthRadiusMiles = 3958.8;
    final double dLat = _toRadians(lat2 - lat1);
    final double dLon = _toRadians(lon2 - lon1);

    final double a = dart_math.sin(dLat / 2) * dart_math.sin(dLat / 2) +
        dart_math.cos(_toRadians(lat1)) *
            dart_math.cos(_toRadians(lat2)) *
            dart_math.sin(dLon / 2) *
            dart_math.sin(dLon / 2);

    final double c = 2 * dart_math.atan2(dart_math.sqrt(a), dart_math.sqrt(1 - a));
    return earthRadiusMiles * c;
  }

  static double _toRadians(double degrees) => degrees * Math.pi / 180;

  static double _getMaxDistanceFromPreference(DistancePreference pref) {
    switch (pref) {
      case DistancePreference.within5Miles:
        return 5.0;
      case DistancePreference.within10Miles:
        return 10.0;
      case DistancePreference.within25Miles:
        return 25.0;
      case DistancePreference.within50Miles:
        return 50.0;
      case DistancePreference.anywhere:
        return double.infinity;
    }
  }
}

/// Helper class for Math functions
class Math {
  static double sin(double x) => dart_math.sin(x);
  static double cos(double x) => dart_math.cos(x);
  static double sqrt(double x) => dart_math.sqrt(x);
  static double atan2(double y, double x) => dart_math.atan2(y, x);
  static const double pi = dart_math.pi;
}
