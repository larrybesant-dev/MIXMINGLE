// import 'package:freezed_annotation/freezed_annotation.dart';

// part 'match_score.freezed.dart';
// part 'match_score.g.dart';

/// Detailed breakdown of compatibility score between two users
// @freezed
class MatchScore {
  const MatchScore({
    required this.userId,
    required this.matchedUserId,
    required this.overallScore,
    required this.categoryScores,
    required this.sharedInterests,
    required this.compatibilityReasons,
    required this.potentialChallenges,
    required this.calculatedAt,
  });

  final String userId;
  final String matchedUserId;
  final double overallScore;
  final Map<String, double> categoryScores;
  final List<String> sharedInterests;
  final List<String> compatibilityReasons;
  final List<String> potentialChallenges;
  final DateTime calculatedAt;

  factory MatchScore.fromJson(Map<String, dynamic> json) {
    return MatchScore(
      userId: json['userId'] as String,
      matchedUserId: json['matchedUserId'] as String,
      overallScore: (json['overallScore'] as num).toDouble(),
      categoryScores: Map<String, double>.from(json['categoryScores'] as Map),
      sharedInterests: List<String>.from(json['sharedInterests'] as List),
      compatibilityReasons:
          List<String>.from(json['compatibilityReasons'] as List),
      potentialChallenges:
          List<String>.from(json['potentialChallenges'] as List),
      calculatedAt: DateTime.parse(json['calculatedAt'] as String),
    );
  }

  /// Get compatibility level as a string
  String get compatibilityLevel {
    if (overallScore >= 90) return 'Exceptional Match';
    if (overallScore >= 80) return 'Great Match';
    if (overallScore >= 70) return 'Good Match';
    if (overallScore >= 60) return 'Decent Match';
    if (overallScore >= 50) return 'Fair Match';
    return 'Low Compatibility';
  }

  /// Get color for UI display
  String get compatibilityColor {
    if (overallScore >= 80) return '#00FF00'; // Green
    if (overallScore >= 60) return '#FFD700'; // Gold
    if (overallScore >= 40) return '#FFA500'; // Orange
    return '#FF4C4C'; // Red
  }

  /// Check if this is a strong match (above threshold)
  bool get isStrongMatch => overallScore >= 70;

  /// Get top 3 compatibility reasons
  List<String> get topReasons => compatibilityReasons.take(3).toList();

  /// Get score for a specific category
  double getCategoryScore(String category) {
    return categoryScores[category] ?? 0.0;
  }
}

/// Ranked match result for display in UI
// @freezed
class RankedMatch {
  const RankedMatch({
    required this.userId,
    required this.userName,
    required this.userPhotoUrl,
    required this.age,
    required this.distanceInMiles,
    required this.matchScore,
    required this.rank,
  });

  final String userId;
  final String userName;
  final String? userPhotoUrl;
  final int age;
  final double distanceInMiles;
  final MatchScore matchScore;
  final int rank;

  factory RankedMatch.fromJson(Map<String, dynamic> json) {
    return RankedMatch(
      userId: json['userId'] as String,
      userName: json['userName'] as String,
      userPhotoUrl: json['userPhotoUrl'] as String?,
      age: json['age'] as int,
      distanceInMiles: (json['distanceInMiles'] as num).toDouble(),
      matchScore:
          MatchScore.fromJson(json['matchScore'] as Map<String, dynamic>),
      rank: json['rank'] as int,
    );
  }
}

/// Match statistics for analytics
// @freezed
class MatchStatistics {
  const MatchStatistics({
    required this.totalMatches,
    required this.strongMatches,
    required this.averageScore,
    required this.highestScore,
    required this.lowestScore,
    required this.compatibilityDistribution,
    required this.calculatedAt,
  });

  final int totalMatches;
  final int strongMatches;
  final double averageScore;
  final double highestScore;
  final double lowestScore;
  final Map<String, int> compatibilityDistribution;
  final DateTime calculatedAt;

  factory MatchStatistics.fromJson(Map<String, dynamic> json) {
    return MatchStatistics(
      totalMatches: json['totalMatches'] as int,
      strongMatches: json['strongMatches'] as int,
      averageScore: (json['averageScore'] as num).toDouble(),
      highestScore: (json['highestScore'] as num).toDouble(),
      lowestScore: (json['lowestScore'] as num).toDouble(),
      compatibilityDistribution:
          Map<String, int>.from(json['compatibilityDistribution'] as Map),
      calculatedAt: DateTime.parse(json['calculatedAt'] as String),
    );
  }
}
