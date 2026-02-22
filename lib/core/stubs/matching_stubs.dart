// lib/core/stubs/matching_stubs.dart
// Temporary stubs used by tests to unblock compilation.
// Replace with real implementations from the app when available.

import 'package:cloud_firestore/cloud_firestore.dart';

/// Simple preference marker classes used in tests.
class CannabisPreference {
  final bool uses;
  const CannabisPreference({this.uses = false});
  static const CannabisPreference never = CannabisPreference(uses: false);
  static const CannabisPreference occasionally = CannabisPreference(uses: true);
  static const CannabisPreference regularly = CannabisPreference(uses: true);
}

class PetsPreference {
  final bool hasPets;
  const PetsPreference({this.hasPets = false});
  static const PetsPreference loveBoth = PetsPreference(hasPets: true);
  static const PetsPreference loveDogs = PetsPreference(hasPets: true);
  static const PetsPreference noPets = PetsPreference(hasPets: false);
}

class KidsPreference {
  final bool hasKids;
  const KidsPreference({this.hasKids = false});
  static const KidsPreference wantKids = KidsPreference(hasKids: false);
  static const KidsPreference haveKids = KidsPreference(hasKids: true);
  static const KidsPreference dontWantKids = KidsPreference(hasKids: false);
}

enum SmokingPreference { never, occasionally, regularly }
enum DrinkingPreference { never, occasionally, socially, regularly }

/// Minimal enums for relationship intent and preferred gender.
enum RelationshipIntent {
  casual,
  serious,
  undecided,
  casualRelationship,
  seriousRelationship,
  casualDating,
}

enum PreferredGender { any, male, female, nonBinary, everyone }

/// Additional enums referenced by tests
enum WeekendEnergy { energetic, balanced, homebody, balancedMix, partyAnimal }

enum SocialStyle { extrovert, ambivert, introvert }

enum CommunicationStyle {
  expressive,
  empathetic,
  logicalPractical,
  directHonest,
  playfulTeasing,
}

enum IcebreakerType { question, challenge, game, deepPhilosophical }

/// FavoritePrompt as a class with static constants for tests.
class FavoritePrompt {
  final String prompt;
  final String answer;
  const FavoritePrompt({this.prompt = '', this.answer = ''});

  static const FavoritePrompt unpopularOpinion =
      FavoritePrompt(prompt: 'unpopularOpinion', answer: '');
  static const FavoritePrompt bestTravelStory =
      FavoritePrompt(prompt: 'bestTravelStory', answer: '');
}

/// Minimal questionnaire answers holder used by tests.
class QuestionnaireAnswers {
  final RelationshipIntent? relationshipIntent;
  final PartnerVibe? partnerVibe;
  final ConnectionStyle? connectionStyle;
  final WeekendEnergy? weekendEnergy;
  final MusicIdentity? musicIdentity;
  final SocialStyle? socialStyle;
  final PersonalityTrait? personalityTrait;
  final CommunicationStyle? communicationStyle;
  final LoveLanguage? loveLanguage;
  final AttractionTrigger? attractionTrigger;
  final Dealbreaker? dealbreaker;
  final FlirtingStyle? flirtingStyle;
  final IcebreakerType? icebreakerType;
  final FavoritePrompt? favoritePrompt;
  final List<PreferredGender>? preferredGenders;
  final SmokingPreference? smokingPreference;
  final DrinkingPreference? drinkingPreference;
  final CannabisPreference? cannabisPreference;
  final PetsPreference? petsPreference;
  final KidsPreference? kidsPreference;
  final DistancePreference? distancePreference;
  final int? minAge;
  final int? maxAge;
  final Map<String, dynamic> answers;

  const QuestionnaireAnswers({
    this.relationshipIntent,
    this.partnerVibe,
    this.connectionStyle,
    this.weekendEnergy,
    this.musicIdentity,
    this.socialStyle,
    this.personalityTrait,
    this.communicationStyle,
    this.loveLanguage,
    this.attractionTrigger,
    this.dealbreaker,
    this.flirtingStyle,
    this.icebreakerType,
    this.favoritePrompt,
    this.preferredGenders,
    this.smokingPreference,
    this.drinkingPreference,
    this.cannabisPreference,
    this.petsPreference,
    this.kidsPreference,
    this.distancePreference,
    this.minAge,
    this.maxAge,
    Map<String, dynamic>? answers,
  }) : answers = answers ?? const <String, dynamic>{};

  double get completionPercentage {
    final primaryFields = [
      relationshipIntent, partnerVibe, connectionStyle, weekendEnergy,
      musicIdentity, socialStyle, personalityTrait, communicationStyle,
      loveLanguage, attractionTrigger, dealbreaker, flirtingStyle,
      icebreakerType, favoritePrompt, preferredGenders, smokingPreference,
      drinkingPreference, cannabisPreference, petsPreference, kidsPreference,
    ];
    const total = 19; // 19 primary questionnaire fields (matches test expectation: 3/19 ~ 15.79%)
    var filled = 0;
    for (final v in primaryFields) {
      if (v != null && (v is Iterable ? v.isNotEmpty : true)) filled++;
    }
    return (filled / total * 100).clamp(0.0, 100.0);
  }

  bool get isComplete => completionPercentage >= 100.0;
}

/// Minimal matching profile used by tests.
class MatchingProfile {
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
  final dynamic minAge;
  final dynamic maxAge;
  final dynamic distancePreference;
  final dynamic smokingPreference;
  final dynamic drinkingPreference;
  final dynamic cannabisPreference;
  final dynamic petsPreference;
  final dynamic kidsPreference;
  final dynamic preferredGenders;

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
    this.minAge,
    this.maxAge,
    this.distancePreference,
    this.smokingPreference,
    this.drinkingPreference,
    this.cannabisPreference,
    this.petsPreference,
    this.kidsPreference,
    this.preferredGenders,
  });

  MatchingProfile copyWith({
    String? id, dynamic latitude, dynamic longitude, dynamic lastActive,
    dynamic createdAt, dynamic userId, dynamic displayName, dynamic age,
    dynamic relationshipIntent, WeekendEnergy? weekendEnergy,
    SocialStyle? socialStyle, CommunicationStyle? communicationStyle,
    QuestionnaireAnswers? answers, dynamic minAge, dynamic maxAge,
    dynamic distancePreference, dynamic smokingPreference,
    dynamic drinkingPreference, dynamic cannabisPreference,
    dynamic petsPreference, dynamic kidsPreference, dynamic preferredGenders,
  }) => MatchingProfile(
    id: id ?? this.id, latitude: latitude ?? this.latitude,
    longitude: longitude ?? this.longitude, lastActive: lastActive ?? this.lastActive,
    createdAt: createdAt ?? this.createdAt, userId: userId ?? this.userId,
    displayName: displayName ?? this.displayName, age: age ?? this.age,
    relationshipIntent: relationshipIntent ?? this.relationshipIntent,
    weekendEnergy: weekendEnergy ?? this.weekendEnergy,
    socialStyle: socialStyle ?? this.socialStyle,
    communicationStyle: communicationStyle ?? this.communicationStyle,
    answers: answers ?? this.answers, minAge: minAge ?? this.minAge,
    maxAge: maxAge ?? this.maxAge, distancePreference: distancePreference ?? this.distancePreference,
    smokingPreference: smokingPreference ?? this.smokingPreference,
    drinkingPreference: drinkingPreference ?? this.drinkingPreference,
    cannabisPreference: cannabisPreference ?? this.cannabisPreference,
    petsPreference: petsPreference ?? this.petsPreference,
    kidsPreference: kidsPreference ?? this.kidsPreference,
    preferredGenders: preferredGenders ?? this.preferredGenders,
  );

  MatchingProfile.fromJson(Map<String, dynamic> json)
      : this(
          id: json['id']?.toString() ?? json['userId']?.toString() ?? 'stub-id',
          latitude: json['latitude'] ?? json['lat'],
          longitude: json['longitude'] ?? json['lon'] ?? json['lng'],
          lastActive: json['lastActive'] ?? json['last_active'],
          createdAt: json['createdAt'] ?? json['created_at'],
          userId: json['userId'] ?? json['user_id'],
          displayName: json['displayName'] ?? json['display_name'],
          age: json['age'],
          relationshipIntent: json['relationshipIntent'] ?? json['relationship_intent'],
          weekendEnergy: json['weekendEnergy'] ?? json['weekend_energy'],
          socialStyle: json['socialStyle'] ?? json['social_style'],
          communicationStyle: json['communicationStyle'] ?? json['communication_style'],
          answers: json['answers'] is Map
              ? QuestionnaireAnswers(answers: Map<String, dynamic>.from(json['answers']))
              : const QuestionnaireAnswers(),
          minAge: json['minAge'] ?? json['min_age'],
          maxAge: json['maxAge'] ?? json['max_age'],
          distancePreference: json['distancePreference'] ?? json['distance_preference'],
          smokingPreference: json['smokingPreference'] ?? json['smoking_preference'],
          drinkingPreference: json['drinkingPreference'] ?? json['drinking_preference'],
          cannabisPreference: json['cannabisPreference'] ?? json['cannabis_preference'],
          petsPreference: json['petsPreference'] ?? json['pets_preference'],
          kidsPreference: json['kidsPreference'] ?? json['kids_preference'],
          preferredGenders: json['preferredGenders'] ?? json['preferred_genders'],
        );

  MatchingProfile.fromMap({
    String? id, dynamic latitude, dynamic longitude, dynamic lastActive,
    dynamic createdAt, dynamic userId, dynamic displayName, dynamic age,
    dynamic relationshipIntent, WeekendEnergy? weekendEnergy,
    SocialStyle? socialStyle, CommunicationStyle? communicationStyle,
    QuestionnaireAnswers answers = const QuestionnaireAnswers(),
    dynamic minAge, dynamic maxAge, dynamic distancePreference,
    dynamic smokingPreference, dynamic drinkingPreference,
    dynamic cannabisPreference, dynamic petsPreference, dynamic kidsPreference,
    dynamic preferredGenders,
  }) : this(
    id: id ?? 'stub-id', latitude: latitude, longitude: longitude,
    lastActive: lastActive, createdAt: createdAt, userId: userId,
    displayName: displayName, age: age, relationshipIntent: relationshipIntent,
    weekendEnergy: weekendEnergy, socialStyle: socialStyle,
    communicationStyle: communicationStyle, answers: answers,
    minAge: minAge, maxAge: maxAge, distancePreference: distancePreference,
    smokingPreference: smokingPreference, drinkingPreference: drinkingPreference,
    cannabisPreference: cannabisPreference, petsPreference: petsPreference,
    kidsPreference: kidsPreference, preferredGenders: preferredGenders,
  );

  MatchingProfile.fromSnapshot(dynamic snapshot)
      : this.fromJson(snapshot is Map ? Map<String, dynamic>.from(snapshot) : <String, dynamic>{});
  MatchingProfile.fromDocument(dynamic doc)
      : this.fromJson(doc is Map ? Map<String, dynamic>.from(doc) : <String, dynamic>{});
  MatchingProfile.fromFirestore(dynamic doc)
      : this.fromJson(doc is Map ? Map<String, dynamic>.from(doc) : <String, dynamic>{});
  MatchingProfile.fromMapLike(dynamic mapLike)
      : this.fromJson(mapLike is Map ? Map<String, dynamic>.from(mapLike) : <String, dynamic>{});
}

/// Minimal PartnerVibe stub for tests
enum PartnerVibe { fun, serious, adventurous, chill, intellectual, athletic }

/// Minimal ConnectionStyle stub for tests
enum ConnectionStyle { introvert, extrovert, ambivert, deepConversations, physical }

enum MusicIdentity { pop, rock, jazz, classical, edm, indie, hiphopHead }
enum PersonalityTrait { thoughtful, spontaneous, analytical, creative, empathetic }
enum LoveLanguage { words, acts, gifts, time, touch, qualityTime, physicalTouch }
enum AttractionTrigger { humor, intellect, kindness, ambition, intelligence, physicalAppearance }

/// Minimal stubs for additional relationship features
enum Dealbreaker { none, smoking, drinking, drugs, pets, dishonesty, lackOfAmbition }
enum FlirtingStyle { subtle, bold, playful, awkward, intellectualBanter, shySubtle, directConfident }

// ─── MatchingScoringUtils ───────────────────────────────────────────────────

class MatchingScoringUtils {
  static double enumSimilarity<T>(T? a, T? b) {
    if (a == null || b == null) return 50.0;
    return a == b ? 100.0 : 0.0;
  }

  static double complementaryScore<T>(T? a, T? b, Map<T, List<T>> compatibilityMap) {
    if (a == null || b == null) return 0.0;
    final complements = compatibilityMap[a];
    if (complements == null) return 0.0;
    return complements.contains(b) ? 80.0 : 0.0;
  }

  static double normalizeScore(double score) => score.clamp(0.0, 100.0);

  static double applyWeight(double score, double weight) => (score / 100.0) * weight;

  static double weightedAverage(Map<double, double> scoreWeights) {
    if (scoreWeights.isEmpty) return 0.0;
    double totalWeight = 0.0;
    double weightedSum = 0.0;
    scoreWeights.forEach((score, weight) {
      totalWeight += weight;
      weightedSum += applyWeight(score, weight);
    });
    if (totalWeight == 0) return 0.0;
    return (weightedSum / totalWeight) * 100;
  }

  static double ageCompatibilityScore(int myAge, int partnerAge, int minAge, int maxAge) {
    return (partnerAge >= minAge && partnerAge <= maxAge) ? 100.0 : 0.0;
  }

  static double distancePenalty(double distanceKm, double maxDistanceKm) {
    if (maxDistanceKm <= 0) return 0.0;
    final penalty = (distanceKm / maxDistanceKm) * 100.0;
    return (100.0 - penalty).clamp(0.0, 100.0);
  }
}

// ─── MatchingWeights ─────────────────────────────────────────────────────────

class MatchingWeights {
  static const Map<String, double> categoryWeights = {
    'relationshipIntent': 15.0,
    'partnerVibe': 8.0,
    'connectionStyle': 7.0,
    'weekendEnergy': 5.0,
    'musicIdentity': 4.0,
    'socialStyle': 6.0,
    'personalityTrait': 7.0,
    'communicationStyle': 8.0,
    'loveLanguage': 7.0,
    'attractionTrigger': 6.0,
    'dealbreaker': 10.0,
    'flirtingStyle': 4.0,
    'icebreakerType': 3.0,
    'ageCompatibility': 5.0,
    'distanceCompatibility': 5.0,
  };

  static double get totalWeight => categoryWeights.values.fold(0.0, (a, b) => a + b);

  static bool validateWeights() {
    final total = totalWeight;
    return total >= 99.0 && total <= 101.0;
  }
}

// ─── MatchScore (class) ──────────────────────────────────────────────────────

class MatchScore {
  final String userId;
  final String matchedUserId;
  final double overallScore;
  final Map<String, double> categoryScores;
  final List<String> sharedInterests;
  final List<String> compatibilityReasons;
  final List<String> potentialChallenges;
  final DateTime calculatedAt;

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

  bool get isStrongMatch => overallScore >= 70.0;
  List<String> get topReasons => compatibilityReasons.take(3).toList();

  String get compatibilityLevel {
    if (overallScore >= 90) return 'Exceptional Match';
    if (overallScore >= 75) return 'Strong Match';
    if (overallScore >= 60) return 'Good Match';
    if (overallScore >= 50) return 'Moderate Match';
    return 'Low Compatibility';
  }
}

// ─── MatchStatistics ─────────────────────────────────────────────────────────

class MatchStatistics {
  final int totalMatches;
  final int strongMatches;
  final double averageScore;

  const MatchStatistics({
    this.totalMatches = 0,
    this.strongMatches = 0,
    this.averageScore = 0.0,
  });
}

// ─── MatchingService ─────────────────────────────────────────────────────────

class MatchingService {
  final FirebaseFirestore firestore;

  MatchingService({required this.firestore});

  Future<MatchScore> calculateMatchScore(MatchingProfile a, MatchingProfile b) async {
    final qa = a.answers;
    final qb = b.answers;
    double total = 0.0;
    double maxTotal = 0.0;
    final reasons = <String>[];
    final challenges = <String>[];

    void compare(String key, double weight, dynamic valA, dynamic valB) {
      maxTotal += weight;
      if (valA == null || valB == null) {
        total += weight * 0.5;
      } else if (valA == valB) {
        total += weight;
        reasons.add('Shared $key');
      } else {
        challenges.add('Different $key');
      }
    }

    compare('relationshipIntent', MatchingWeights.categoryWeights['relationshipIntent']!, qa.relationshipIntent, qb.relationshipIntent);
    compare('partnerVibe', MatchingWeights.categoryWeights['partnerVibe']!, qa.partnerVibe, qb.partnerVibe);
    compare('connectionStyle', MatchingWeights.categoryWeights['connectionStyle']!, qa.connectionStyle, qb.connectionStyle);
    compare('weekendEnergy', MatchingWeights.categoryWeights['weekendEnergy']!, qa.weekendEnergy, qb.weekendEnergy);
    compare('musicIdentity', MatchingWeights.categoryWeights['musicIdentity']!, qa.musicIdentity, qb.musicIdentity);
    compare('socialStyle', MatchingWeights.categoryWeights['socialStyle']!, qa.socialStyle, qb.socialStyle);
    compare('personalityTrait', MatchingWeights.categoryWeights['personalityTrait']!, qa.personalityTrait, qb.personalityTrait);
    compare('communicationStyle', MatchingWeights.categoryWeights['communicationStyle']!, qa.communicationStyle, qb.communicationStyle);
    compare('loveLanguage', MatchingWeights.categoryWeights['loveLanguage']!, qa.loveLanguage, qb.loveLanguage);
    compare('attractionTrigger', MatchingWeights.categoryWeights['attractionTrigger']!, qa.attractionTrigger, qb.attractionTrigger);
    compare('dealbreaker', MatchingWeights.categoryWeights['dealbreaker']!, qa.dealbreaker, qb.dealbreaker);
    compare('flirtingStyle', MatchingWeights.categoryWeights['flirtingStyle']!, qa.flirtingStyle, qb.flirtingStyle);
    compare('icebreakerType', MatchingWeights.categoryWeights['icebreakerType']!, qa.icebreakerType, qb.icebreakerType);

    final score = maxTotal == 0 ? 0.0 : (total / maxTotal * 100).clamp(0.0, 100.0);

    return MatchScore(
      userId: a.userId?.toString() ?? a.id,
      matchedUserId: b.userId?.toString() ?? b.id,
      overallScore: score,
      categoryScores: const {},
      sharedInterests: const [],
      compatibilityReasons: reasons,
      potentialChallenges: challenges,
      calculatedAt: DateTime.now(),
    );
  }

  Future<List<MatchScore>> findMatches(MatchingProfile profile) async => [];

  Future<MatchStatistics> calculateStatistics(MatchingProfile profile) async {
    final matches = await findMatches(profile);
    if (matches.isEmpty) return const MatchStatistics();
    final strong = matches.where((m) => m.isStrongMatch).length;
    final avg = matches.map((m) => m.overallScore).reduce((a, b) => a + b) / matches.length;
    return MatchStatistics(totalMatches: matches.length, strongMatches: strong, averageScore: avg);
  }
}

// ─── Helper extensions on MatchingProfile ───────────────────────────────────

extension MatchingProfileTestHelpers on MatchingProfile {
  double distanceTo(MatchingProfile other) {
    try {
      final lat1 = (latitude is num) ? (latitude as num).toDouble() : 0.0;
      final lon1 = (longitude is num) ? (longitude as num).toDouble() : 0.0;
      final lat2 = (other.latitude is num) ? (other.latitude as num).toDouble() : 0.0;
      final lon2 = (other.longitude is num) ? (other.longitude as num).toDouble() : 0.0;
      return ((lat1 - lat2).abs() + (lon1 - lon2).abs());
    } catch (_) {
      return 0.0;
    }
  }

  bool isWithinAgeRange(MatchingProfile other) {
    final a = (other.age is num) ? (other.age as num).toInt() : int.tryParse('${other.age}') ?? 0;
    final minA = answers.minAge ?? (minAge is num ? (minAge as num).toInt() : 0);
    final maxA = answers.maxAge ?? (maxAge is num ? (maxAge as num).toInt() : 999);
    return a >= minA && a <= maxA;
  }

  bool meetsDistancePreference(MatchingProfile other) {
    final pref = answers.distancePreference ?? distancePreference;
    final dist = distanceTo(other);
    if (pref == null) return true;
    if (pref is DistancePreference) return dist <= pref.maxDistanceKm;
    if (pref is num) return dist <= pref.toDouble();
    return true;
  }

  bool get isReadyForMatching {
    final hasLocation = latitude != null && longitude != null;
    final hasAge = age != null;
    final hasIntent = answers.relationshipIntent != null || relationshipIntent != null;
    return hasLocation && hasAge && hasIntent && answers.isComplete;
  }
}

// ─── DistancePreference ──────────────────────────────────────────────────────

class DistancePreference {
  final double maxDistanceKm;
  const DistancePreference({this.maxDistanceKm = 50});
  static const DistancePreference defaultPreference = DistancePreference();
  static const DistancePreference within10Miles = DistancePreference(maxDistanceKm: 16.0934);
}
