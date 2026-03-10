/// Weight configuration for the matching algorithm
class MatchingWeights {
  // Core Compatibility (40% total weight)
  static const double relationshipIntent = 15.0;
  static const double partnerVibe = 10.0;
  static const double connectionStyle = 8.0;
  static const double attractionTrigger = 7.0;

  // Lifestyle Compatibility (30% total weight)
  static const double weekendEnergy = 8.0;
  static const double socialStyle = 7.0;
  static const double musicIdentity = 5.0;
  static const double lifestyleHabits = 10.0; // smoking/drinking/cannabis

  // Communication & Personality (20% total weight)
  static const double communicationStyle = 7.0;
  static const double personalityTrait = 6.0;
  static const double loveLanguage = 7.0;

  // Preferences (10% total weight)
  static const double flirtingStyle = 3.0;
  static const double icebreakerType = 2.0;
  static const double favoritePrompt = 2.0;
  static const double petsKidsPreference = 3.0;

  /// Get total weight sum (should equal 100)
  static double get totalWeight {
    return relationshipIntent +
        partnerVibe +
        connectionStyle +
        attractionTrigger +
        weekendEnergy +
        socialStyle +
        musicIdentity +
        lifestyleHabits +
        communicationStyle +
        personalityTrait +
        loveLanguage +
        flirtingStyle +
        icebreakerType +
        favoritePrompt +
        petsKidsPreference;
  }

  /// Validate that weights sum to approximately 100
  static bool validateWeights() {
    final total = totalWeight;
    return (total >= 99.0 && total <= 101.0);
  }

  /// Get category weights map
  static Map<String, double> get categoryWeights => {
        'relationshipIntent': relationshipIntent,
        'partnerVibe': partnerVibe,
        'connectionStyle': connectionStyle,
        'attractionTrigger': attractionTrigger,
        'weekendEnergy': weekendEnergy,
        'socialStyle': socialStyle,
        'musicIdentity': musicIdentity,
        'lifestyleHabits': lifestyleHabits,
        'communicationStyle': communicationStyle,
        'personalityTrait': personalityTrait,
        'loveLanguage': loveLanguage,
        'flirtingStyle': flirtingStyle,
        'icebreakerType': icebreakerType,
        'favoritePrompt': favoritePrompt,
        'petsKidsPreference': petsKidsPreference,
      };

  /// Get weights grouped by importance
  static Map<String, List<String>> get weightsByImportance => {
        'critical': ['relationshipIntent', 'dealbreaker'],
        'high': [
          'partnerVibe',
          'connectionStyle',
          'attractionTrigger',
          'lifestyleHabits'
        ],
        'medium': [
          'weekendEnergy',
          'socialStyle',
          'communicationStyle',
          'loveLanguage',
          'personalityTrait'
        ],
        'low': [
          'musicIdentity',
          'flirtingStyle',
          'icebreakerType',
          'favoritePrompt',
          'petsKidsPreference'
        ],
      };
}

/// Scoring utilities for the matching algorithm
class MatchingScoringUtils {
  /// Calculate similarity score between two enum values (0-100)
  static double enumSimilarity<T>(T? value1, T? value2) {
    if (value1 == null || value2 == null) return 50.0; // Neutral for missing
    return value1 == value2 ? 100.0 : 0.0;
  }

  /// Calculate compatibility for complementary traits (e.g., introvert + extrovert)
  static double complementaryScore<T>(
    T? value1,
    T? value2,
    Map<T, List<T>> complementaryMap,
  ) {
    if (value1 == null || value2 == null) return 50.0;
    if (value1 == value2) return 100.0; // Perfect match
    if (complementaryMap[value1]?.contains(value2) ?? false) {
      return 80.0; // Good complementary match
    }
    return 30.0; // Poor match
  }

  /// Calculate partial match for multi-value fields
  static double partialMatchScore(
    List<dynamic> list1,
    List<dynamic> list2,
  ) {
    if (list1.isEmpty || list2.isEmpty) return 50.0;

    final intersection = list1.where((item) => list2.contains(item)).length;
    final union = {...list1, ...list2}.length;

    if (union == 0) return 50.0;
    return (intersection / union) * 100.0;
  }

  /// Normalize score to 0-100 range
  static double normalizeScore(double score) {
    return score.clamp(0.0, 100.0);
  }

  /// Apply weight to a score
  static double applyWeight(double score, double weight) {
    return (score / 100.0) * weight;
  }

  /// Calculate weighted average from multiple scores
  static double weightedAverage(Map<double, double> scoreWeightPairs) {
    double totalWeightedScore = 0.0;
    double totalWeight = 0.0;

    scoreWeightPairs.forEach((score, weight) {
      totalWeightedScore += applyWeight(score, weight);
      totalWeight += weight;
    });

    if (totalWeight == 0) return 0.0;
    return (totalWeightedScore / totalWeight) * 100.0;
  }

  /// Check if dealbreaker is violated
  static bool isDealbreaker(
    String dealbreaker,
    Map<String, dynamic> user1Data,
    Map<String, dynamic> user2Data,
  ) {
    // Example dealbreaker logic
    switch (dealbreaker.toLowerCase()) {
      case 'smoking':
        return user2Data['smokingPreference'] == 'regularly';
      case 'dishonesty':
        // Would check user behavior patterns
        return false;
      case 'differentvalues':
        return user1Data['relationshipIntent'] !=
            user2Data['relationshipIntent'];
      default:
        return false;
    }
  }

  /// Calculate distance penalty (reduces score based on distance)
  static double distancePenalty(double distanceInMiles, double maxDistance) {
    if (distanceInMiles > maxDistance) return 0.0;
    if (maxDistance == 0) return 100.0;

    final ratio = distanceInMiles / maxDistance;
    return (1 - ratio) * 100.0;
  }

  /// Calculate age compatibility score
  static double ageCompatibilityScore(
    int age1,
    int age2,
    int minAge,
    int maxAge,
  ) {
    if (age2 < minAge || age2 > maxAge) return 0.0;

    // Perfect score for exact match
    if (age1 == age2) return 100.0;

    // Calculate how far from ideal (assuming ideal is same age)
    final ageDifference = (age1 - age2).abs();
    final maxDifference = (maxAge - minAge) / 2;

    if (maxDifference == 0) return 100.0;

    final score = 100.0 - ((ageDifference / maxDifference) * 30.0);
    return normalizeScore(score);
  }
}


