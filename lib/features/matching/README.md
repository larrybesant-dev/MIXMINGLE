# Mix & Mingle Matching System

## Overview

A complete, production-ready matching algorithm for the Mix & Mingle Flutter app that scores compatibility between users based on 19 questionnaire fields.

## Architecture

```
lib/features/matching/
├── models/
│   ├── questionnaire_answers.dart  # All 19 questionnaire enums & model
│   ├── matching_profile.dart       # Extended user profile for matching
│   ├── match_score.dart            # Match results & statistics
│   └── *.freezed.dart              # Generated Freezed files
├── services/
│   └── matching_service.dart       # Core matching algorithm
├── providers/
│   └── matching_providers.dart     # Riverpod state management
├── utils/
│   └── matching_weights.dart       # Weight configuration & utilities
└── examples/
    └── matching_example.dart       # UI example implementation
```

## Features

### ✅ Complete Question Coverage (19 Fields)

**Core Compatibility (40% weight)**
- Relationship Intent (15%)
- Partner Vibe (10%)
- Connection Style (8%)
- Attraction Trigger (7%)

**Lifestyle Compatibility (30% weight)**
- Weekend Energy (8%)
- Social Style (7%)
- Lifestyle Habits - smoking/drinking/cannabis (10%)
- Music Identity (5%)

**Communication & Personality (20% weight)**
- Communication Style (7%)
- Love Language (7%)
- Personality Trait (6%)

**Preferences (10% weight)**
- Pets/Kids Preference (3%)
- Flirting Style (3%)
- Icebreaker Type (2%)
- Favorite Prompt (2%)

**Filters**
- Age Range
- Preferred Genders
- Distance Preference

### ✅ Advanced Matching Features

- **Weighted Scoring**: Configurable weights for each category
- **Complementary Matching**: Some traits match better when complementary (e.g., introvert + ambivert)
- **Dealbreaker Detection**: Automatic filtering based on user dealbreakers
- **Distance Calculation**: Haversine formula for accurate distance
- **Normalized Scores**: All scores normalized to 0-100 range
- **Match Ranking**: Sorted list of best matches
- **Match Statistics**: Analytics on match quality distribution
- **Real-time Updates**: Stream providers for live match updates
- **Mutual Matching**: Detection of two-way likes

### ✅ Production Ready

- **Null Safety**: Full null-safe implementation
- **Error Handling**: Comprehensive try-catch blocks
- **Validation**: Input validation for all scores
- **Testing**: Unit tests for all scoring functions
- **Performance**: Efficient batch processing
- **Scalability**: Ready for large user bases

## Setup

### 1. Generate Freezed Files

```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

This will generate:
- `questionnaire_answers.freezed.dart`
- `questionnaire_answers.g.dart`
- `matching_profile.freezed.dart`
- `matching_profile.g.dart`
- `match_score.freezed.dart`
- `match_score.g.dart`

### 2. Run Tests

```bash
flutter test test/features/matching/matching_service_test.dart
```

### 3. Integration

Add to your app:

```dart
import 'package:mix_and_mingle/features/matching/providers/matching_providers.dart';

// In your widget
class MatchesScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final matchesAsync = ref.watch(topMatchesProvider);
    
    return matchesAsync.when(
      loading: () => CircularProgressIndicator(),
      error: (e, _) => Text('Error: $e'),
      data: (matches) => ListView.builder(
        itemCount: matches.length,
        itemBuilder: (context, index) {
          final match = matches[index];
          return ListTile(
            title: Text(match.userName),
            subtitle: Text('${match.matchScore.overallScore.toInt()}% Match'),
            trailing: Text(match.matchScore.compatibilityLevel),
          );
        },
      ),
    );
  }
}
```

## Usage Examples

### Calculate Match Score

```dart
final matchingService = ref.read(matchingServiceProvider);

final score = await matchingService.calculateMatchScore(
  currentUserProfile,
  otherUserProfile,
);

print('Overall Score: ${score.overallScore}');
print('Compatibility: ${score.compatibilityLevel}');
print('Shared Interests: ${score.sharedInterests}');
print('Reasons: ${score.compatibilityReasons}');
```

### Find Top Matches

```dart
final matches = await matchingService.findMatches(
  currentUserProfile,
  limit: 50,
  minScore: 60.0,
);

for (final match in matches) {
  print('#${match.rank}: ${match.userName} - ${match.matchScore.overallScore}%');
}
```

### Filter Matches

```dart
// Update filter settings
ref.read(matchFilterProvider.notifier).state = MatchesFilter(
  limit: 100,
  minScore: 70.0,
  maxDistance: 25.0,
);

// Matches will automatically update
final matches = ref.watch(topMatchesProvider);
```

### Get Match Statistics

```dart
final stats = await ref.read(matchStatisticsProvider.future);

print('Total Matches: ${stats.totalMatches}');
print('Strong Matches: ${stats.strongMatches}');
print('Average Score: ${stats.averageScore}');
print('Distribution: ${stats.compatibilityDistribution}');
```

## Algorithm Details

### Scoring Process

1. **Basic Compatibility Check**
   - Verify dealbreakers
   - Check age range
   - Validate distance preference
   - Confirm gender preferences

2. **Category Scoring**
   - Each category scored 0-100
   - Exact match = 100 points
   - Complementary match = 80 points (for compatible traits)
   - No match = 0 points
   - Missing data = 50 points (neutral)

3. **Weight Application**
   - Each score multiplied by category weight
   - Sum of weighted scores = overall score
   - Normalized to 0-100 range

4. **Result Generation**
   - Compatibility reasons extracted
   - Shared interests identified
   - Potential challenges noted
   - Match level determined

### Weight Configuration

Weights are defined in `matching_weights.dart` and can be dynamically adjusted:

```dart
class MatchingWeights {
  static const double relationshipIntent = 15.0;
  static const double partnerVibe = 10.0;
  // ... more weights
  
  // Total always equals 100.0
}
```

### Complementary Matching

Some traits work better when complementary rather than identical:

```dart
// Example: Social Style
Extrovert + Ambivert = 80% (good match)
Introvert + Ambivert = 80% (good match)
Extrovert + Introvert = 30% (potential conflict)
```

### Distance Calculation

Uses Haversine formula for accurate Earth-surface distance:

```dart
double distanceTo(MatchingProfile other) {
  // Haversine formula implementation
  // Returns distance in miles
}
```

## Database Schema

### Firestore Collection: `matching_profiles`

```json
{
  "userId": "user123",
  "displayName": "Alex Johnson",
  "photoUrl": "https://...",
  "age": 28,
  "latitude": 40.7128,
  "longitude": -74.0060,
  "answers": {
    "relationshipIntent": "seriousRelationship",
    "partnerVibe": "intellectual",
    "connectionStyle": "deepConversations",
    "weekendEnergy": "balancedMix",
    "musicIdentity": "indie",
    "socialStyle": "ambivert",
    "personalityTrait": "empathetic",
    "communicationStyle": "directHonest",
    "loveLanguage": "qualityTime",
    "attractionTrigger": "intelligence",
    "dealbreaker": "dishonesty",
    "flirtingStyle": "intellectualBanter",
    "icebreakerType": "deepPhilosophical",
    "favoritePrompt": "unpopularOpinion",
    "minAge": 25,
    "maxAge": 35,
    "preferredGenders": ["everyone"],
    "distancePreference": "within25Miles",
    "smokingPreference": "never",
    "drinkingPreference": "socially",
    "cannabisPreference": "never",
    "petsPreference": "loveBoth",
    "kidsPreference": "wantKids"
  },
  "isActive": true,
  "blockedUserIds": [],
  "likedUserIds": [],
  "passedUserIds": [],
  "lastActive": "2026-01-23T10:00:00Z",
  "createdAt": "2026-01-01T00:00:00Z"
}
```

## Testing

### Run All Tests

```bash
flutter test test/features/matching/
```

### Test Coverage

- ✅ Enum similarity scoring
- ✅ Complementary trait matching
- ✅ Weight application
- ✅ Score normalization
- ✅ Distance calculation
- ✅ Age compatibility
- ✅ Profile completeness
- ✅ Match score calculation
- ✅ Match finding
- ✅ Statistics generation

### Sample Test Data

See `matching_service_test.dart` for complete test profiles with all 19 fields populated.

## Performance Considerations

- **Batch Processing**: Process multiple matches in parallel
- **Caching**: Cache calculated scores for performance
- **Lazy Loading**: Load matches on-demand
- **Pagination**: Support for paginated results
- **Indexing**: Ensure Firestore indexes for efficient queries

## Firestore Indexes Required

```json
{
  "collectionGroup": "matching_profiles",
  "fields": [
    {"fieldPath": "isActive", "order": "ASCENDING"},
    {"fieldPath": "lastActive", "order": "DESCENDING"}
  ]
}
```

## Future Enhancements

- [ ] Machine learning score adjustments based on successful matches
- [ ] A/B testing for weight optimization
- [ ] Behavioral scoring (response time, message quality)
- [ ] Match explanation AI
- [ ] Video profile compatibility
- [ ] Social graph integration
- [ ] Match prediction confidence scores

## API Reference

### MatchingService

```dart
class MatchingService {
  Future<MatchScore> calculateMatchScore(profile1, profile2);
  Future<List<RankedMatch>> findMatches(profile, {limit, minScore});
  Future<MatchStatistics> calculateStatistics(profile);
}
```

### Providers

```dart
final matchingServiceProvider // Service instance
final currentMatchingProfileProvider // Current user's profile
final matchesProvider // Filtered matches
final matchStatisticsProvider // Match stats
final matchScoreProvider // Score with specific user
final topMatchesProvider // Top matches shortcut
final matchesStreamProvider // Real-time updates
final likedMatchesProvider // User's liked matches
final mutualMatchesProvider // Mutual likes
```

## Support

For questions or issues:
1. Check test files for usage examples
2. Review example UI implementation
3. Validate Firestore data structure
4. Ensure all Freezed files generated
5. Check weights sum to 100

## License

Part of Mix & Mingle app - Private/Proprietary
