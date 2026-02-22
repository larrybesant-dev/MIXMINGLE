// lib/core/stubs/matching_stubs.dart
// Temporary stubs used by tests to unblock compilation.
// Replace with real implementations from the app when available.

import 'package:flutter/foundation.dart';

/// Simple preference marker classes used in tests.
class CannabisPreference {
  final bool uses;
  const CannabisPreference({this.uses = false});
  static const CannabisPreference never = CannabisPreference(uses: false);
}

class PetsPreference {
  final bool hasPets;
  const PetsPreference({this.hasPets = false});
  static const PetsPreference loveBoth = PetsPreference(hasPets: true);
}

class KidsPreference {
  final bool hasKids;
  const KidsPreference({this.hasKids = false});
  static const KidsPreference wantKids = KidsPreference(hasKids: true);
}

enum SmokingPreference { never, occasionally, regularly }
enum DrinkingPreference { never, occasionally, socially, regularly }

/// Minimal enums for relationship intent and preferred gender.
/// Added explicit values that tests may reference (e.g., seriousRelationship).
enum RelationshipIntent {
  casual,
  serious,
  undecided,
  casualRelationship,
  seriousRelationship,
}

enum PreferredGender { any, male, female, nonBinary }

/// Additional enums referenced by tests
enum WeekendEnergy { energetic, balanced, homebody }

enum SocialStyle { extrovert, ambivert, introvert }

enum CommunicationStyle { expressive, empathetic, logicalPractical }

/// Minimal questionnaire answers holder used by tests.
class QuestionnaireAnswers {
  final Map<String, dynamic> answers;
  const QuestionnaireAnswers([Map<String, dynamic>? a]) : answers = a ?? <String, dynamic>{};
}

/// Minimal matching profile used by tests.
/// Accepts all named parameters and enums used by tests; constructor is const to support const contexts.
class MatchingProfile {
  /// Use flexible types because tests sometimes pass ints, timestamps, or strings.
  final String id;
  final dynamic latitude;
  final dynamic longitude;
  final dynamic lastActive;
  final dynamic createdAt;
  final dynamic userId;
  final dynamic displayName;
  final dynamic age;
  final dynamic relationshipIntent;
  final WeekendEnergy? weekendEnergy;
  final SocialStyle? socialStyle;
  final CommunicationStyle? communicationStyle;
  final QuestionnaireAnswers answers;

  /// Constructor is const and tolerant: `id` has a stable default so tests that
  /// call `MatchingProfile()` without arguments compile.
  const MatchingProfile({
    this.id = 'stub-id',
    this.latitude,
    this.longitude,
    this.lastActive,
    this.createdAt,
    this.userId,
    this.displayName,
    this.age,
    this.relationshipIntent,
    this.weekendEnergy,
    this.socialStyle,
    this.communicationStyle,
    this.answers = const QuestionnaireAnswers(),
  });
}

/// Minimal PartnerVibe stub for tests
enum PartnerVibe {
  fun,
  serious,
  adventurous,
  chill,
  intellectual,
}

/// Minimal ConnectionStyle stub for tests
enum ConnectionStyle {
  introvert,
  extrovert,
  ambivert,
  deepConversations,
}

enum WeekendEnergy { low, medium, high, homebody, balancedMix }
enum MusicIdentity { pop, rock, jazz, classical, edm }
enum SocialStyle { outgoing, reserved, balanced, ambivert, introvert }
enum PersonalityTrait { thoughtful, spontaneous, analytical, creative }
enum CommunicationStyle { direct, indirect, expressive, reserved, directHonest, logicalPractical }
enum LoveLanguage { words, acts, gifts, time, touch, qualityTime }
enum AttractionTrigger { humor, intellect, kindness, ambition, intelligence }

/// Minimal stubs for additional relationship features
enum Dealbreaker { none, smoking, drinking, drugs, pets, dishonesty }
enum FlirtingStyle { subtle, bold, playful, awkward, intellectualBanter }

/// Minimal MatchScore function used by tests.
double MatchScore(MatchingProfile a, MatchingProfile b) {
  // Deterministic but trivial score for tests.
  // Use id hash and some fields to produce a stable value.
  final base = (a.id.hashCode ^ b.id.hashCode).abs();
  final ageFactor = ((a.age ?? 0) + (b.age ?? 0)).toDouble();
  return ((base % 100) + ageFactor) / 200.0;
}

/// Helper methods used by tests. Kept simple and deterministic.
extension MatchingProfileTestHelpers on MatchingProfile {
  /// Returns a trivial distance between two profiles.
  /// Tests only need a numeric value; this uses lat/lon if present, otherwise 0.
  double distanceTo(MatchingProfile other) {
    try {
      final lat1 = (latitude is num) ? latitude.toDouble() : 0.0;
      final lon1 = (longitude is num) ? longitude.toDouble() : 0.0;
      final lat2 = (other.latitude is num) ? other.latitude.toDouble() : 0.0;
      final lon2 = (other.longitude is num) ? other.longitude.toDouble() : 0.0;
      // Very small deterministic "distance" metric for tests.
      final dx = (lat1 - lat2).abs();
      final dy = (lon1 - lon2).abs();
      return (dx + dy);
    } catch (_) {
      return 0.0;
    }
  }

  /// Returns true if this profile's age is within [minAge,maxAge].
  bool isWithinAgeRange({dynamic minAge, dynamic maxAge}) {
    final a = (age is num) ? age as num : int.tryParse('$age') ?? 0;
    final min = (minAge is num) ? minAge as num : int.tryParse('$minAge') ?? 0;
    final max = (maxAge is num) ? maxAge as num : int.tryParse('$maxAge') ?? 999;
    return a >= min && a <= max;
  }

  /// Simple distance preference check. Accepts numeric or map-like preference.
  bool meetsDistancePreference(dynamic distancePreference, {double Function(double)? distanceProvider}) {
    final pref = distancePreference;
    final dist = distanceProvider != null ? distanceProvider(distanceTo(this)) : distanceTo(this);
    if (pref == null) return true;
    if (pref is num) return dist <= pref.toDouble();
    if (pref is String) {
      final n = double.tryParse(pref);
      return n == null ? true : dist <= n;
    }
    if (pref is Map) {
      final max = pref['max'] ?? pref['distance'] ?? pref['radius'];
      if (max is num) return dist <= max.toDouble();
    }
    return true;
  }
}

class DistancePreference {
  final double maxDistanceKm;
  const DistancePreference({this.maxDistanceKm = 50});
  static const DistancePreference defaultPreference = DistancePreference();
  static const DistancePreference within10Miles = DistancePreference(maxDistanceKm: 16.0934); // 10 miles in km
}
