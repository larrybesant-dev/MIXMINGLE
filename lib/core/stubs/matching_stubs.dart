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
  final String id;
  final double? latitude;
  final double? longitude;
  final DateTime? lastActive;
  final DateTime? createdAt;
  final String? userId;
  final String? displayName;
  final int? age;
  final RelationshipIntent? relationshipIntent;
  final WeekendEnergy? weekendEnergy;
  final SocialStyle? socialStyle;
  final CommunicationStyle? communicationStyle;
  final QuestionnaireAnswers answers;

  bool get isReadyForMatching => true;
  bool meetsDistancePreference(DistancePreference pref) => true;

  const MatchingProfile({
    required this.id,
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

class DistancePreference {
  final double maxDistanceKm;
  const DistancePreference({this.maxDistanceKm = 50});
  static const DistancePreference defaultPreference = DistancePreference();
  static const DistancePreference within10Miles = DistancePreference(maxDistanceKm: 16.0934); // 10 miles in km
}
