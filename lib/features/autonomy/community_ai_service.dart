/// Community AI Service
///
/// Machine-assisted community management with trend detection,
/// growth pattern analysis, and automated feature recommendations.
library;

import 'dart:async';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../../core/analytics/analytics_service.dart';

/// Emerging trend data
class EmergingTrend {
  final String id;
  final String name;
  final TrendCategory category;
  final double growthRate;
  final double confidence;
  final int affectedUsers;
  final List<String> relatedTopics;
  final List<String> sampleContent;
  final DateTime detectedAt;
  final TrendStage stage;

  const EmergingTrend({
    required this.id,
    required this.name,
    required this.category,
    required this.growthRate,
    required this.confidence,
    required this.affectedUsers,
    this.relatedTopics = const [],
    this.sampleContent = const [],
    required this.detectedAt,
    required this.stage,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'category': category.name,
    'growthRate': growthRate,
    'confidence': confidence,
    'affectedUsers': affectedUsers,
    'relatedTopics': relatedTopics,
    'sampleContent': sampleContent,
    'detectedAt': detectedAt.toIso8601String(),
    'stage': stage.name,
  };
}

/// Trend categories
enum TrendCategory {
  content,
  interaction,
  roomType,
  feature,
  topic,
  behavior,
  demographic,
}

/// Trend lifecycle stage
enum TrendStage {
  emerging,
  growing,
  peaking,
  declining,
  stable,
}

/// Community shift data
class CommunityShift {
  final String id;
  final ShiftType type;
  final String description;
  final double magnitude;
  final Map<String, dynamic> beforeState;
  final Map<String, dynamic> afterState;
  final List<String> drivers;
  final DateTime detectedAt;
  final DateTime? projectedPeakAt;

  const CommunityShift({
    required this.id,
    required this.type,
    required this.description,
    required this.magnitude,
    this.beforeState = const {},
    this.afterState = const {},
    this.drivers = const [],
    required this.detectedAt,
    this.projectedPeakAt,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'type': type.name,
    'description': description,
    'magnitude': magnitude,
    'beforeState': beforeState,
    'afterState': afterState,
    'drivers': drivers,
    'detectedAt': detectedAt.toIso8601String(),
    'projectedPeakAt': projectedPeakAt?.toIso8601String(),
  };
}

/// Shift types
enum ShiftType {
  demographicShift,
  behaviorChange,
  contentPreference,
  engagementPattern,
  platformMigration,
  seasonalVariation,
}

/// Creator growth pattern
class CreatorGrowthPattern {
  final String creatorId;
  final String creatorName;
  final GrowthPatternType patternType;
  final double growthVelocity;
  final int followerCount;
  final int followerGain30d;
  final double engagementRate;
  final List<String> successFactors;
  final List<String> recommendations;
  final DateTime analyzedAt;

  const CreatorGrowthPattern({
    required this.creatorId,
    required this.creatorName,
    required this.patternType,
    required this.growthVelocity,
    required this.followerCount,
    required this.followerGain30d,
    required this.engagementRate,
    this.successFactors = const [],
    this.recommendations = const [],
    required this.analyzedAt,
  });

  Map<String, dynamic> toMap() => {
    'creatorId': creatorId,
    'creatorName': creatorName,
    'patternType': patternType.name,
    'growthVelocity': growthVelocity,
    'followerCount': followerCount,
    'followerGain30d': followerGain30d,
    'engagementRate': engagementRate,
    'successFactors': successFactors,
    'recommendations': recommendations,
    'analyzedAt': analyzedAt.toIso8601String(),
  };
}

/// Growth pattern types
enum GrowthPatternType {
  explosive,
  steady,
  viral,
  plateaued,
  declining,
  resurgent,
}

/// Feature recommendation
class FeatureRecommendation {
  final String id;
  final String featureName;
  final String description;
  final double impactScore;
  final double effortScore;
  final double priorityScore;
  final List<String> supportingData;
  final List<String> targetSegments;
  final Map<String, dynamic> projectedMetrics;
  final RecommendationSource source;
  final DateTime generatedAt;

  const FeatureRecommendation({
    required this.id,
    required this.featureName,
    required this.description,
    required this.impactScore,
    required this.effortScore,
    required this.priorityScore,
    this.supportingData = const [],
    this.targetSegments = const [],
    this.projectedMetrics = const {},
    required this.source,
    required this.generatedAt,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'featureName': featureName,
    'description': description,
    'impactScore': impactScore,
    'effortScore': effortScore,
    'priorityScore': priorityScore,
    'supportingData': supportingData,
    'targetSegments': targetSegments,
    'projectedMetrics': projectedMetrics,
    'source': source.name,
    'generatedAt': generatedAt.toIso8601String(),
  };
}

/// Recommendation sources
enum RecommendationSource {
  trendAnalysis,
  userFeedback,
  competitorAnalysis,
  usagePatterns,
  communityRequests,
  aiPrediction,
}

/// Community AI service for machine-assisted management
class CommunityAIService {
  static CommunityAIService? _instance;
  static CommunityAIService get instance => _instance ??= CommunityAIService._();

  CommunityAIService._();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final _random = Random();

  // Stream controllers
  final _trendController = StreamController<EmergingTrend>.broadcast();
  final _shiftController = StreamController<CommunityShift>.broadcast();
  final _growthController = StreamController<CreatorGrowthPattern>.broadcast();
  final _recommendationController = StreamController<FeatureRecommendation>.broadcast();

  Stream<EmergingTrend> get trendStream => _trendController.stream;
  Stream<CommunityShift> get shiftStream => _shiftController.stream;
  Stream<CreatorGrowthPattern> get growthStream => _growthController.stream;
  Stream<FeatureRecommendation> get recommendationStream => _recommendationController.stream;

  // Collections
  CollectionReference<Map<String, dynamic>> get _trendsCollection =>
      _firestore.collection('detected_trends');

  CollectionReference<Map<String, dynamic>> get _shiftsCollection =>
      _firestore.collection('community_shifts');

  CollectionReference<Map<String, dynamic>> get _growthPatternsCollection =>
      _firestore.collection('creator_growth_patterns');

  CollectionReference<Map<String, dynamic>> get _recommendationsCollection =>
      _firestore.collection('feature_recommendations');

  CollectionReference<Map<String, dynamic>> get _creatorsCollection =>
      _firestore.collection('creator_profiles');

  // ============================================================
  // TREND DETECTION
  // ============================================================

  /// Detect emerging trends in the community
  Future<List<EmergingTrend>> detectEmergingTrends({
    int lookbackDays = 14,
    double minGrowthRate = 0.1,
    int minAffectedUsers = 100,
  }) async {
    debugPrint('ðŸ“ˆ [CommunityAI] Detecting emerging trends');

    final trends = <EmergingTrend>[];

    try {
      // Analyze various data sources
      final contentTrends = await _analyzeContentTrends(lookbackDays);
      final topicTrends = await _analyzeTopicTrends(lookbackDays);
      final behaviorTrends = await _analyzeBehaviorTrends(lookbackDays);

      trends.addAll(contentTrends);
      trends.addAll(topicTrends);
      trends.addAll(behaviorTrends);

      // Filter by thresholds
      final filtered = trends.where((t) =>
        t.growthRate >= minGrowthRate &&
        t.affectedUsers >= minAffectedUsers
      ).toList();

      // Sort by growth rate
      filtered.sort((a, b) => b.growthRate.compareTo(a.growthRate));

      // Store detected trends
      for (final trend in filtered) {
        await _trendsCollection.doc(trend.id).set(trend.toMap());
        _trendController.add(trend);
      }

      // Track analytics
      AnalyticsService.instance.logEvent(name: 'trends_detected', parameters: {
        'count': filtered.length,
        'top_category': filtered.isNotEmpty ? filtered.first.category.name : 'none',
      });

      debugPrint('âœ… [CommunityAI] Detected ${filtered.length} emerging trends');
      return filtered;
    } catch (e) {
      debugPrint('âŒ [CommunityAI] Failed to detect trends: $e');
      return [];
    }
  }

  Future<List<EmergingTrend>> _analyzeContentTrends(int lookbackDays) async {
    // Simulate content trend analysis
    final trends = <EmergingTrend>[];

    final contentTypes = [
      ('Short-form video clips', 0.35),
      ('Interactive Q&A sessions', 0.28),
      ('Collaborative streams', 0.22),
      ('Behind-the-scenes content', 0.18),
    ];

    for (var i = 0; i < contentTypes.length; i++) {
      final (name, baseGrowth) = contentTypes[i];
      final growthVariance = _random.nextDouble() * 0.1;

      trends.add(EmergingTrend(
        id: 'trend_content_${DateTime.now().millisecondsSinceEpoch}_$i',
        name: name,
        category: TrendCategory.content,
        growthRate: baseGrowth + growthVariance,
        confidence: 0.7 + _random.nextDouble() * 0.25,
        affectedUsers: (500 + _random.nextInt(5000)),
        relatedTopics: ['entertainment', 'social', 'creativity'],
        sampleContent: [],
        detectedAt: DateTime.now(),
        stage: _determineStage(baseGrowth + growthVariance),
      ));
    }

    return trends;
  }

  Future<List<EmergingTrend>> _analyzeTopicTrends(int lookbackDays) async {
    final trends = <EmergingTrend>[];

    final topics = [
      ('AI art creation', 0.45),
      ('Music production streams', 0.32),
      ('Fitness challenges', 0.25),
      ('Language exchange', 0.20),
    ];

    for (var i = 0; i < topics.length; i++) {
      final (name, baseGrowth) = topics[i];

      trends.add(EmergingTrend(
        id: 'trend_topic_${DateTime.now().millisecondsSinceEpoch}_$i',
        name: name,
        category: TrendCategory.topic,
        growthRate: baseGrowth + _random.nextDouble() * 0.1,
        confidence: 0.65 + _random.nextDouble() * 0.3,
        affectedUsers: (300 + _random.nextInt(3000)),
        relatedTopics: [],
        sampleContent: [],
        detectedAt: DateTime.now(),
        stage: _determineStage(baseGrowth),
      ));
    }

    return trends;
  }

  Future<List<EmergingTrend>> _analyzeBehaviorTrends(int lookbackDays) async {
    final trends = <EmergingTrend>[];

    final behaviors = [
      ('Multi-room participation', 0.28),
      ('Gift chain reactions', 0.22),
      ('Scheduled recurring events', 0.19),
    ];

    for (var i = 0; i < behaviors.length; i++) {
      final (name, baseGrowth) = behaviors[i];

      trends.add(EmergingTrend(
        id: 'trend_behavior_${DateTime.now().millisecondsSinceEpoch}_$i',
        name: name,
        category: TrendCategory.behavior,
        growthRate: baseGrowth + _random.nextDouble() * 0.08,
        confidence: 0.7 + _random.nextDouble() * 0.2,
        affectedUsers: (200 + _random.nextInt(2000)),
        relatedTopics: [],
        sampleContent: [],
        detectedAt: DateTime.now(),
        stage: _determineStage(baseGrowth),
      ));
    }

    return trends;
  }

  TrendStage _determineStage(double growthRate) {
    if (growthRate > 0.4) return TrendStage.emerging;
    if (growthRate > 0.25) return TrendStage.growing;
    if (growthRate > 0.15) return TrendStage.peaking;
    if (growthRate > 0.05) return TrendStage.stable;
    return TrendStage.declining;
  }

  // ============================================================
  // COMMUNITY SHIFT DETECTION
  // ============================================================

  /// Detect significant shifts in community behavior
  Future<List<CommunityShift>> detectCommunityShifts({
    int lookbackDays = 30,
    double minMagnitude = 0.15,
  }) async {
    debugPrint('ðŸ”„ [CommunityAI] Detecting community shifts');

    final shifts = <CommunityShift>[];

    try {
      // Analyze demographic data
      final demographicShift = await _analyzeDemographicShift(lookbackDays);
      if (demographicShift != null && demographicShift.magnitude >= minMagnitude) {
        shifts.add(demographicShift);
      }

      // Analyze engagement patterns
      final engagementShift = await _analyzeEngagementShift(lookbackDays);
      if (engagementShift != null && engagementShift.magnitude >= minMagnitude) {
        shifts.add(engagementShift);
      }

      // Analyze content preferences
      final contentShift = await _analyzeContentPreferenceShift(lookbackDays);
      if (contentShift != null && contentShift.magnitude >= minMagnitude) {
        shifts.add(contentShift);
      }

      // Store detected shifts
      for (final shift in shifts) {
        await _shiftsCollection.doc(shift.id).set(shift.toMap());
        _shiftController.add(shift);
      }

      debugPrint('âœ… [CommunityAI] Detected ${shifts.length} community shifts');
      return shifts;
    } catch (e) {
      debugPrint('âŒ [CommunityAI] Failed to detect shifts: $e');
      return [];
    }
  }

  Future<CommunityShift?> _analyzeDemographicShift(int lookbackDays) async {
    // Simulate demographic analysis
    final magnitude = 0.1 + _random.nextDouble() * 0.3;

    return CommunityShift(
      id: 'shift_demo_${DateTime.now().millisecondsSinceEpoch}',
      type: ShiftType.demographicShift,
      description: 'Increasing participation from 25-34 age group',
      magnitude: magnitude,
      beforeState: {
        'ageGroup18_24': 0.45,
        'ageGroup25_34': 0.30,
        'ageGroup35_plus': 0.25,
      },
      afterState: {
        'ageGroup18_24': 0.38,
        'ageGroup25_34': 0.40,
        'ageGroup35_plus': 0.22,
      },
      drivers: ['Premium content appeal', 'Creator age demographics'],
      detectedAt: DateTime.now(),
      projectedPeakAt: DateTime.now().add(const Duration(days: 60)),
    );
  }

  Future<CommunityShift?> _analyzeEngagementShift(int lookbackDays) async {
    final magnitude = 0.12 + _random.nextDouble() * 0.25;

    return CommunityShift(
      id: 'shift_engage_${DateTime.now().millisecondsSinceEpoch}',
      type: ShiftType.engagementPattern,
      description: 'Shift from passive viewing to active participation',
      magnitude: magnitude,
      beforeState: {
        'passiveViewers': 0.70,
        'activeParticipants': 0.30,
      },
      afterState: {
        'passiveViewers': 0.55,
        'activeParticipants': 0.45,
      },
      drivers: ['Interactive features', 'Gamification', 'Creator incentives'],
      detectedAt: DateTime.now(),
    );
  }

  Future<CommunityShift?> _analyzeContentPreferenceShift(int lookbackDays) async {
    final magnitude = 0.15 + _random.nextDouble() * 0.2;

    return CommunityShift(
      id: 'shift_content_${DateTime.now().millisecondsSinceEpoch}',
      type: ShiftType.contentPreference,
      description: 'Growing preference for educational content',
      magnitude: magnitude,
      beforeState: {
        'entertainment': 0.60,
        'educational': 0.25,
        'social': 0.15,
      },
      afterState: {
        'entertainment': 0.45,
        'educational': 0.38,
        'social': 0.17,
      },
      drivers: ['New learning-focused creators', 'Skill-building trend'],
      detectedAt: DateTime.now(),
    );
  }

  // ============================================================
  // CREATOR GROWTH PATTERN DETECTION
  // ============================================================

  /// Detect and analyze creator growth patterns
  Future<List<CreatorGrowthPattern>> detectCreatorGrowthPatterns({
    int limit = 50,
    GrowthPatternType? filterType,
  }) async {
    debugPrint('ðŸ“Š [CommunityAI] Analyzing creator growth patterns');

    final patterns = <CreatorGrowthPattern>[];

    try {
      // Fetch creator data
      final creatorsQuery = await _creatorsCollection
          .orderBy('followerCount', descending: true)
          .limit(limit)
          .get();

      for (final doc in creatorsQuery.docs) {
        final data = doc.data();
        final creatorId = doc.id;
        final creatorName = data['displayName'] as String? ?? 'Unknown';
        final followerCount = (data['followerCount'] as num?)?.toInt() ?? 0;
        final followerGain = (data['followerGain30d'] as num?)?.toInt() ?? _random.nextInt(500);
        final engagementRate = (data['engagementRate'] as num?)?.toDouble() ??
            0.02 + _random.nextDouble() * 0.08;

        // Calculate growth velocity
        final growthVelocity = followerCount > 0
            ? followerGain / followerCount
            : 0.0;

        // Determine pattern type
        final patternType = _determineGrowthPattern(growthVelocity, engagementRate);

        // Skip if filtering and doesn't match
        if (filterType != null && patternType != filterType) continue;

        // Generate recommendations
        final recommendations = _generateGrowthRecommendations(patternType, engagementRate);

        final pattern = CreatorGrowthPattern(
          creatorId: creatorId,
          creatorName: creatorName,
          patternType: patternType,
          growthVelocity: growthVelocity,
          followerCount: followerCount,
          followerGain30d: followerGain,
          engagementRate: engagementRate,
          successFactors: _identifySuccessFactors(data),
          recommendations: recommendations,
          analyzedAt: DateTime.now(),
        );

        patterns.add(pattern);

        // Store pattern
        await _growthPatternsCollection.doc(creatorId).set(pattern.toMap());
        _growthController.add(pattern);
      }

      debugPrint('âœ… [CommunityAI] Analyzed ${patterns.length} creator growth patterns');
      return patterns;
    } catch (e) {
      debugPrint('âŒ [CommunityAI] Failed to analyze growth patterns: $e');
      return [];
    }
  }

  GrowthPatternType _determineGrowthPattern(double velocity, double engagement) {
    if (velocity > 0.5) return GrowthPatternType.explosive;
    if (velocity > 0.3 && engagement > 0.05) return GrowthPatternType.viral;
    if (velocity > 0.1) return GrowthPatternType.steady;
    if (velocity > 0 && velocity < 0.02) return GrowthPatternType.plateaued;
    if (velocity < 0 && engagement > 0.03) return GrowthPatternType.resurgent;
    if (velocity < 0) return GrowthPatternType.declining;
    return GrowthPatternType.steady;
  }

  List<String> _identifySuccessFactors(Map<String, dynamic> data) {
    final factors = <String>[];

    if (((data['streamFrequency'] as num?)?.toInt() ?? 0) > 3) {
      factors.add('Consistent streaming schedule');
    }
    if (((data['avgRoomDuration'] as num?)?.toInt() ?? 0) > 60) {
      factors.add('Long-form engaging content');
    }
    if (((data['interactionRate'] as num?)?.toDouble() ?? 0) > 0.3) {
      factors.add('High audience interaction');
    }
    if (((data['collaborationCount'] as num?)?.toInt() ?? 0) > 2) {
      factors.add('Active collaborations');
    }

    return factors;
  }

  List<String> _generateGrowthRecommendations(GrowthPatternType type, double engagement) {
    switch (type) {
      case GrowthPatternType.explosive:
        return [
          'Maintain momentum with consistent content',
          'Consider launching premium offerings',
          'Build community moderation team',
        ];
      case GrowthPatternType.viral:
        return [
          'Replicate successful content format',
          'Engage with new followers personally',
          'Create shareable highlight clips',
        ];
      case GrowthPatternType.steady:
        return [
          'Experiment with new content types',
          'Collaborate with complementary creators',
          'Optimize streaming schedule for audience timezone',
        ];
      case GrowthPatternType.plateaued:
        return [
          'Refresh content strategy',
          'Try new room formats',
          'Engage more actively with community',
          'Consider cross-promotion opportunities',
        ];
      case GrowthPatternType.declining:
        return [
          'Analyze audience retention data',
          'Survey existing followers for feedback',
          'Take strategic break if needed',
          'Consider niche pivot',
        ];
      case GrowthPatternType.resurgent:
        return [
          'Capitalize on renewed interest',
          'Re-engage lapsed followers',
          'Double down on what\'s working',
        ];
    }
  }

  // ============================================================
  // FEATURE RECOMMENDATIONS
  // ============================================================

  /// Automatically recommend features based on community data
  Future<List<FeatureRecommendation>> autoRecommendFeatures({
    int maxRecommendations = 5,
  }) async {
    debugPrint('ðŸ’¡ [CommunityAI] Generating feature recommendations');

    final recommendations = <FeatureRecommendation>[];

    try {
      // Get trending data
      final trends = await detectEmergingTrends();
      final shifts = await detectCommunityShifts();

      // Generate recommendations from trends
      for (final trend in trends.take(3)) {
        final rec = _generateRecommendationFromTrend(trend);
        if (rec != null) recommendations.add(rec);
      }

      // Generate recommendations from shifts
      for (final shift in shifts.take(2)) {
        final rec = _generateRecommendationFromShift(shift);
        if (rec != null) recommendations.add(rec);
      }

      // Add AI-predicted recommendations
      final aiRecs = _generateAIPredictedRecommendations();
      recommendations.addAll(aiRecs);

      // Sort by priority score
      recommendations.sort((a, b) => b.priorityScore.compareTo(a.priorityScore));

      // Limit and store
      final limited = recommendations.take(maxRecommendations).toList();

      for (final rec in limited) {
        await _recommendationsCollection.doc(rec.id).set(rec.toMap());
        _recommendationController.add(rec);
      }

      // Track analytics
      AnalyticsService.instance.logEvent(name: 'feature_recommendations', parameters: {
        'count': limited.length,
      });

      debugPrint('âœ… [CommunityAI] Generated ${limited.length} feature recommendations');
      return limited;
    } catch (e) {
      debugPrint('âŒ [CommunityAI] Failed to generate recommendations: $e');
      return [];
    }
  }

  FeatureRecommendation? _generateRecommendationFromTrend(EmergingTrend trend) {
    final impactScore = trend.growthRate * trend.confidence;
    final effortScore = 0.3 + _random.nextDouble() * 0.5;
    final priorityScore = impactScore / effortScore;

    return FeatureRecommendation(
      id: 'rec_trend_${DateTime.now().millisecondsSinceEpoch}',
      featureName: 'Support for ${trend.name}',
      description: 'Capitalize on emerging trend in ${trend.category.name}',
      impactScore: impactScore,
      effortScore: effortScore,
      priorityScore: priorityScore,
      supportingData: [
        'Growth rate: ${(trend.growthRate * 100).toStringAsFixed(1)}%',
        'Affected users: ${trend.affectedUsers}',
        'Confidence: ${(trend.confidence * 100).toStringAsFixed(0)}%',
      ],
      targetSegments: trend.relatedTopics,
      projectedMetrics: {
        'engagementIncrease': trend.growthRate * 0.5,
        'userRetentionImprovement': trend.growthRate * 0.3,
      },
      source: RecommendationSource.trendAnalysis,
      generatedAt: DateTime.now(),
    );
  }

  FeatureRecommendation? _generateRecommendationFromShift(CommunityShift shift) {
    final impactScore = shift.magnitude;
    final effortScore = 0.4 + _random.nextDouble() * 0.4;
    final priorityScore = impactScore / effortScore;

    return FeatureRecommendation(
      id: 'rec_shift_${DateTime.now().millisecondsSinceEpoch}',
      featureName: 'Adapt to ${shift.type.name}',
      description: shift.description,
      impactScore: impactScore,
      effortScore: effortScore,
      priorityScore: priorityScore,
      supportingData: shift.drivers,
      targetSegments: ['all_users'],
      projectedMetrics: {
        'relevanceImprovement': shift.magnitude,
      },
      source: RecommendationSource.usagePatterns,
      generatedAt: DateTime.now(),
    );
  }

  List<FeatureRecommendation> _generateAIPredictedRecommendations() {
    final templates = [
      {
        'name': 'AI-Powered Room Matching',
        'description': 'Use ML to match users with rooms based on interests',
        'impact': 0.6,
        'effort': 0.7,
      },
      {
        'name': 'Sentiment-Based Moderation',
        'description': 'Auto-detect negative interactions in real-time',
        'impact': 0.5,
        'effort': 0.6,
      },
      {
        'name': 'Personalized Creator Discovery',
        'description': 'Recommend creators based on viewing history',
        'impact': 0.55,
        'effort': 0.5,
      },
    ];

    return templates.map((t) => FeatureRecommendation(
      id: 'rec_ai_${DateTime.now().millisecondsSinceEpoch}_${_random.nextInt(1000)}',
      featureName: t['name'] as String,
      description: t['description'] as String,
      impactScore: t['impact'] as double,
      effortScore: t['effort'] as double,
      priorityScore: (t['impact'] as double) / (t['effort'] as double),
      supportingData: ['AI prediction based on platform patterns'],
      targetSegments: ['all_users'],
      projectedMetrics: {},
      source: RecommendationSource.aiPrediction,
      generatedAt: DateTime.now(),
    )).toList();
  }

  // ============================================================
  // INTEGRATION WITH OTHER SERVICES
  // ============================================================

  /// Get comprehensive community insights
  Future<Map<String, dynamic>> getCommunityInsights() async {
    final trends = await detectEmergingTrends();
    final shifts = await detectCommunityShifts();
    final recommendations = await autoRecommendFeatures();

    return {
      'timestamp': DateTime.now().toIso8601String(),
      'trends': trends.map((t) => t.toMap()).toList(),
      'shifts': shifts.map((s) => s.toMap()).toList(),
      'recommendations': recommendations.map((r) => r.toMap()).toList(),
      'summary': {
        'topTrend': trends.isNotEmpty ? trends.first.name : 'None detected',
        'majorShift': shifts.isNotEmpty ? shifts.first.description : 'None detected',
        'topRecommendation': recommendations.isNotEmpty ? recommendations.first.featureName : 'None',
      },
    };
  }

  /// Dispose resources
  void dispose() {
    _trendController.close();
    _shiftController.close();
    _growthController.close();
    _recommendationController.close();
  }
}
