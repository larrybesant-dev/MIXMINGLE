import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/questionnaire_answers.dart';
import '../models/matching_profile.dart';
import '../providers/matching_providers.dart';

/// Example usage of the matching system
class MatchingExample extends ConsumerWidget {
  const MatchingExample({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final matchesAsync = ref.watch(topMatchesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Matches'),
        actions: [
          IconButton(
            icon: const Icon(Icons.tune),
            onPressed: () => _showFilterDialog(context, ref),
          ),
        ],
      ),
      body: matchesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('Error: $error')),
        data: (matches) {
          if (matches.isEmpty) {
            return const Center(
              child: Text('No matches found. Try adjusting your filters.'),
            );
          }

          return ListView.builder(
            itemCount: matches.length,
            itemBuilder: (context, index) {
              final match = matches[index];
              return _MatchCard(match: match);
            },
          );
        },
      ),
    );
  }

  void _showFilterDialog(BuildContext context, WidgetRef ref) {
    final currentFilter = ref.read(matchFilterProvider);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Match Filters'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Min Score: ${currentFilter.minScore.toInt()}'),
            Slider(
              value: currentFilter.minScore,
              min: 0,
              max: 100,
              divisions: 10,
              onChanged: (value) {
                ref.read(matchFilterProvider.notifier).updateFilter(currentFilter.copyWith(minScore: value));
              },
            ),
            Text('Max Distance: ${currentFilter.maxDistance.toInt()} miles'),
            Slider(
              value: currentFilter.maxDistance,
              min: 5,
              max: 100,
              divisions: 19,
              onChanged: (value) {
                ref.read(matchFilterProvider.notifier).updateFilter(currentFilter.copyWith(maxDistance: value));
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }
}

class _MatchCard extends ConsumerWidget {
  final dynamic match;

  const _MatchCard({required this.match});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final score = match.matchScore;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: InkWell(
        onTap: () => _showMatchDetails(context, match),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundImage: match.userPhotoUrl != null ? NetworkImage(match.userPhotoUrl!) : null,
                    child: match.userPhotoUrl == null ? Text(match.userName[0]) : null,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          match.userName,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '${match.age} years old • ${match.distanceInMiles.toStringAsFixed(1)} miles away',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  ),
                  _buildScoreBadge(score.overallScore),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                score.compatibilityLevel,
                style: TextStyle(
                  color: _getScoreColor(score.overallScore),
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (score.topReasons.isNotEmpty) ...[
                const SizedBox(height: 8),
                ...score.topReasons.map(
                  (reason) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      children: [
                        const Icon(Icons.check_circle, size: 16, color: Colors.green),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            reason,
                            style: const TextStyle(fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildScoreBadge(double score) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: _getScoreColor(score),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        '${score.toInt()}%',
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Color _getScoreColor(double score) {
    if (score >= 80) return Colors.green;
    if (score >= 60) return Colors.orange;
    return Colors.red;
  }

  void _showMatchDetails(BuildContext context, dynamic match) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        builder: (context, scrollController) {
          return _MatchDetailsSheet(
            match: match,
            scrollController: scrollController,
          );
        },
      ),
    );
  }
}

class _MatchDetailsSheet extends StatelessWidget {
  final dynamic match;
  final ScrollController scrollController;

  const _MatchDetailsSheet({
    required this.match,
    required this.scrollController,
  });

  @override
  Widget build(BuildContext context) {
    final score = match.matchScore;

    return Container(
      padding: const EdgeInsets.all(24),
      child: ListView(
        controller: scrollController,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            match.userName,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            score.compatibilityLevel,
            style: TextStyle(
              fontSize: 18,
              color: _getScoreColor(score.overallScore),
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          _buildSection(
            'Compatibility Breakdown',
            Icons.analytics,
            _buildCategoryScores(score.categoryScores),
          ),
          if (score.sharedInterests.isNotEmpty)
            _buildSection(
              'Shared Interests',
              Icons.favorite,
              _buildChips(score.sharedInterests, Colors.pink),
            ),
          if (score.compatibilityReasons.isNotEmpty)
            _buildSection(
              'Why You Match',
              Icons.check_circle,
              _buildReasonsList(score.compatibilityReasons),
            ),
          if (score.potentialChallenges.isNotEmpty)
            _buildSection(
              'Things to Know',
              Icons.info_outline,
              _buildReasonsList(score.potentialChallenges),
            ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.close),
                  label: const Text('Pass'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.favorite),
                  label: const Text('Like'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.pink,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSection(String title, IconData icon, Widget content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        Row(
          children: [
            Icon(icon, size: 20),
            const SizedBox(width: 8),
            Text(
              title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const SizedBox(height: 12),
        content,
      ],
    );
  }

  Widget _buildCategoryScores(Map<String, double> scores) {
    return Column(
      children: scores.entries.map((entry) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(_formatCategoryName(entry.key)),
                  Text(
                    '${entry.value.toInt()}%',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              LinearProgressIndicator(
                value: entry.value / 100,
                backgroundColor: Colors.grey[200],
                valueColor: AlwaysStoppedAnimation(_getScoreColor(entry.value)),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildChips(List<String> items, Color color) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: items.map((item) {
        return Chip(
          label: Text(item),
          backgroundColor: color.withValues(alpha: 0.1),
          labelStyle: TextStyle(color: color),
        );
      }).toList(),
    );
  }

  Widget _buildReasonsList(List<String> reasons) {
    return Column(
      children: reasons.map((reason) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('•  '),
              Expanded(child: Text(reason)),
            ],
          ),
        );
      }).toList(),
    );
  }

  String _formatCategoryName(String name) {
    return name
        .replaceAllMapped(
          RegExp(r'([A-Z])'),
          (match) => ' ${match.group(0)}',
        )
        .trim()
        .split(' ')
        .map((word) => word[0].toUpperCase() + word.substring(1))
        .join(' ');
  }

  Color _getScoreColor(double score) {
    if (score >= 80) return Colors.green;
    if (score >= 60) return Colors.orange;
    return Colors.red;
  }
}

/// Example: Creating a matching profile
MatchingProfile createExampleProfile() {
  return MatchingProfile(
    userId: 'user123',
    displayName: 'Alex Johnson',
    photoUrl: 'https://example.com/photo.jpg',
    age: 28,
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
      minAge: 25,
      maxAge: 35,
      preferredGenders: [PreferredGender.everyone],
      distancePreference: DistancePreference.within25Miles,
      smokingPreference: SmokingPreference.never,
      drinkingPreference: DrinkingPreference.socially,
      cannabisPreference: CannabisPreference.never,
      petsPreference: PetsPreference.loveBoth,
      kidsPreference: KidsPreference.wantKids,
    ),
    lastActive: DateTime.now(),
    createdAt: DateTime.now(),
  );
}
