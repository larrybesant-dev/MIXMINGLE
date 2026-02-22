/// Roadmap Service
///
/// Manages feature requests, prioritization, and automatic
/// roadmap generation based on impact and effort analysis.
library;

import 'dart:async';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../analytics/analytics_service.dart';
import '../autonomy/community_ai_service.dart';

/// Feature request
class FeatureRequest {
  final String id;
  final String title;
  final String description;
  final String requestedBy;
  final FeatureCategory category;
  final RequestStatus status;
  final int upvotes;
  final int downvotes;
  final List<String> tags;
  final List<FeatureComment> comments;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final DateTime? completedAt;

  const FeatureRequest({
    required this.id,
    required this.title,
    required this.description,
    required this.requestedBy,
    required this.category,
    required this.status,
    this.upvotes = 0,
    this.downvotes = 0,
    this.tags = const [],
    this.comments = const [],
    required this.createdAt,
    this.updatedAt,
    this.completedAt,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'title': title,
    'description': description,
    'requestedBy': requestedBy,
    'category': category.name,
    'status': status.name,
    'upvotes': upvotes,
    'downvotes': downvotes,
    'tags': tags,
    'comments': comments.map((c) => c.toMap()).toList(),
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt?.toIso8601String(),
    'completedAt': completedAt?.toIso8601String(),
  };

  FeatureRequest copyWith({
    String? id,
    String? title,
    String? description,
    String? requestedBy,
    FeatureCategory? category,
    RequestStatus? status,
    int? upvotes,
    int? downvotes,
    List<String>? tags,
    List<FeatureComment>? comments,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? completedAt,
  }) {
    return FeatureRequest(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      requestedBy: requestedBy ?? this.requestedBy,
      category: category ?? this.category,
      status: status ?? this.status,
      upvotes: upvotes ?? this.upvotes,
      downvotes: downvotes ?? this.downvotes,
      tags: tags ?? this.tags,
      comments: comments ?? this.comments,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      completedAt: completedAt ?? this.completedAt,
    );
  }

  double get score => upvotes - downvotes * 0.5;
}

/// Feature categories
enum FeatureCategory {
  ui,
  performance,
  video,
  chat,
  monetization,
  moderation,
  social,
  accessibility,
  integration,
  mobile,
  web,
  creator,
}

/// Request status
enum RequestStatus {
  submitted,
  underReview,
  planned,
  inProgress,
  completed,
  declined,
  deferred,
}

/// Feature comment
class FeatureComment {
  final String id;
  final String userId;
  final String content;
  final DateTime createdAt;

  const FeatureComment({
    required this.id,
    required this.userId,
    required this.content,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'userId': userId,
    'content': content,
    'createdAt': createdAt.toIso8601String(),
  };
}

/// Ranked feature with scores
class RankedFeature {
  final FeatureRequest request;
  final double impactScore;
  final double effortScore;
  final double priorityScore;
  final int communityVotes;
  final List<String> reasons;
  final RoadmapQuarter? targetQuarter;

  const RankedFeature({
    required this.request,
    required this.impactScore,
    required this.effortScore,
    required this.priorityScore,
    required this.communityVotes,
    this.reasons = const [],
    this.targetQuarter,
  });

  Map<String, dynamic> toMap() => {
    'request': request.toMap(),
    'impactScore': impactScore,
    'effortScore': effortScore,
    'priorityScore': priorityScore,
    'communityVotes': communityVotes,
    'reasons': reasons,
    'targetQuarter': targetQuarter?.toMap(),
  };
}

/// Roadmap quarter
class RoadmapQuarter {
  final int year;
  final int quarter;
  final List<RankedFeature> features;
  final RoadmapTheme? theme;

  const RoadmapQuarter({
    required this.year,
    required this.quarter,
    this.features = const [],
    this.theme,
  });

  String get label => 'Q$quarter $year';

  Map<String, dynamic> toMap() => {
    'year': year,
    'quarter': quarter,
    'features': features.map((f) => f.toMap()).toList(),
    'theme': theme?.toMap(),
  };
}

/// Roadmap theme
class RoadmapTheme {
  final String name;
  final String description;
  final List<FeatureCategory> focusAreas;

  const RoadmapTheme({
    required this.name,
    required this.description,
    this.focusAreas = const [],
  });

  Map<String, dynamic> toMap() => {
    'name': name,
    'description': description,
    'focusAreas': focusAreas.map((f) => f.name).toList(),
  };
}

/// Generated roadmap
class Roadmap {
  final String id;
  final String version;
  final List<RoadmapQuarter> quarters;
  final DateTime generatedAt;
  final Map<String, dynamic> metadata;

  const Roadmap({
    required this.id,
    required this.version,
    required this.quarters,
    required this.generatedAt,
    this.metadata = const {},
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'version': version,
    'quarters': quarters.map((q) => q.toMap()).toList(),
    'generatedAt': generatedAt.toIso8601String(),
    'metadata': metadata,
  };
}

/// Roadmap service for feature prioritization and planning
class RoadmapService {
  static RoadmapService? _instance;
  static RoadmapService get instance => _instance ??= RoadmapService._();

  RoadmapService._();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final CommunityAIService _communityAI = CommunityAIService.instance;
  final _random = Random();

  // Stream controllers
  final _featureController = StreamController<FeatureRequest>.broadcast();
  final _roadmapController = StreamController<Roadmap>.broadcast();

  Stream<FeatureRequest> get featureStream => _featureController.stream;
  Stream<Roadmap> get roadmapStream => _roadmapController.stream;

  // Collections
  CollectionReference<Map<String, dynamic>> get _featuresCollection =>
      _firestore.collection('feature_requests');

  CollectionReference<Map<String, dynamic>> get _roadmapsCollection =>
      _firestore.collection('roadmaps');

  // ============================================================
  // FEATURE REQUEST COLLECTION
  // ============================================================

  /// Collect and submit a new feature request
  Future<FeatureRequest> collectFeatureRequests({
    required String title,
    required String description,
    required String requestedBy,
    FeatureCategory? category,
    List<String>? tags,
  }) async {
    debugPrint('ðŸ“ [RoadmapService] Collecting feature request: $title');

    try {
      // Auto-categorize if not provided
      final detectedCategory = category ?? _detectCategory(title, description);

      // Auto-tag if not provided
      final detectedTags = tags ?? _detectTags(title, description);

      final request = FeatureRequest(
        id: 'feature_${DateTime.now().millisecondsSinceEpoch}_${_random.nextInt(10000)}',
        title: title,
        description: description,
        requestedBy: requestedBy,
        category: detectedCategory,
        status: RequestStatus.submitted,
        upvotes: 1, // Auto-upvote by submitter
        tags: detectedTags,
        createdAt: DateTime.now(),
      );

      // Store in Firestore
      await _featuresCollection.doc(request.id).set(request.toMap());

      // Emit event
      _featureController.add(request);

      // Track analytics
      AnalyticsService.instance.logEvent(name: 'feature_request', parameters: {
        'category': detectedCategory.name,
        'tags_count': detectedTags.length,
      });

      debugPrint('âœ… [RoadmapService] Feature request collected: ${request.id}');
      return request;
    } catch (e) {
      debugPrint('âŒ [RoadmapService] Failed to collect feature request: $e');
      rethrow;
    }
  }

  FeatureCategory _detectCategory(String title, String description) {
    final combined = '$title $description'.toLowerCase();

    if (combined.contains('video') || combined.contains('stream')) {
      return FeatureCategory.video;
    }
    if (combined.contains('chat') || combined.contains('message')) {
      return FeatureCategory.chat;
    }
    if (combined.contains('money') || combined.contains('pay') || combined.contains('subscribe')) {
      return FeatureCategory.monetization;
    }
    if (combined.contains('mobile') || combined.contains('app')) {
      return FeatureCategory.mobile;
    }
    if (combined.contains('creator') || combined.contains('host')) {
      return FeatureCategory.creator;
    }
    if (combined.contains('ui') || combined.contains('design') || combined.contains('look')) {
      return FeatureCategory.ui;
    }
    if (combined.contains('fast') || combined.contains('slow') || combined.contains('performance')) {
      return FeatureCategory.performance;
    }

    return FeatureCategory.social;
  }

  List<String> _detectTags(String title, String description) {
    final tags = <String>[];
    final combined = '$title $description'.toLowerCase();

    final tagKeywords = {
      'ux': ['user', 'experience', 'interface', 'design'],
      'performance': ['fast', 'slow', 'speed', 'performance', 'optimize'],
      'mobile': ['mobile', 'phone', 'ios', 'android'],
      'web': ['web', 'browser', 'chrome', 'firefox'],
      'accessibility': ['accessibility', 'a11y', 'screen reader', 'keyboard'],
      'creator': ['creator', 'host', 'streamer', 'broadcaster'],
      'viewer': ['viewer', 'audience', 'watcher'],
      'social': ['social', 'share', 'friend', 'follow'],
    };

    for (final entry in tagKeywords.entries) {
      for (final keyword in entry.value) {
        if (combined.contains(keyword)) {
          tags.add(entry.key);
          break;
        }
      }
    }

    return tags.toSet().toList();
  }

  /// Vote on a feature request
  Future<bool> voteFeature(String featureId, {required bool upvote}) async {
    try {
      await _featuresCollection.doc(featureId).update({
        if (upvote) 'upvotes': FieldValue.increment(1),
        if (!upvote) 'downvotes': FieldValue.increment(1),
        'updatedAt': DateTime.now().toIso8601String(),
      });
      return true;
    } catch (e) {
      debugPrint('âŒ [RoadmapService] Failed to vote: $e');
      return false;
    }
  }

  // ============================================================
  // IMPACT RANKING
  // ============================================================

  /// Rank features by impact score
  Future<List<RankedFeature>> rankByImpact({
    int limit = 20,
  }) async {
    debugPrint('ðŸ“Š [RoadmapService] Ranking features by impact');

    try {
      final features = await _getAllFeatures();
      final rankedFeatures = <RankedFeature>[];

      for (final feature in features) {
        final impactScore = _calculateImpactScore(feature);
        final effortScore = _estimateEffort(feature);
        final priorityScore = impactScore / effortScore;

        rankedFeatures.add(RankedFeature(
          request: feature,
          impactScore: impactScore,
          effortScore: effortScore,
          priorityScore: priorityScore,
          communityVotes: feature.upvotes - feature.downvotes,
          reasons: _generateImpactReasons(feature, impactScore),
        ));
      }

      // Sort by impact score
      rankedFeatures.sort((a, b) => b.impactScore.compareTo(a.impactScore));

      debugPrint('âœ… [RoadmapService] Ranked ${rankedFeatures.length} features by impact');
      return rankedFeatures.take(limit).toList();
    } catch (e) {
      debugPrint('âŒ [RoadmapService] Failed to rank by impact: $e');
      return [];
    }
  }

  double _calculateImpactScore(FeatureRequest feature) {
    double score = 0;

    // Community votes weight
    score += feature.score * 0.3;

    // Category impact weights
    final categoryWeights = {
      FeatureCategory.performance: 1.5,
      FeatureCategory.video: 1.4,
      FeatureCategory.monetization: 1.3,
      FeatureCategory.creator: 1.2,
      FeatureCategory.accessibility: 1.1,
    };
    score *= categoryWeights[feature.category] ?? 1.0;

    // Recency bonus
    final daysSinceCreation = DateTime.now().difference(feature.createdAt).inDays;
    if (daysSinceCreation < 30) {
      score *= 1.1;
    }

    // Comment engagement
    score += feature.comments.length * 2;

    return score.clamp(0, 100);
  }

  List<String> _generateImpactReasons(FeatureRequest feature, double impactScore) {
    final reasons = <String>[];

    if (feature.score > 50) {
      reasons.add('High community demand (${feature.upvotes} votes)');
    }

    if (feature.category == FeatureCategory.performance) {
      reasons.add('Performance improvements affect all users');
    }

    if (feature.category == FeatureCategory.creator) {
      reasons.add('Creator tools drive platform growth');
    }

    if (feature.tags.contains('accessibility')) {
      reasons.add('Improves accessibility for all users');
    }

    return reasons;
  }

  // ============================================================
  // EFFORT RANKING
  // ============================================================

  /// Rank features by effort score
  Future<List<RankedFeature>> rankByEffort({
    int limit = 20,
  }) async {
    debugPrint('ðŸ“Š [RoadmapService] Ranking features by effort');

    try {
      final features = await _getAllFeatures();
      final rankedFeatures = <RankedFeature>[];

      for (final feature in features) {
        final impactScore = _calculateImpactScore(feature);
        final effortScore = _estimateEffort(feature);
        final priorityScore = impactScore / effortScore;

        rankedFeatures.add(RankedFeature(
          request: feature,
          impactScore: impactScore,
          effortScore: effortScore,
          priorityScore: priorityScore,
          communityVotes: feature.upvotes - feature.downvotes,
          reasons: _generateEffortReasons(feature, effortScore),
        ));
      }

      // Sort by effort score (lowest first = quick wins)
      rankedFeatures.sort((a, b) => a.effortScore.compareTo(b.effortScore));

      debugPrint('âœ… [RoadmapService] Ranked ${rankedFeatures.length} features by effort');
      return rankedFeatures.take(limit).toList();
    } catch (e) {
      debugPrint('âŒ [RoadmapService] Failed to rank by effort: $e');
      return [];
    }
  }

  double _estimateEffort(FeatureRequest feature) {
    double effort = 3.0; // Base effort

    // Category effort multipliers
    final categoryEffort = {
      FeatureCategory.ui: 1.0,
      FeatureCategory.performance: 2.0,
      FeatureCategory.video: 2.5,
      FeatureCategory.integration: 2.0,
      FeatureCategory.monetization: 1.8,
      FeatureCategory.accessibility: 1.2,
    };
    effort *= categoryEffort[feature.category] ?? 1.5;

    // Description complexity
    final wordCount = feature.description.split(' ').length;
    if (wordCount > 100) effort *= 1.3;
    if (wordCount > 200) effort *= 1.5;

    // Tag complexity
    if (feature.tags.contains('mobile') && feature.tags.contains('web')) {
      effort *= 1.4; // Multi-platform
    }

    return effort.clamp(1, 10);
  }

  List<String> _generateEffortReasons(FeatureRequest feature, double effortScore) {
    final reasons = <String>[];

    if (effortScore <= 3) {
      reasons.add('Quick win - can be implemented in 1-2 sprints');
    } else if (effortScore <= 5) {
      reasons.add('Medium effort - requires 3-4 sprints');
    } else {
      reasons.add('Large effort - requires dedicated team');
    }

    if (feature.category == FeatureCategory.video) {
      reasons.add('Video features require infrastructure changes');
    }

    if (feature.tags.contains('mobile') && feature.tags.contains('web')) {
      reasons.add('Multi-platform implementation required');
    }

    return reasons;
  }

  // ============================================================
  // AUTO-GENERATE ROADMAP
  // ============================================================

  /// Automatically generate a roadmap based on rankings
  Future<Roadmap> autoGenerateRoadmap({
    int quartersAhead = 4,
    int featuresPerQuarter = 5,
  }) async {
    debugPrint('ðŸ—ºï¸ [RoadmapService] Auto-generating roadmap');

    try {
      // Get all ranked features
      final allFeatures = await _getAllFeatures();
      final rankedFeatures = <RankedFeature>[];

      for (final feature in allFeatures) {
        if (feature.status == RequestStatus.declined ||
            feature.status == RequestStatus.completed) {
          continue;
        }

        final impactScore = _calculateImpactScore(feature);
        final effortScore = _estimateEffort(feature);
        final priorityScore = impactScore / effortScore;

        rankedFeatures.add(RankedFeature(
          request: feature,
          impactScore: impactScore,
          effortScore: effortScore,
          priorityScore: priorityScore,
          communityVotes: feature.upvotes - feature.downvotes,
        ));
      }

      // Sort by priority score
      rankedFeatures.sort((a, b) => b.priorityScore.compareTo(a.priorityScore));

      // Get AI recommendations
      final aiRecommendations = await _communityAI.autoRecommendFeatures();

      // Generate quarters
      final quarters = <RoadmapQuarter>[];
      final now = DateTime.now();
      var currentQuarter = ((now.month - 1) ~/ 3) + 1;
      var currentYear = now.year;

      var featureIndex = 0;

      for (var q = 0; q < quartersAhead; q++) {
        // Move to next quarter
        currentQuarter++;
        if (currentQuarter > 4) {
          currentQuarter = 1;
          currentYear++;
        }

        // Select features for this quarter
        final quarterFeatures = <RankedFeature>[];
        final theme = _determineQuarterTheme(q, rankedFeatures);

        // Add top priority features
        while (quarterFeatures.length < featuresPerQuarter &&
               featureIndex < rankedFeatures.length) {
          final feature = rankedFeatures[featureIndex];
          quarterFeatures.add(RankedFeature(
            request: feature.request.copyWith(
              status: RequestStatus.planned,
            ),
            impactScore: feature.impactScore,
            effortScore: feature.effortScore,
            priorityScore: feature.priorityScore,
            communityVotes: feature.communityVotes,
            targetQuarter: RoadmapQuarter(
              year: currentYear,
              quarter: currentQuarter,
            ),
          ));
          featureIndex++;
        }

        quarters.add(RoadmapQuarter(
          year: currentYear,
          quarter: currentQuarter,
          features: quarterFeatures,
          theme: theme,
        ));
      }

      // Create roadmap
      final roadmap = Roadmap(
        id: 'roadmap_${DateTime.now().millisecondsSinceEpoch}',
        version: '1.0',
        quarters: quarters,
        generatedAt: DateTime.now(),
        metadata: {
          'totalFeatures': rankedFeatures.length,
          'plannedFeatures': featureIndex,
          'aiRecommendations': aiRecommendations.length,
        },
      );

      // Store roadmap
      await _roadmapsCollection.doc(roadmap.id).set(roadmap.toMap());

      // Emit event
      _roadmapController.add(roadmap);

      // Track analytics
      AnalyticsService.instance.logEvent(name: 'roadmap_generated', parameters: {
        'quarters': quartersAhead,
        'features': featureIndex,
      });

      debugPrint('âœ… [RoadmapService] Generated roadmap with $featureIndex features');
      return roadmap;
    } catch (e) {
      debugPrint('âŒ [RoadmapService] Failed to generate roadmap: $e');
      rethrow;
    }
  }

  RoadmapTheme _determineQuarterTheme(int quarterIndex, List<RankedFeature> features) {
    final themes = [
      const RoadmapTheme(
        name: 'Foundation & Performance',
        description: 'Building a solid, fast platform foundation',
        focusAreas: [FeatureCategory.performance, FeatureCategory.accessibility],
      ),
      const RoadmapTheme(
        name: 'Creator Empowerment',
        description: 'Tools and features for content creators',
        focusAreas: [FeatureCategory.creator, FeatureCategory.monetization],
      ),
      const RoadmapTheme(
        name: 'Community & Social',
        description: 'Enhanced social features and community building',
        focusAreas: [FeatureCategory.social, FeatureCategory.chat],
      ),
      const RoadmapTheme(
        name: 'Innovation & Growth',
        description: 'New experiences and platform expansion',
        focusAreas: [FeatureCategory.video, FeatureCategory.integration],
      ),
    ];

    return themes[quarterIndex % themes.length];
  }

  // ============================================================
  // UTILITY METHODS
  // ============================================================

  Future<List<FeatureRequest>> _getAllFeatures() async {
    final snapshot = await _featuresCollection
        .orderBy('createdAt', descending: true)
        .get();

    return snapshot.docs.map((doc) {
      final data = doc.data();
      return FeatureRequest(
        id: data['id'] as String,
        title: data['title'] as String,
        description: data['description'] as String,
        requestedBy: data['requestedBy'] as String,
        category: FeatureCategory.values.firstWhere(
          (c) => c.name == data['category'],
          orElse: () => FeatureCategory.social,
        ),
        status: RequestStatus.values.firstWhere(
          (s) => s.name == data['status'],
          orElse: () => RequestStatus.submitted,
        ),
        upvotes: data['upvotes'] as int? ?? 0,
        downvotes: data['downvotes'] as int? ?? 0,
        tags: List<String>.from(data['tags'] ?? []),
        comments: [],
        createdAt: DateTime.parse(data['createdAt'] as String),
        updatedAt: data['updatedAt'] != null
            ? DateTime.parse(data['updatedAt'] as String)
            : null,
        completedAt: data['completedAt'] != null
            ? DateTime.parse(data['completedAt'] as String)
            : null,
      );
    }).toList();
  }

  /// Get feature requests by status
  Future<List<FeatureRequest>> getFeaturesByStatus(RequestStatus status) async {
    final snapshot = await _featuresCollection
        .where('status', isEqualTo: status.name)
        .orderBy('createdAt', descending: true)
        .get();

    return snapshot.docs.map((doc) {
      final data = doc.data();
      return FeatureRequest(
        id: data['id'] as String,
        title: data['title'] as String,
        description: data['description'] as String,
        requestedBy: data['requestedBy'] as String,
        category: FeatureCategory.values.firstWhere(
          (c) => c.name == data['category'],
        ),
        status: status,
        upvotes: data['upvotes'] as int? ?? 0,
        downvotes: data['downvotes'] as int? ?? 0,
        tags: List<String>.from(data['tags'] ?? []),
        comments: [],
        createdAt: DateTime.parse(data['createdAt'] as String),
      );
    }).toList();
  }

  /// Get latest roadmap
  Future<Roadmap?> getLatestRoadmap() async {
    final snapshot = await _roadmapsCollection
        .orderBy('generatedAt', descending: true)
        .limit(1)
        .get();

    if (snapshot.docs.isEmpty) return null;

    final data = snapshot.docs.first.data();
    return Roadmap(
      id: data['id'] as String,
      version: data['version'] as String,
      quarters: [], // Would need full parsing
      generatedAt: DateTime.parse(data['generatedAt'] as String),
      metadata: (data['metadata'] as Map<String, dynamic>?) ?? {},
    );
  }

  /// Dispose resources
  void dispose() {
    _featureController.close();
    _roadmapController.close();
  }
}
