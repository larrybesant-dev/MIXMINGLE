/// Roadmap Dashboard Widget
///
/// Displays upcoming features, priorities, and timelines
/// for the platform roadmap.
library;

import 'package:flutter/material.dart';

import 'roadmap_service.dart';

/// Dashboard displaying the platform roadmap
class RoadmapDashboard extends StatefulWidget {
  const RoadmapDashboard({super.key});

  @override
  State<RoadmapDashboard> createState() => _RoadmapDashboardState();
}

class _RoadmapDashboardState extends State<RoadmapDashboard>
    with SingleTickerProviderStateMixin {
  final RoadmapService _roadmapService = RoadmapService.instance;

  late TabController _tabController;

  Roadmap? _currentRoadmap;
  List<RankedFeature> _impactRanked = [];
  List<RankedFeature> _effortRanked = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadRoadmapData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadRoadmapData() async {
    setState(() => _isLoading = true);

    try {
      final results = await Future.wait([
        _roadmapService.getLatestRoadmap(),
        _roadmapService.rankByImpact(limit: 10),
        _roadmapService.rankByEffort(limit: 10),
      ]);

      if (mounted) {
        setState(() {
          _currentRoadmap = results[0] as Roadmap?;
          _impactRanked = results[1] as List<RankedFeature>;
          _effortRanked = results[2] as List<RankedFeature>;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('❌ [RoadmapDashboard] Failed to load data: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Platform Roadmap'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadRoadmapData,
            tooltip: 'Refresh roadmap',
          ),
          IconButton(
            icon: const Icon(Icons.auto_awesome),
            onPressed: _generateNewRoadmap,
            tooltip: 'Generate new roadmap',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.timeline), text: 'Timeline'),
            Tab(icon: Icon(Icons.trending_up), text: 'Impact'),
            Tab(icon: Icon(Icons.speed), text: 'Quick Wins'),
            Tab(icon: Icon(Icons.lightbulb), text: 'Ideas'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildTimelineView(),
                _buildImpactView(),
                _buildQuickWinsView(),
                _buildIdeasView(),
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showSubmitFeatureDialog,
        icon: const Icon(Icons.add),
        label: const Text('Request Feature'),
      ),
    );
  }

  // ============================================================
  // TIMELINE VIEW
  // ============================================================

  Widget _buildTimelineView() {
    if (_currentRoadmap == null || _currentRoadmap!.quarters.isEmpty) {
      return _buildEmptyState(
        icon: Icons.timeline,
        title: 'No Roadmap Yet',
        subtitle: 'Generate a roadmap to see the timeline',
        actionLabel: 'Generate Roadmap',
        onAction: _generateNewRoadmap,
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _currentRoadmap!.quarters.length,
      itemBuilder: (context, index) {
        final quarter = _currentRoadmap!.quarters[index];
        return _buildQuarterCard(quarter, isFirst: index == 0);
      },
    );
  }

  Widget _buildQuarterCard(RoadmapQuarter quarter, {bool isFirst = false}) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Quarter header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isFirst
                  ? Theme.of(context).colorScheme.primaryContainer
                  : Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                if (isFirst)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    margin: const EdgeInsets.only(right: 8),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      'CURRENT',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                Text(
                  quarter.label,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Text(
                  '${quarter.features.length} features',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),

          // Theme
          if (quarter.theme != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Row(
                children: [
                  const Icon(Icons.stars, size: 16),
                  const SizedBox(width: 8),
                  Text(
                    quarter.theme!.name,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),

          // Features
          if (quarter.features.isEmpty)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text('No features planned yet'),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.all(8),
              itemCount: quarter.features.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final feature = quarter.features[index];
                return _buildFeatureListTile(feature);
              },
            ),
        ],
      ),
    );
  }

  Widget _buildFeatureListTile(RankedFeature feature) {
    return ListTile(
      leading: _buildCategoryIcon(feature.request.category),
      title: Text(feature.request.title),
      subtitle: Row(
        children: [
          _buildScoreBadge(
            'Impact',
            feature.impactScore,
            Colors.green,
          ),
          const SizedBox(width: 8),
          _buildScoreBadge(
            'Effort',
            feature.effortScore,
            Colors.orange,
          ),
        ],
      ),
      trailing: _buildStatusChip(feature.request.status),
      onTap: () => _showFeatureDetails(feature),
    );
  }

  Widget _buildCategoryIcon(FeatureCategory category) {
    final iconData = switch (category) {
      FeatureCategory.ui => Icons.palette,
      FeatureCategory.performance => Icons.speed,
      FeatureCategory.video => Icons.videocam,
      FeatureCategory.chat => Icons.chat,
      FeatureCategory.monetization => Icons.attach_money,
      FeatureCategory.moderation => Icons.shield,
      FeatureCategory.social => Icons.people,
      FeatureCategory.accessibility => Icons.accessibility,
      FeatureCategory.integration => Icons.extension,
      FeatureCategory.mobile => Icons.phone_android,
      FeatureCategory.web => Icons.web,
      FeatureCategory.creator => Icons.star,
    };

    return CircleAvatar(
      radius: 18,
      backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Icon(iconData, size: 18),
    );
  }

  Widget _buildScoreBadge(String label, double score, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        '$label: ${score.toStringAsFixed(1)}',
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildStatusChip(RequestStatus status) {
    final (color, label) = switch (status) {
      RequestStatus.submitted => (Colors.grey, 'New'),
      RequestStatus.underReview => (Colors.blue, 'Review'),
      RequestStatus.planned => (Colors.purple, 'Planned'),
      RequestStatus.inProgress => (Colors.orange, 'In Progress'),
      RequestStatus.completed => (Colors.green, 'Done'),
      RequestStatus.declined => (Colors.red, 'Declined'),
      RequestStatus.deferred => (Colors.grey, 'Deferred'),
    };

    return Chip(
      label: Text(
        label,
        style: TextStyle(color: color, fontSize: 10),
      ),
      backgroundColor: color.withValues(alpha: 0.1),
      padding: EdgeInsets.zero,
      visualDensity: VisualDensity.compact,
    );
  }

  // ============================================================
  // IMPACT VIEW
  // ============================================================

  Widget _buildImpactView() {
    if (_impactRanked.isEmpty) {
      return _buildEmptyState(
        icon: Icons.trending_up,
        title: 'No Features Ranked',
        subtitle: 'Submit feature requests to see impact rankings',
        actionLabel: 'Request Feature',
        onAction: _showSubmitFeatureDialog,
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _impactRanked.length,
      itemBuilder: (context, index) {
        final feature = _impactRanked[index];
        return _buildRankedFeatureCard(
          feature,
          rank: index + 1,
          primaryMetric: 'Impact',
          primaryValue: feature.impactScore,
        );
      },
    );
  }

  Widget _buildRankedFeatureCard(
    RankedFeature feature, {
    required int rank,
    required String primaryMetric,
    required double primaryValue,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            // Rank badge
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: rank <= 3
                    ? Theme.of(context).colorScheme.primaryContainer
                    : Theme.of(context).colorScheme.surfaceContainerHighest,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  '#$rank',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: rank <= 3
                        ? Theme.of(context).colorScheme.primary
                        : null,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),

            // Feature info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    feature.request.title,
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      _buildCategoryChip(feature.request.category),
                      const SizedBox(width: 8),
                      Icon(
                        Icons.thumb_up,
                        size: 12,
                        color: Theme.of(context).colorScheme.outline,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${feature.communityVotes}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Primary metric
            Column(
              children: [
                Text(
                  primaryValue.toStringAsFixed(1),
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                Text(
                  primaryMetric,
                  style: Theme.of(context).textTheme.labelSmall,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryChip(FeatureCategory category) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        category.name.toUpperCase(),
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.w600,
          color: Theme.of(context).colorScheme.outline,
        ),
      ),
    );
  }

  // ============================================================
  // QUICK WINS VIEW
  // ============================================================

  Widget _buildQuickWinsView() {
    if (_effortRanked.isEmpty) {
      return _buildEmptyState(
        icon: Icons.speed,
        title: 'No Quick Wins',
        subtitle: 'Submit feature requests to see quick win opportunities',
        actionLabel: 'Request Feature',
        onAction: _showSubmitFeatureDialog,
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _effortRanked.length,
      itemBuilder: (context, index) {
        final feature = _effortRanked[index];
        return _buildRankedFeatureCard(
          feature,
          rank: index + 1,
          primaryMetric: 'Effort',
          primaryValue: feature.effortScore,
        );
      },
    );
  }

  // ============================================================
  // IDEAS VIEW
  // ============================================================

  Widget _buildIdeasView() {
    return FutureBuilder<List<FeatureRequest>>(
      future: _roadmapService.getFeaturesByStatus(RequestStatus.submitted),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final ideas = snapshot.data ?? [];

        if (ideas.isEmpty) {
          return _buildEmptyState(
            icon: Icons.lightbulb,
            title: 'No Ideas Yet',
            subtitle: 'Be the first to submit a feature request!',
            actionLabel: 'Submit Idea',
            onAction: _showSubmitFeatureDialog,
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: ideas.length,
          itemBuilder: (context, index) {
            final idea = ideas[index];
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: ListTile(
                leading: _buildCategoryIcon(idea.category),
                title: Text(idea.title),
                subtitle: Text(
                  idea.description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.thumb_up_outlined),
                      onPressed: () => _voteFeature(idea.id, upvote: true),
                    ),
                    Text('${idea.upvotes}'),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // ============================================================
  // HELPER WIDGETS
  // ============================================================

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
    required String actionLabel,
    required VoidCallback onAction,
  }) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 64, color: Theme.of(context).colorScheme.outline),
          const SizedBox(height: 16),
          Text(title, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.outline,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: onAction,
            icon: const Icon(Icons.add),
            label: Text(actionLabel),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // ACTIONS
  // ============================================================

  Future<void> _generateNewRoadmap() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        content: Row(
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 16),
            Text('Generating roadmap...'),
          ],
        ),
      ),
    );

    try {
      final roadmap = await _roadmapService.autoGenerateRoadmap();
      if (mounted) {
        Navigator.pop(context);
        setState(() => _currentRoadmap = roadmap);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Roadmap generated successfully!')),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to generate roadmap: $e')),
        );
      }
    }
  }

  Future<void> _showSubmitFeatureDialog() async {
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Request a Feature'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              decoration: const InputDecoration(
                labelText: 'Feature Title',
                hintText: 'What would you like to see?',
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description',
                hintText: 'Describe the feature in detail...',
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Submit'),
          ),
        ],
      ),
    );

    if (result == true && titleController.text.isNotEmpty) {
      try {
        await _roadmapService.collectFeatureRequests(
          title: titleController.text,
          description: descriptionController.text,
          requestedBy: 'current_user', // Replace with actual user ID
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Feature request submitted!')),
          );
          _loadRoadmapData();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to submit: $e')),
          );
        }
      }
    }

    titleController.dispose();
    descriptionController.dispose();
  }

  Future<void> _showFeatureDetails(RankedFeature feature) async {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) => SingleChildScrollView(
          controller: scrollController,
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  _buildCategoryIcon(feature.request.category),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      feature.request.title,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Status
              _buildStatusChip(feature.request.status),
              const SizedBox(height: 16),

              // Description
              Text(
                feature.request.description,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 24),

              // Scores
              Text(
                'Analysis',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 12),
              _buildScoreRow('Impact Score', feature.impactScore, 10),
              _buildScoreRow('Effort Score', feature.effortScore, 10),
              _buildScoreRow('Priority Score', feature.priorityScore, 10),
              _buildScoreRow(
                'Community Votes',
                feature.communityVotes.toDouble(),
                100,
              ),

              // Reasons
              if (feature.reasons.isNotEmpty) ...[
                const SizedBox(height: 24),
                Text(
                  'Reasoning',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 12),
                ...feature.reasons.map((reason) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle, size: 16),
                      const SizedBox(width: 8),
                      Expanded(child: Text(reason)),
                    ],
                  ),
                )),
              ],
              const SizedBox(height: 24),

              // Tags
              if (feature.request.tags.isNotEmpty) ...[
                Text(
                  'Tags',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: feature.request.tags
                      .map((tag) => Chip(label: Text(tag)))
                      .toList(),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildScoreRow(String label, double value, double max) {
    final percentage = (value / max).clamp(0.0, 1.0);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label),
              Text(value.toStringAsFixed(1)),
            ],
          ),
          const SizedBox(height: 4),
          LinearProgressIndicator(
            value: percentage,
            backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
          ),
        ],
      ),
    );
  }

  Future<void> _voteFeature(String featureId, {required bool upvote}) async {
    final success = await _roadmapService.voteFeature(featureId, upvote: upvote);
    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Vote recorded!')),
        );
        _loadRoadmapData();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to vote')),
        );
      }
    }
  }
}
