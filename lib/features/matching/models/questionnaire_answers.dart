// import 'package:freezed_annotation/freezed_annotation.dart';

// part 'questionnaire_answers.freezed.dart';
// part 'questionnaire_answers.g.dart';

/// All possible answer options for the speed dating questionnaire
enum RelationshipIntent {
  casualDating,
  seriousRelationship,
  friendship,
  networking,
  figureItOut,
}

enum PartnerVibe {
  adventurous,
  intellectual,
  creative,
  athletic,
  spiritual,
  ambitious,
  chill,
}

enum ConnectionStyle {
  deepConversations,
  sharedActivities,
  physical,
  humor,
  emotional,
}

enum WeekendEnergy {
  partyAnimal,
  socialButterfly,
  balancedMix,
  quietNights,
  homebody,
}

enum MusicIdentity {
  popLover,
  rockRebel,
  hiphopHead,
  jazzSoul,
  electronic,
  indie,
  classical,
  country,
  eclectic,
}

enum SocialStyle {
  extrovert,
  introvert,
  ambivert,
  selective,
}

enum PersonalityTrait {
  spontaneous,
  planner,
  analytical,
  creative,
  empathetic,
  confident,
  curious,
}

enum CommunicationStyle {
  directHonest,
  diplomaticCareful,
  playfulTeasing,
  deepEmotional,
  logicalPractical,
}

enum LoveLanguage {
  wordsOfAffirmation,
  qualityTime,
  physicalTouch,
  actsOfService,
  receivingGifts,
}

enum AttractionTrigger {
  intelligence,
  humor,
  confidence,
  kindness,
  ambition,
  creativity,
  physicalAppearance,
  sharedValues,
}

enum Dealbreaker {
  smoking,
  poorHygiene,
  rudeness,
  dishonesty,
  lackOfAmbition,
  differentValues,
  badCommunication,
  jealousy,
}

enum FlirtingStyle {
  playfulTeasing,
  directConfident,
  shySubtle,
  intellectualBanter,
  compliments,
  physicalTouch,
}

enum IcebreakerType {
  funnyQuestion,
  deepPhilosophical,
  wouldYouRather,
  storyTime,
  debate,
  game,
}

enum FavoritePrompt {
  twoTruthsOneLie,
  bestTravelStory,
  passionProject,
  perfectDate,
  unpopularOpinion,
  hiddenTalent,
}

enum PreferredGender {
  men,
  women,
  nonBinary,
  everyone,
}

enum DistancePreference {
  within5Miles,
  within10Miles,
  within25Miles,
  within50Miles,
  anywhere,
}

enum SmokingPreference {
  never,
  socially,
  regularly,
  noPreference,
}

enum DrinkingPreference {
  never,
  socially,
  regularly,
  noPreference,
}

enum CannabisPreference {
  never,
  occasionally,
  regularly,
  noPreference,
}

enum PetsPreference {
  loveDogs,
  loveCats,
  loveBoth,
  noPreference,
  noPets,
}

enum KidsPreference {
  haveKids,
  wantKids,
  dontWantKids,
  openToIt,
  noPreference,
}

/// Complete questionnaire answers for a user
// @freezed
class QuestionnaireAnswers {
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
    this.minAge = 18,
    this.maxAge = 80,
    this.preferredGenders = const [],
    this.distancePreference = DistancePreference.within25Miles,
    this.smokingPreference,
    this.drinkingPreference,
    this.cannabisPreference,
    this.petsPreference,
    this.kidsPreference,
  });

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
  final int minAge;
  final int maxAge;
  final List<PreferredGender> preferredGenders;
  final DistancePreference distancePreference;
  final SmokingPreference? smokingPreference;
  final DrinkingPreference? drinkingPreference;
  final CannabisPreference? cannabisPreference;
  final PetsPreference? petsPreference;
  final KidsPreference? kidsPreference;

  factory QuestionnaireAnswers.fromJson(Map<String, dynamic> json) {
    return QuestionnaireAnswers(
      minAge: json['minAge'] as int? ?? 18,
      maxAge: json['maxAge'] as int? ?? 80,
      preferredGenders: const [],
      distancePreference: DistancePreference.within25Miles,
    );
  }

  /// Check if questionnaire is complete
  bool get isComplete {
    return relationshipIntent != null &&
        partnerVibe != null &&
        connectionStyle != null &&
        weekendEnergy != null &&
        musicIdentity != null &&
        socialStyle != null &&
        personalityTrait != null &&
        communicationStyle != null &&
        loveLanguage != null &&
        attractionTrigger != null &&
        dealbreaker != null &&
        flirtingStyle != null &&
        icebreakerType != null &&
        favoritePrompt != null &&
        preferredGenders.isNotEmpty &&
        smokingPreference != null &&
        drinkingPreference != null &&
        cannabisPreference != null &&
        petsPreference != null &&
        kidsPreference != null;
  }

  /// Calculate completion percentage
  double get completionPercentage {
    int completed = 0;
    const int total = 19;

    if (relationshipIntent != null) completed++;
    if (partnerVibe != null) completed++;
    if (connectionStyle != null) completed++;
    if (weekendEnergy != null) completed++;
    if (musicIdentity != null) completed++;
    if (socialStyle != null) completed++;
    if (personalityTrait != null) completed++;
    if (communicationStyle != null) completed++;
    if (loveLanguage != null) completed++;
    if (attractionTrigger != null) completed++;
    if (dealbreaker != null) completed++;
    if (flirtingStyle != null) completed++;
    if (icebreakerType != null) completed++;
    if (favoritePrompt != null) completed++;
    if (preferredGenders.isNotEmpty) completed++;
    if (smokingPreference != null) completed++;
    if (drinkingPreference != null) completed++;
    if (cannabisPreference != null) completed++;
    if (petsPreference != null) completed++;
    if (kidsPreference != null) completed++;

    return (completed / total) * 100;
  }
}


