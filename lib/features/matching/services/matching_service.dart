import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/questionnaire_answers.dart';
import '../models/match_score.dart';
import '../models/matching_profile.dart';
import '../utils/matching_weights.dart';

/// Core matching service that calculates compatibility between users
class MatchingService {
  final FirebaseFirestore _firestore;

  MatchingService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  /// Calculate match score between two users
  Future<MatchScore> calculateMatchScore(
    MatchingProfile user1,
    MatchingProfile user2,
  ) async {
    // Check if users are compatible at all
    if (!_areBasicallyCompatible(user1, user2)) {
      return _createLowScoreMatch(user1.userId, user2.userId);
    }

    final categoryScores = <String, double>{};
    final sharedInterests = <String>[];
    final compatibilityReasons = <String>[];
    final potentialChallenges = <String>[];

    // Core Compatibility Scores
    categoryScores['relationshipIntent'] = _scoreRelationshipIntent(
      user1.answers,
      user2.answers,
      compatibilityReasons,
      potentialChallenges,
    );

    categoryScores['partnerVibe'] = _scorePartnerVibe(
      user1.answers,
      user2.answers,
      sharedInterests,
    );

    categoryScores['connectionStyle'] = _scoreConnectionStyle(
      user1.answers,
      user2.answers,
      compatibilityReasons,
    );

    categoryScores['attractionTrigger'] = _scoreAttractionTrigger(
      user1.answers,
      user2.answers,
    );

    // Lifestyle Compatibility
    categoryScores['weekendEnergy'] = _scoreWeekendEnergy(
      user1.answers,
      user2.answers,
      sharedInterests,
    );

    categoryScores['socialStyle'] = _scoreSocialStyle(
      user1.answers,
      user2.answers,
      compatibilityReasons,
    );

    categoryScores['musicIdentity'] = _scoreMusicIdentity(
      user1.answers,
      user2.answers,
      sharedInterests,
    );

    categoryScores['lifestyleHabits'] = _scoreLifestyleHabits(
      user1.answers,
      user2.answers,
      potentialChallenges,
    );

    // Communication & Personality
    categoryScores['communicationStyle'] = _scoreCommunicationStyle(
      user1.answers,
      user2.answers,
      compatibilityReasons,
    );

    categoryScores['personalityTrait'] = _scorePersonalityTrait(
      user1.answers,
      user2.answers,
    );

    categoryScores['loveLanguage'] = _scoreLoveLanguage(
      user1.answers,
      user2.answers,
      compatibilityReasons,
    );

    // Preferences
    categoryScores['flirtingStyle'] = _scoreFlirtingStyle(
      user1.answers,
      user2.answers,
    );

    categoryScores['icebreakerType'] = _scoreIcebreakerType(
      user1.answers,
      user2.answers,
      sharedInterests,
    );

    categoryScores['favoritePrompt'] = _scoreFavoritePrompt(
      user1.answers,
      user2.answers,
    );

    categoryScores['petsKidsPreference'] = _scorePetsKidsPreference(
      user1.answers,
      user2.answers,
      potentialChallenges,
    );

    // Calculate overall weighted score
    final overallScore = _calculateWeightedScore(categoryScores);

    return MatchScore(
      userId: user1.userId,
      matchedUserId: user2.userId,
      overallScore: overallScore,
      categoryScores: categoryScores,
      sharedInterests: sharedInterests,
      compatibilityReasons: compatibilityReasons,
      potentialChallenges: potentialChallenges,
      calculatedAt: DateTime.now(),
    );
  }

  /// Find and rank all potential matches for a user
  Future<List<RankedMatch>> findMatches(
    MatchingProfile currentUser, {
    int limit = 50,
    double minScore = 50.0,
  }) async {
    // Fetch potential matches from Firestore
    final potentialMatches = await _fetchPotentialMatches(currentUser);

    final matchScores = <MatchScore>[];

    for (final candidate in potentialMatches) {
      final score = await calculateMatchScore(currentUser, candidate);
      if (score.overallScore >= minScore) {
        matchScores.add(score);
      }
    }

    // Sort by score descending
    matchScores.sort((a, b) => b.overallScore.compareTo(a.overallScore));

    // Convert to RankedMatch and take top N
    final rankedMatches = <RankedMatch>[];
    for (int i = 0; i < matchScores.length && i < limit; i++) {
      final score = matchScores[i];
      final matchedUser = potentialMatches.firstWhere(
        (u) => u.userId == score.matchedUserId,
      );

      rankedMatches.add(
        RankedMatch(
          userId: matchedUser.userId,
          userName: matchedUser.displayName,
          userPhotoUrl: matchedUser.photoUrl,
          age: matchedUser.age,
          distanceInMiles: currentUser.distanceTo(matchedUser),
          matchScore: score,
          rank: i + 1,
        ),
      );
    }

    return rankedMatches;
  }

  /// Fetch potential matches from database
  Future<List<MatchingProfile>> _fetchPotentialMatches(
    MatchingProfile currentUser,
  ) async {
    final query = _firestore
        .collection('matching_profiles')
        .where('isActive', isEqualTo: true)
        .where('userId', isNotEqualTo: currentUser.userId);

    final snapshot = await query.get();
    final profiles = snapshot.docs
        .map((doc) => MatchingProfile.fromJson(doc.data()))
        .where((profile) {
      // Filter by basic criteria
      return !currentUser.hasBlocked(profile.userId) &&
          !profile.hasBlocked(currentUser.userId) &&
          currentUser.isWithinAgeRange(profile) &&
          currentUser.meetsDistancePreference(profile) &&
          _isGenderMatch(currentUser.answers, profile);
    }).toList();

    return profiles;
  }

  /// Check if gender preferences match
  bool _isGenderMatch(
    QuestionnaireAnswers userAnswers,
    MatchingProfile candidate,
  ) {
    if (userAnswers.preferredGenders.isEmpty) return true;
    if (userAnswers.preferredGenders.contains(PreferredGender.everyone)) {
      return true;
    }
    // Would check candidate's gender - simplified for now
    return true;
  }

  /// Check basic compatibility requirements
  bool _areBasicallyCompatible(
    MatchingProfile user1,
    MatchingProfile user2,
  ) {
    // Check dealbreakers
    if (user1.answers.dealbreaker != null) {
      if (_checkDealbreaker(user1.answers.dealbreaker!, user2.answers)) {
        return false;
      }
    }

    // Both must have complete profiles
    return user1.isReadyForMatching && user2.isReadyForMatching;
  }

  /// Check if a dealbreaker is violated
  bool _checkDealbreaker(
      Dealbreaker dealbreaker, QuestionnaireAnswers answers) {
    switch (dealbreaker) {
      case Dealbreaker.smoking:
        return answers.smokingPreference == SmokingPreference.regularly;
      case Dealbreaker.dishonesty:
        return false; // Would check user behavior
      case Dealbreaker.poorHygiene:
        return false; // Would check user reviews
      case Dealbreaker.rudeness:
        return false; // Would check user reviews
      case Dealbreaker.lackOfAmbition:
        return false; // Would check profile completeness
      case Dealbreaker.differentValues:
        return false; // Checked in relationship intent
      case Dealbreaker.badCommunication:
        return false; // Would check message response patterns
      case Dealbreaker.jealousy:
        return false; // Would check user behavior
    }
  }

  /// Calculate weighted overall score
  double _calculateWeightedScore(Map<String, double> categoryScores) {
    double totalWeighted = 0.0;

    categoryScores.forEach((category, score) {
      final weight = MatchingWeights.categoryWeights[category] ?? 1.0;
      totalWeighted += MatchingScoringUtils.applyWeight(score, weight);
    });

    return MatchingScoringUtils.normalizeScore(totalWeighted);
  }

  /// Individual scoring methods for each category

  double _scoreRelationshipIntent(
    QuestionnaireAnswers user1,
    QuestionnaireAnswers user2,
    List<String> reasons,
    List<String> challenges,
  ) {
    final score = MatchingScoringUtils.enumSimilarity(
      user1.relationshipIntent,
      user2.relationshipIntent,
    );

    if (score == 100.0) {
      reasons.add('Both looking for ${user1.relationshipIntent?.name}');
    } else if (score == 0.0) {
      challenges.add('Different relationship goals');
    }

    return score;
  }

  double _scorePartnerVibe(
    QuestionnaireAnswers user1,
    QuestionnaireAnswers user2,
    List<String> interests,
  ) {
    final score = MatchingScoringUtils.enumSimilarity(
      user1.partnerVibe,
      user2.partnerVibe,
    );

    if (score == 100.0) {
      interests.add('Both are ${user1.partnerVibe?.name}');
    }

    return score;
  }

  double _scoreConnectionStyle(
    QuestionnaireAnswers user1,
    QuestionnaireAnswers user2,
    List<String> reasons,
  ) {
    final score = MatchingScoringUtils.enumSimilarity(
      user1.connectionStyle,
      user2.connectionStyle,
    );

    if (score == 100.0) {
      reasons.add('Same connection style: ${user1.connectionStyle?.name}');
    }

    return score;
  }

  double _scoreAttractionTrigger(
    QuestionnaireAnswers user1,
    QuestionnaireAnswers user2,
  ) {
    return MatchingScoringUtils.enumSimilarity(
      user1.attractionTrigger,
      user2.attractionTrigger,
    );
  }

  double _scoreWeekendEnergy(
    QuestionnaireAnswers user1,
    QuestionnaireAnswers user2,
    List<String> interests,
  ) {
    // Use complementary scoring for weekend energy
    final compatibilityMap = <WeekendEnergy, List<WeekendEnergy>>{
      WeekendEnergy.partyAnimal: [
        WeekendEnergy.socialButterfly,
        WeekendEnergy.balancedMix
      ],
      WeekendEnergy.socialButterfly: [
        WeekendEnergy.partyAnimal,
        WeekendEnergy.balancedMix
      ],
      WeekendEnergy.balancedMix: [
        WeekendEnergy.socialButterfly,
        WeekendEnergy.quietNights
      ],
      WeekendEnergy.quietNights: [
        WeekendEnergy.balancedMix,
        WeekendEnergy.homebody
      ],
      WeekendEnergy.homebody: [WeekendEnergy.quietNights],
    };

    final score = MatchingScoringUtils.complementaryScore(
      user1.weekendEnergy,
      user2.weekendEnergy,
      compatibilityMap,
    );

    if (score >= 80.0) {
      interests.add('Compatible weekend vibes');
    }

    return score;
  }

  double _scoreSocialStyle(
    QuestionnaireAnswers user1,
    QuestionnaireAnswers user2,
    List<String> reasons,
  ) {
    final compatibilityMap = <SocialStyle, List<SocialStyle>>{
      SocialStyle.extrovert: [SocialStyle.ambivert, SocialStyle.extrovert],
      SocialStyle.introvert: [SocialStyle.ambivert, SocialStyle.introvert],
      SocialStyle.ambivert: [
        SocialStyle.extrovert,
        SocialStyle.introvert,
        SocialStyle.ambivert
      ],
      SocialStyle.selective: [SocialStyle.selective, SocialStyle.ambivert],
    };

    final score = MatchingScoringUtils.complementaryScore(
      user1.socialStyle,
      user2.socialStyle,
      compatibilityMap,
    );

    if (score == 100.0) {
      reasons.add('Perfect social energy match');
    }

    return score;
  }

  double _scoreMusicIdentity(
    QuestionnaireAnswers user1,
    QuestionnaireAnswers user2,
    List<String> interests,
  ) {
    final score = MatchingScoringUtils.enumSimilarity(
      user1.musicIdentity,
      user2.musicIdentity,
    );

    if (score == 100.0) {
      interests.add('Same music taste: ${user1.musicIdentity?.name}');
    } else if (user1.musicIdentity == MusicIdentity.eclectic ||
        user2.musicIdentity == MusicIdentity.eclectic) {
      return 70.0; // Eclectic users are flexible
    }

    return score;
  }

  double _scoreLifestyleHabits(
    QuestionnaireAnswers user1,
    QuestionnaireAnswers user2,
    List<String> challenges,
  ) {
    final double smokingScore = MatchingScoringUtils.enumSimilarity(
      user1.smokingPreference,
      user2.smokingPreference,
    );

    final double drinkingScore = MatchingScoringUtils.enumSimilarity(
      user1.drinkingPreference,
      user2.drinkingPreference,
    );

    final double cannabisScore = MatchingScoringUtils.enumSimilarity(
      user1.cannabisPreference,
      user2.cannabisPreference,
    );

    // Check for potential conflicts
    if (smokingScore < 50.0) challenges.add('Different smoking preferences');
    if (drinkingScore < 50.0) challenges.add('Different drinking habits');

    return (smokingScore + drinkingScore + cannabisScore) / 3.0;
  }

  double _scoreCommunicationStyle(
    QuestionnaireAnswers user1,
    QuestionnaireAnswers user2,
    List<String> reasons,
  ) {
    final compatibilityMap = <CommunicationStyle, List<CommunicationStyle>>{
      CommunicationStyle.directHonest: [
        CommunicationStyle.directHonest,
        CommunicationStyle.logicalPractical,
      ],
      CommunicationStyle.diplomaticCareful: [
        CommunicationStyle.diplomaticCareful,
        CommunicationStyle.deepEmotional,
      ],
      CommunicationStyle.playfulTeasing: [
        CommunicationStyle.playfulTeasing,
        CommunicationStyle.directHonest,
      ],
      CommunicationStyle.deepEmotional: [
        CommunicationStyle.deepEmotional,
        CommunicationStyle.diplomaticCareful,
      ],
      CommunicationStyle.logicalPractical: [
        CommunicationStyle.logicalPractical,
        CommunicationStyle.directHonest,
      ],
    };

    final score = MatchingScoringUtils.complementaryScore(
      user1.communicationStyle,
      user2.communicationStyle,
      compatibilityMap,
    );

    if (score >= 80.0) {
      reasons.add('Compatible communication styles');
    }

    return score;
  }

  double _scorePersonalityTrait(
    QuestionnaireAnswers user1,
    QuestionnaireAnswers user2,
  ) {
    final compatibilityMap = <PersonalityTrait, List<PersonalityTrait>>{
      PersonalityTrait.spontaneous: [
        PersonalityTrait.spontaneous,
        PersonalityTrait.creative
      ],
      PersonalityTrait.planner: [
        PersonalityTrait.planner,
        PersonalityTrait.analytical
      ],
      PersonalityTrait.analytical: [
        PersonalityTrait.analytical,
        PersonalityTrait.planner
      ],
      PersonalityTrait.creative: [
        PersonalityTrait.creative,
        PersonalityTrait.spontaneous
      ],
      PersonalityTrait.empathetic: [
        PersonalityTrait.empathetic,
        PersonalityTrait.curious
      ],
      PersonalityTrait.confident: [
        PersonalityTrait.confident,
        PersonalityTrait.empathetic
      ],
      PersonalityTrait.curious: [
        PersonalityTrait.curious,
        PersonalityTrait.creative
      ],
    };

    return MatchingScoringUtils.complementaryScore(
      user1.personalityTrait,
      user2.personalityTrait,
      compatibilityMap,
    );
  }

  double _scoreLoveLanguage(
    QuestionnaireAnswers user1,
    QuestionnaireAnswers user2,
    List<String> reasons,
  ) {
    final score = MatchingScoringUtils.enumSimilarity(
      user1.loveLanguage,
      user2.loveLanguage,
    );

    if (score == 100.0) {
      reasons.add('Same love language: ${user1.loveLanguage?.name}');
    }

    return score;
  }

  double _scoreFlirtingStyle(
    QuestionnaireAnswers user1,
    QuestionnaireAnswers user2,
  ) {
    return MatchingScoringUtils.enumSimilarity(
      user1.flirtingStyle,
      user2.flirtingStyle,
    );
  }

  double _scoreIcebreakerType(
    QuestionnaireAnswers user1,
    QuestionnaireAnswers user2,
    List<String> interests,
  ) {
    final score = MatchingScoringUtils.enumSimilarity(
      user1.icebreakerType,
      user2.icebreakerType,
    );

    if (score == 100.0) {
      interests.add('Love the same icebreakers');
    }

    return score;
  }

  double _scoreFavoritePrompt(
    QuestionnaireAnswers user1,
    QuestionnaireAnswers user2,
  ) {
    return MatchingScoringUtils.enumSimilarity(
      user1.favoritePrompt,
      user2.favoritePrompt,
    );
  }

  double _scorePetsKidsPreference(
    QuestionnaireAnswers user1,
    QuestionnaireAnswers user2,
    List<String> challenges,
  ) {
    final double petsScore = MatchingScoringUtils.enumSimilarity(
      user1.petsPreference,
      user2.petsPreference,
    );

    final double kidsScore = MatchingScoringUtils.enumSimilarity(
      user1.kidsPreference,
      user2.kidsPreference,
    );

    // Kids preference is more critical
    if (kidsScore < 50.0) {
      challenges.add('Different views on having children');
    }

    return (petsScore * 0.3) + (kidsScore * 0.7);
  }

  /// Create a low-score match for incompatible users
  MatchScore _createLowScoreMatch(String userId, String matchedUserId) {
    return MatchScore(
      userId: userId,
      matchedUserId: matchedUserId,
      overallScore: 0.0,
      categoryScores: {},
      sharedInterests: [],
      compatibilityReasons: [],
      potentialChallenges: ['Not compatible'],
      calculatedAt: DateTime.now(),
    );
  }

  /// Calculate match statistics for a user
  Future<MatchStatistics> calculateStatistics(
    MatchingProfile currentUser,
  ) async {
    final matches = await findMatches(currentUser, limit: 100, minScore: 0.0);

    if (matches.isEmpty) {
      return MatchStatistics(
        totalMatches: 0,
        strongMatches: 0,
        averageScore: 0.0,
        highestScore: 0.0,
        lowestScore: 0.0,
        compatibilityDistribution: {},
        calculatedAt: DateTime.now(),
      );
    }

    final scores = matches.map((m) => m.matchScore.overallScore).toList();
    final strongMatches =
        matches.where((m) => m.matchScore.isStrongMatch).length;

    final distribution = <String, int>{
      '90-100': scores.where((s) => s >= 90).length,
      '80-89': scores.where((s) => s >= 80 && s < 90).length,
      '70-79': scores.where((s) => s >= 70 && s < 80).length,
      '60-69': scores.where((s) => s >= 60 && s < 70).length,
      '50-59': scores.where((s) => s >= 50 && s < 60).length,
      'Below 50': scores.where((s) => s < 50).length,
    };

    return MatchStatistics(
      totalMatches: matches.length,
      strongMatches: strongMatches,
      averageScore: scores.reduce((a, b) => a + b) / scores.length,
      highestScore: scores.reduce((a, b) => a > b ? a : b),
      lowestScore: scores.reduce((a, b) => a < b ? a : b),
      compatibilityDistribution: distribution,
      calculatedAt: DateTime.now(),
    );
  }
}
