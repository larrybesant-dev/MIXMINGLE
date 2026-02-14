import 'package:flutter_test/flutter_test.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:mix_and_mingle/features/matching/models/questionnaire_answers.dart';
import 'package:mix_and_mingle/features/matching/models/matching_profile.dart';
import 'package:mix_and_mingle/features/matching/models/match_score.dart';
import 'package:mix_and_mingle/features/matching/services/matching_service.dart';
import 'package:mix_and_mingle/features/matching/utils/matching_weights.dart';

void main() {
  late FakeFirebaseFirestore fakeFirestore;
  late MatchingService matchingService;

  setUp(() {
    fakeFirestore = FakeFirebaseFirestore();
    matchingService = MatchingService(firestore: fakeFirestore);
  });

  group('MatchingScoringUtils', () {
    test('enumSimilarity returns 100 for identical values', () {
      final score = MatchingScoringUtils.enumSimilarity(
        RelationshipIntent.seriousRelationship,
        RelationshipIntent.seriousRelationship,
      );
      expect(score, 100.0);
    });

    test('enumSimilarity returns 0 for different values', () {
      final score = MatchingScoringUtils.enumSimilarity(
        RelationshipIntent.seriousRelationship,
        RelationshipIntent.casualDating,
      );
      expect(score, 0.0);
    });

    test('enumSimilarity returns 50 for null values', () {
      final score = MatchingScoringUtils.enumSimilarity<RelationshipIntent>(
        null,
        RelationshipIntent.casualDating,
      );
      expect(score, 50.0);
    });

    test('complementaryScore works for matching pairs', () {
      final compatibilityMap = <SocialStyle, List<SocialStyle>>{
        SocialStyle.extrovert: [SocialStyle.ambivert],
        SocialStyle.introvert: [SocialStyle.ambivert],
      };

      final score = MatchingScoringUtils.complementaryScore(
        SocialStyle.extrovert,
        SocialStyle.ambivert,
        compatibilityMap,
      );

      expect(score, 80.0);
    });

    test('normalizeScore clamps values to 0-100', () {
      expect(MatchingScoringUtils.normalizeScore(150.0), 100.0);
      expect(MatchingScoringUtils.normalizeScore(-50.0), 0.0);
      expect(MatchingScoringUtils.normalizeScore(75.0), 75.0);
    });

    test('applyWeight calculates correctly', () {
      final weighted = MatchingScoringUtils.applyWeight(80.0, 10.0);
      expect(weighted, 8.0); // (80/100) * 10 = 8
    });

    test('weightedAverage calculates correctly', () {
      final scores = {
        100.0: 10.0, // Perfect score, weight 10
        50.0: 5.0, // Medium score, weight 5
      };

      final avg = MatchingScoringUtils.weightedAverage(scores);
      // (10 + 2.5) / 15 * 100 = 83.33
      expect(avg, closeTo(83.33, 0.1));
    });

    test('ageCompatibilityScore perfect for same age', () {
      final score = MatchingScoringUtils.ageCompatibilityScore(25, 25, 22, 30);
      expect(score, 100.0);
    });

    test('ageCompatibilityScore returns 0 for out of range', () {
      final score = MatchingScoringUtils.ageCompatibilityScore(25, 35, 22, 30);
      expect(score, 0.0);
    });

    test('distancePenalty works correctly', () {
      expect(MatchingScoringUtils.distancePenalty(0, 10), 100.0);
      expect(MatchingScoringUtils.distancePenalty(5, 10), 50.0);
      expect(MatchingScoringUtils.distancePenalty(10, 10), 0.0);
      expect(MatchingScoringUtils.distancePenalty(15, 10), 0.0);
    });
  });

  group('MatchingWeights', () {
    test('total weights sum to approximately 100', () {
      expect(MatchingWeights.validateWeights(), true);
      expect(MatchingWeights.totalWeight, closeTo(100.0, 1.0));
    });

    test('categoryWeights contains all categories', () {
      final weights = MatchingWeights.categoryWeights;
      expect(weights.length, 15);
      expect(weights.containsKey('relationshipIntent'), true);
      expect(weights.containsKey('partnerVibe'), true);
    });

    test('weights are positive values', () {
      MatchingWeights.categoryWeights.forEach((key, value) {
        expect(value, greaterThan(0.0));
      });
    });
  });

  group('QuestionnaireAnswers', () {
    test('isComplete returns false for incomplete answers', () {
      const answers = QuestionnaireAnswers(
        relationshipIntent: RelationshipIntent.seriousRelationship,
      );
      expect(answers.isComplete, false);
    });

    test('isComplete returns true for complete answers', () {
      const answers = QuestionnaireAnswers(
        relationshipIntent: RelationshipIntent.seriousRelationship,
        partnerVibe: PartnerVibe.intellectual,
        connectionStyle: ConnectionStyle.deepConversations,
        weekendEnergy: WeekendEnergy.balancedMix,
        musicIdentity: MusicIdentity.indie,
        socialStyle: SocialStyle.ambivert,
        personalityTrait: PersonalityTrait.empathetic,
        communicationStyle: CommunicationStyle.directHonest,
        loveLanguage: LoveLanguage.qualityTime,
        attractionTrigger: AttractionTrigger.intelligence,
        dealbreaker: Dealbreaker.dishonesty,
        flirtingStyle: FlirtingStyle.intellectualBanter,
        icebreakerType: IcebreakerType.deepPhilosophical,
        favoritePrompt: FavoritePrompt.unpopularOpinion,
        preferredGenders: [PreferredGender.everyone],
        smokingPreference: SmokingPreference.never,
        drinkingPreference: DrinkingPreference.socially,
        cannabisPreference: CannabisPreference.never,
        petsPreference: PetsPreference.loveBoth,
        kidsPreference: KidsPreference.wantKids,
      );
      expect(answers.isComplete, true);
    });

    test('completionPercentage calculates correctly', () {
      const answers = QuestionnaireAnswers(
        relationshipIntent: RelationshipIntent.seriousRelationship,
        partnerVibe: PartnerVibe.intellectual,
        preferredGenders: [PreferredGender.everyone],
      );
      // 3 out of 19 = ~15.79%
      expect(answers.completionPercentage, closeTo(15.79, 0.1));
    });
  });

  group('MatchingProfile', () {
    test('distanceTo calculates correctly', () {
      final profile1 = MatchingProfile(
        userId: 'user1',
        displayName: 'User 1',
        age: 25,
        latitude: 40.7128, // NYC
        longitude: -74.0060,
        answers: const QuestionnaireAnswers(),
        lastActive: DateTime.now(),
        createdAt: DateTime.now(),
      );

      final profile2 = MatchingProfile(
        userId: 'user2',
        displayName: 'User 2',
        age: 26,
        latitude: 40.7580, // Close to NYC
        longitude: -73.9855,
        answers: const QuestionnaireAnswers(),
        lastActive: DateTime.now(),
        createdAt: DateTime.now(),
      );

      final distance = profile1.distanceTo(profile2);
      expect(distance, greaterThan(0.0));
      expect(distance, lessThan(10.0)); // Should be a few miles
    });

    test('isWithinAgeRange works correctly', () {
      final profile1 = MatchingProfile(
        userId: 'user1',
        displayName: 'User 1',
        age: 25,
        latitude: 0,
        longitude: 0,
        answers: const QuestionnaireAnswers(minAge: 22, maxAge: 30),
        lastActive: DateTime.now(),
        createdAt: DateTime.now(),
      );

      final profile2 = MatchingProfile(
        userId: 'user2',
        displayName: 'User 2',
        age: 26,
        latitude: 0,
        longitude: 0,
        answers: const QuestionnaireAnswers(),
        lastActive: DateTime.now(),
        createdAt: DateTime.now(),
      );

      expect(profile1.isWithinAgeRange(profile2), true);
    });

    test('meetsDistancePreference works correctly', () {
      final profile1 = MatchingProfile(
        userId: 'user1',
        displayName: 'User 1',
        age: 25,
        latitude: 40.7128,
        longitude: -74.0060,
        answers: const QuestionnaireAnswers(
          distancePreference: DistancePreference.within10Miles,
        ),
        lastActive: DateTime.now(),
        createdAt: DateTime.now(),
      );

      final profile2 = MatchingProfile(
        userId: 'user2',
        displayName: 'User 2',
        age: 26,
        latitude: 40.7580,
        longitude: -73.9855,
        answers: const QuestionnaireAnswers(),
        lastActive: DateTime.now(),
        createdAt: DateTime.now(),
      );

      expect(profile1.meetsDistancePreference(profile2), true);
    });

    test('isReadyForMatching checks profile completeness', () {
      final profile = MatchingProfile(
        userId: 'user1',
        displayName: 'User 1',
        age: 25,
        latitude: 0,
        longitude: 0,
        answers: const QuestionnaireAnswers(
          relationshipIntent: RelationshipIntent.seriousRelationship,
        ),
        lastActive: DateTime.now(),
        createdAt: DateTime.now(),
      );

      expect(profile.isReadyForMatching, false);
    });
  });

  group('MatchingService', () {
    test('calculateMatchScore returns perfect score for identical profiles', () async {
      const answers = QuestionnaireAnswers(
        relationshipIntent: RelationshipIntent.seriousRelationship,
        partnerVibe: PartnerVibe.intellectual,
        connectionStyle: ConnectionStyle.deepConversations,
        weekendEnergy: WeekendEnergy.balancedMix,
        musicIdentity: MusicIdentity.indie,
        socialStyle: SocialStyle.ambivert,
        personalityTrait: PersonalityTrait.empathetic,
        communicationStyle: CommunicationStyle.directHonest,
        loveLanguage: LoveLanguage.qualityTime,
        attractionTrigger: AttractionTrigger.intelligence,
        dealbreaker: Dealbreaker.dishonesty,
        flirtingStyle: FlirtingStyle.intellectualBanter,
        icebreakerType: IcebreakerType.deepPhilosophical,
        favoritePrompt: FavoritePrompt.unpopularOpinion,
        preferredGenders: [PreferredGender.everyone],
        smokingPreference: SmokingPreference.never,
        drinkingPreference: DrinkingPreference.socially,
        cannabisPreference: CannabisPreference.never,
        petsPreference: PetsPreference.loveBoth,
        kidsPreference: KidsPreference.wantKids,
      );

      final profile1 = MatchingProfile(
        userId: 'user1',
        displayName: 'User 1',
        age: 25,
        latitude: 40.7128,
        longitude: -74.0060,
        answers: answers,
        lastActive: DateTime.now(),
        createdAt: DateTime.now(),
      );

      final profile2 = MatchingProfile(
        userId: 'user2',
        displayName: 'User 2',
        age: 26,
        latitude: 40.7580,
        longitude: -73.9855,
        answers: answers,
        lastActive: DateTime.now(),
        createdAt: DateTime.now(),
      );

      final matchScore = await matchingService.calculateMatchScore(profile1, profile2);

      expect(matchScore.overallScore, greaterThan(90.0));
      expect(matchScore.compatibilityReasons.isNotEmpty, true);
      expect(matchScore.isStrongMatch, true);
    });

    test('calculateMatchScore returns low score for incompatible profiles', () async {
      final profile1 = MatchingProfile(
        userId: 'user1',
        displayName: 'User 1',
        age: 25,
        latitude: 40.7128,
        longitude: -74.0060,
        answers: const QuestionnaireAnswers(
          relationshipIntent: RelationshipIntent.seriousRelationship,
          partnerVibe: PartnerVibe.intellectual,
          connectionStyle: ConnectionStyle.deepConversations,
          weekendEnergy: WeekendEnergy.homebody,
          musicIdentity: MusicIdentity.classical,
          socialStyle: SocialStyle.introvert,
          personalityTrait: PersonalityTrait.analytical,
          communicationStyle: CommunicationStyle.logicalPractical,
          loveLanguage: LoveLanguage.qualityTime,
          attractionTrigger: AttractionTrigger.intelligence,
          dealbreaker: Dealbreaker.smoking,
          flirtingStyle: FlirtingStyle.shySubtle,
          icebreakerType: IcebreakerType.deepPhilosophical,
          favoritePrompt: FavoritePrompt.unpopularOpinion,
          preferredGenders: [PreferredGender.everyone],
          smokingPreference: SmokingPreference.never,
          drinkingPreference: DrinkingPreference.never,
          cannabisPreference: CannabisPreference.never,
          petsPreference: PetsPreference.noPets,
          kidsPreference: KidsPreference.dontWantKids,
        ),
        lastActive: DateTime.now(),
        createdAt: DateTime.now(),
      );

      final profile2 = MatchingProfile(
        userId: 'user2',
        displayName: 'User 2',
        age: 26,
        latitude: 40.7580,
        longitude: -73.9855,
        answers: const QuestionnaireAnswers(
          relationshipIntent: RelationshipIntent.casualDating,
          partnerVibe: PartnerVibe.athletic,
          connectionStyle: ConnectionStyle.physical,
          weekendEnergy: WeekendEnergy.partyAnimal,
          musicIdentity: MusicIdentity.hiphopHead,
          socialStyle: SocialStyle.extrovert,
          personalityTrait: PersonalityTrait.spontaneous,
          communicationStyle: CommunicationStyle.playfulTeasing,
          loveLanguage: LoveLanguage.physicalTouch,
          attractionTrigger: AttractionTrigger.physicalAppearance,
          dealbreaker: Dealbreaker.lackOfAmbition,
          flirtingStyle: FlirtingStyle.directConfident,
          icebreakerType: IcebreakerType.game,
          favoritePrompt: FavoritePrompt.bestTravelStory,
          preferredGenders: [PreferredGender.everyone],
          smokingPreference: SmokingPreference.regularly,
          drinkingPreference: DrinkingPreference.regularly,
          cannabisPreference: CannabisPreference.regularly,
          petsPreference: PetsPreference.loveDogs,
          kidsPreference: KidsPreference.haveKids,
        ),
        lastActive: DateTime.now(),
        createdAt: DateTime.now(),
      );

      final matchScore = await matchingService.calculateMatchScore(profile1, profile2);

      expect(matchScore.overallScore, lessThan(50.0));
      expect(matchScore.potentialChallenges.isNotEmpty, true);
      expect(matchScore.isStrongMatch, false);
    });

    test('findMatches returns empty list when no profiles exist', () async {
      final profile = MatchingProfile(
        userId: 'user1',
        displayName: 'User 1',
        age: 25,
        latitude: 40.7128,
        longitude: -74.0060,
        answers: const QuestionnaireAnswers(
          relationshipIntent: RelationshipIntent.seriousRelationship,
          partnerVibe: PartnerVibe.intellectual,
          connectionStyle: ConnectionStyle.deepConversations,
          weekendEnergy: WeekendEnergy.balancedMix,
          musicIdentity: MusicIdentity.indie,
          socialStyle: SocialStyle.ambivert,
          personalityTrait: PersonalityTrait.empathetic,
          communicationStyle: CommunicationStyle.directHonest,
          loveLanguage: LoveLanguage.qualityTime,
          attractionTrigger: AttractionTrigger.intelligence,
          dealbreaker: Dealbreaker.dishonesty,
          flirtingStyle: FlirtingStyle.intellectualBanter,
          icebreakerType: IcebreakerType.deepPhilosophical,
          favoritePrompt: FavoritePrompt.unpopularOpinion,
          preferredGenders: [PreferredGender.everyone],
          smokingPreference: SmokingPreference.never,
          drinkingPreference: DrinkingPreference.socially,
          cannabisPreference: CannabisPreference.never,
          petsPreference: PetsPreference.loveBoth,
          kidsPreference: KidsPreference.wantKids,
        ),
        lastActive: DateTime.now(),
        createdAt: DateTime.now(),
      );

      final matches = await matchingService.findMatches(profile);
      expect(matches, isEmpty);
    });

    test('calculateStatistics handles empty matches correctly', () async {
      final profile = MatchingProfile(
        userId: 'user1',
        displayName: 'User 1',
        age: 25,
        latitude: 40.7128,
        longitude: -74.0060,
        answers: const QuestionnaireAnswers(
          relationshipIntent: RelationshipIntent.seriousRelationship,
          preferredGenders: [PreferredGender.everyone],
        ),
        lastActive: DateTime.now(),
        createdAt: DateTime.now(),
      );

      final stats = await matchingService.calculateStatistics(profile);

      expect(stats.totalMatches, 0);
      expect(stats.strongMatches, 0);
      expect(stats.averageScore, 0.0);
    });
  });

  group('MatchScore', () {
    test('compatibilityLevel returns correct string', () {
      final score1 = MatchScore(
        userId: 'user1',
        matchedUserId: 'user2',
        overallScore: 95.0,
        categoryScores: const {},
        sharedInterests: const [],
        compatibilityReasons: const [],
        potentialChallenges: const [],
        calculatedAt: DateTime.now(),
      );

      expect(score1.compatibilityLevel, 'Exceptional Match');

      final score2 = MatchScore(
        userId: 'user1',
        matchedUserId: 'user2',
        overallScore: 45.0,
        categoryScores: const {},
        sharedInterests: const [],
        compatibilityReasons: const [],
        potentialChallenges: const [],
        calculatedAt: DateTime.now(),
      );

      expect(score2.compatibilityLevel, 'Low Compatibility');
    });

    test('isStrongMatch threshold works correctly', () {
      final score1 = MatchScore(
        userId: 'user1',
        matchedUserId: 'user2',
        overallScore: 75.0,
        categoryScores: const {},
        sharedInterests: const [],
        compatibilityReasons: const [],
        potentialChallenges: const [],
        calculatedAt: DateTime.now(),
      );

      expect(score1.isStrongMatch, true);

      final score2 = MatchScore(
        userId: 'user1',
        matchedUserId: 'user2',
        overallScore: 65.0,
        categoryScores: const {},
        sharedInterests: const [],
        compatibilityReasons: const [],
        potentialChallenges: const [],
        calculatedAt: DateTime.now(),
      );

      expect(score2.isStrongMatch, false);
    });

    test('topReasons returns maximum 3 reasons', () {
      final reasons = [
        'Reason 1',
        'Reason 2',
        'Reason 3',
        'Reason 4',
        'Reason 5',
      ];

      final score = MatchScore(
        userId: 'user1',
        matchedUserId: 'user2',
        overallScore: 80.0,
        categoryScores: const {},
        sharedInterests: const [],
        compatibilityReasons: reasons,
        potentialChallenges: const [],
        calculatedAt: DateTime.now(),
      );

      expect(score.topReasons.length, 3);
    });
  });
}
