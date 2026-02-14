/// Policy Engine
///
/// Platform governance and policy enforcement system for
/// community guidelines, automated policy updates, and violation detection.
library;

import 'dart:async';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../analytics/analytics_service.dart';

/// Policy definition
class PolicyDefinition {
  final String id;
  final String name;
  final String description;
  final PolicyCategory category;
  final PolicySeverity severity;
  final List<String> rules;
  final List<String> examples;
  final List<PolicyAction> actions;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String version;

  const PolicyDefinition({
    required this.id,
    required this.name,
    required this.description,
    required this.category,
    required this.severity,
    this.rules = const [],
    this.examples = const [],
    this.actions = const [],
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
    required this.version,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'description': description,
    'category': category.name,
    'severity': severity.name,
    'rules': rules,
    'examples': examples,
    'actions': actions.map((a) => a.toMap()).toList(),
    'isActive': isActive,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
    'version': version,
  };

  PolicyDefinition copyWith({
    String? id,
    String? name,
    String? description,
    PolicyCategory? category,
    PolicySeverity? severity,
    List<String>? rules,
    List<String>? examples,
    List<PolicyAction>? actions,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? version,
  }) {
    return PolicyDefinition(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      category: category ?? this.category,
      severity: severity ?? this.severity,
      rules: rules ?? this.rules,
      examples: examples ?? this.examples,
      actions: actions ?? this.actions,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      version: version ?? this.version,
    );
  }
}

/// Policy categories
enum PolicyCategory {
  content,
  behavior,
  safety,
  privacy,
  monetization,
  intellectualProperty,
  community,
}

/// Policy severity levels
enum PolicySeverity {
  informational,
  warning,
  moderate,
  severe,
  critical,
}

/// Policy action
class PolicyAction {
  final PolicyActionType type;
  final Duration? duration;
  final String description;
  final bool requiresReview;

  const PolicyAction({
    required this.type,
    this.duration,
    required this.description,
    this.requiresReview = false,
  });

  Map<String, dynamic> toMap() => {
    'type': type.name,
    'durationMinutes': duration?.inMinutes,
    'description': description,
    'requiresReview': requiresReview,
  };
}

/// Policy action types
enum PolicyActionType {
  warning,
  contentRemoval,
  temporaryMute,
  temporaryBan,
  permanentBan,
  restrictFeatures,
  requireVerification,
  accountSuspension,
}

/// Policy violation record
class PolicyViolation {
  final String id;
  final String policyId;
  final String userId;
  final String? contentId;
  final String? roomId;
  final ViolationType violationType;
  final String description;
  final double confidence;
  final ViolationStatus status;
  final List<String> evidence;
  final PolicyAction? actionTaken;
  final String? reviewedBy;
  final DateTime detectedAt;
  final DateTime? resolvedAt;

  const PolicyViolation({
    required this.id,
    required this.policyId,
    required this.userId,
    this.contentId,
    this.roomId,
    required this.violationType,
    required this.description,
    required this.confidence,
    required this.status,
    this.evidence = const [],
    this.actionTaken,
    this.reviewedBy,
    required this.detectedAt,
    this.resolvedAt,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'policyId': policyId,
    'userId': userId,
    'contentId': contentId,
    'roomId': roomId,
    'violationType': violationType.name,
    'description': description,
    'confidence': confidence,
    'status': status.name,
    'evidence': evidence,
    'actionTaken': actionTaken?.toMap(),
    'reviewedBy': reviewedBy,
    'detectedAt': detectedAt.toIso8601String(),
    'resolvedAt': resolvedAt?.toIso8601String(),
  };
}

/// Violation types
enum ViolationType {
  automated,
  userReport,
  moderatorFlag,
  systemDetected,
}

/// Violation status
enum ViolationStatus {
  pending,
  investigating,
  confirmed,
  dismissed,
  appealed,
  resolved,
}

/// Policy report
class PolicyReport {
  final String reportId;
  final DateTime periodStart;
  final DateTime periodEnd;
  final int totalViolations;
  final Map<String, int> violationsByCategory;
  final Map<String, int> violationsBySeverity;
  final int actionsEnforced;
  final int appealsFiled;
  final int appealsGranted;
  final double automatedDetectionRate;
  final double falsePositiveRate;
  final List<String> recommendations;

  const PolicyReport({
    required this.reportId,
    required this.periodStart,
    required this.periodEnd,
    required this.totalViolations,
    this.violationsByCategory = const {},
    this.violationsBySeverity = const {},
    required this.actionsEnforced,
    required this.appealsFiled,
    required this.appealsGranted,
    required this.automatedDetectionRate,
    required this.falsePositiveRate,
    this.recommendations = const [],
  });

  Map<String, dynamic> toMap() => {
    'reportId': reportId,
    'periodStart': periodStart.toIso8601String(),
    'periodEnd': periodEnd.toIso8601String(),
    'totalViolations': totalViolations,
    'violationsByCategory': violationsByCategory,
    'violationsBySeverity': violationsBySeverity,
    'actionsEnforced': actionsEnforced,
    'appealsFiled': appealsFiled,
    'appealsGranted': appealsGranted,
    'automatedDetectionRate': automatedDetectionRate,
    'falsePositiveRate': falsePositiveRate,
    'recommendations': recommendations,
  };
}

/// Policy engine for platform governance
class PolicyEngine {
  static PolicyEngine? _instance;
  static PolicyEngine get instance => _instance ??= PolicyEngine._();

  PolicyEngine._();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final _random = Random();

  // Cached policies
  final Map<String, PolicyDefinition> _policies = {};

  // Stream controllers
  final _policyController = StreamController<PolicyDefinition>.broadcast();
  final _violationController = StreamController<PolicyViolation>.broadcast();

  Stream<PolicyDefinition> get policyStream => _policyController.stream;
  Stream<PolicyViolation> get violationStream => _violationController.stream;

  // Collections
  CollectionReference<Map<String, dynamic>> get _policiesCollection =>
      _firestore.collection('policies');

  CollectionReference<Map<String, dynamic>> get _violationsCollection =>
      _firestore.collection('policy_violations');

  CollectionReference<Map<String, dynamic>> get _reportsCollection =>
      _firestore.collection('policy_reports');

  // ============================================================
  // COMMUNITY GUIDELINES ENFORCEMENT
  // ============================================================

  /// Enforce community guidelines on content/user
  Future<List<PolicyViolation>> enforceCommunityGuidelines({
    required String userId,
    String? contentId,
    String? roomId,
    String? textContent,
    List<String>? mediaUrls,
  }) async {
    debugPrint('📜 [PolicyEngine] Enforcing community guidelines for user: $userId');

    final violations = <PolicyViolation>[];

    try {
      // Load policies if not cached
      if (_policies.isEmpty) {
        await loadPolicies();
      }

      // Check text content against policies
      if (textContent != null && textContent.isNotEmpty) {
        final textViolations = await _checkTextContent(
          userId: userId,
          contentId: contentId,
          content: textContent,
        );
        violations.addAll(textViolations);
      }

      // Check behavior patterns
      final behaviorViolations = await _checkBehaviorPatterns(
        userId: userId,
        roomId: roomId,
      );
      violations.addAll(behaviorViolations);

      // Store violations
      for (final violation in violations) {
        await _violationsCollection.doc(violation.id).set(violation.toMap());
        _violationController.add(violation);
      }

      // Track analytics
      if (violations.isNotEmpty) {
        AnalyticsService.instance.logEvent(name: 'policy_violations', parameters: {
          'count': violations.length,
          'user_id': userId,
        });
      }

      debugPrint('✅ [PolicyEngine] Found ${violations.length} violations');
      return violations;
    } catch (e) {
      debugPrint('❌ [PolicyEngine] Failed to enforce guidelines: $e');
      return [];
    }
  }

  Future<List<PolicyViolation>> _checkTextContent({
    required String userId,
    String? contentId,
    required String content,
  }) async {
    final violations = <PolicyViolation>[];
    final lowerContent = content.toLowerCase();

    // Check for prohibited content patterns (simplified)
    final contentPolicy = _policies['content_safety'];
    if (contentPolicy != null) {
      final hasProhibited = _containsProhibitedPatterns(lowerContent);
      if (hasProhibited) {
        violations.add(PolicyViolation(
          id: 'violation_${DateTime.now().millisecondsSinceEpoch}_${_random.nextInt(10000)}',
          policyId: contentPolicy.id,
          userId: userId,
          contentId: contentId,
          violationType: ViolationType.automated,
          description: 'Content may violate community guidelines',
          confidence: 0.75 + _random.nextDouble() * 0.2,
          status: ViolationStatus.pending,
          evidence: ['Automated content analysis'],
          detectedAt: DateTime.now(),
        ));
      }
    }

    return violations;
  }

  bool _containsProhibitedPatterns(String content) {
    // Simplified check - in production, use ML-based content moderation
    const prohibitedPatterns = [
      'spam',
      'scam',
      // Add actual patterns in production
    ];

    for (final pattern in prohibitedPatterns) {
      if (content.contains(pattern)) return true;
    }

    return false;
  }

  Future<List<PolicyViolation>> _checkBehaviorPatterns({
    required String userId,
    String? roomId,
  }) async {
    final violations = <PolicyViolation>[];

    // Check for behavioral violations (rate limiting, spam, etc.)
    final userDoc = await _firestore.collection('users').doc(userId).get();
    final userData = userDoc.data() ?? {};

    // Check message rate
    final recentMessageCount = (userData['messageCountLast5Min'] as num?)?.toInt() ?? 0;
    if (recentMessageCount > 50) {
      final behaviorPolicy = _policies['spam_prevention'];
      if (behaviorPolicy != null) {
        violations.add(PolicyViolation(
          id: 'violation_behavior_${DateTime.now().millisecondsSinceEpoch}',
          policyId: behaviorPolicy.id,
          userId: userId,
          roomId: roomId,
          violationType: ViolationType.systemDetected,
          description: 'Excessive message rate detected',
          confidence: 0.9,
          status: ViolationStatus.pending,
          evidence: ['Message rate: $recentMessageCount in 5 minutes'],
          actionTaken: const PolicyAction(
            type: PolicyActionType.temporaryMute,
            duration: Duration(minutes: 5),
            description: 'Auto-muted for spam prevention',
          ),
          detectedAt: DateTime.now(),
        ));
      }
    }

    return violations;
  }

  // ============================================================
  // AUTO-UPDATE POLICIES
  // ============================================================

  /// Automatically update policies based on trends and regulations
  Future<List<PolicyDefinition>> autoUpdatePolicies({
    bool checkRegulations = true,
    bool checkTrends = true,
  }) async {
    debugPrint('🔄 [PolicyEngine] Auto-updating policies');

    final updatedPolicies = <PolicyDefinition>[];

    try {
      // Load current policies
      await loadPolicies();

      // Check for regulation changes (simulated)
      if (checkRegulations) {
        final regulatoryUpdates = await _checkRegulatoryChanges();
        for (final update in regulatoryUpdates) {
          final existing = _policies[update['policyId']];
          if (existing != null) {
            final updated = existing.copyWith(
              rules: [...existing.rules, ...(update['newRules'] as List<String>)],
              updatedAt: DateTime.now(),
              version: _incrementVersion(existing.version),
            );
            await _policiesCollection.doc(updated.id).set(updated.toMap());
            _policies[updated.id] = updated;
            updatedPolicies.add(updated);
            _policyController.add(updated);
          }
        }
      }

      // Check community trends
      if (checkTrends) {
        final trendUpdates = await _checkTrendBasedUpdates();
        for (final update in trendUpdates) {
          final existing = _policies[update['policyId']];
          if (existing != null) {
            final updated = existing.copyWith(
              examples: [...existing.examples, ...(update['newExamples'] as List<String>)],
              updatedAt: DateTime.now(),
              version: _incrementVersion(existing.version),
            );
            await _policiesCollection.doc(updated.id).set(updated.toMap());
            _policies[updated.id] = updated;
            updatedPolicies.add(updated);
            _policyController.add(updated);
          }
        }
      }

      // Track analytics
      AnalyticsService.instance.logEvent(name: 'policies_updated', parameters: {
        'count': updatedPolicies.length,
      });

      debugPrint('✅ [PolicyEngine] Updated ${updatedPolicies.length} policies');
      return updatedPolicies;
    } catch (e) {
      debugPrint('❌ [PolicyEngine] Failed to auto-update policies: $e');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> _checkRegulatoryChanges() async {
    // Simulated regulatory updates
    // In production, this would check against legal databases
    return [];
  }

  Future<List<Map<String, dynamic>>> _checkTrendBasedUpdates() async {
    // Simulated trend-based updates
    // In production, this would analyze community patterns
    return [];
  }

  String _incrementVersion(String version) {
    final parts = version.split('.').map((p) => int.tryParse(p) ?? 0).toList();
    if (parts.length >= 3) {
      parts[2]++;
    }
    return parts.join('.');
  }

  // ============================================================
  // POLICY VIOLATION DETECTION
  // ============================================================

  /// Detect potential policy violations in real-time content stream
  Future<List<PolicyViolation>> detectPolicyViolations({
    required Stream<Map<String, dynamic>> contentStream,
    Duration? timeout,
  }) async {
    debugPrint('🔍 [PolicyEngine] Starting real-time violation detection');

    final violations = <PolicyViolation>[];
    final completer = Completer<List<PolicyViolation>>();

    final subscription = contentStream.listen((content) async {
      final userId = content['userId'] as String?;
      if (userId == null) return;

      final detected = await enforceCommunityGuidelines(
        userId: userId,
        contentId: content['contentId'] as String?,
        textContent: content['text'] as String?,
      );

      violations.addAll(detected);
    });

    // Set timeout
    if (timeout != null) {
      Future.delayed(timeout, () {
        subscription.cancel();
        if (!completer.isCompleted) {
          completer.complete(violations);
        }
      });
    }

    return completer.future;
  }

  // ============================================================
  // POLICY REPORTS
  // ============================================================

  /// Generate comprehensive policy report
  Future<PolicyReport> generatePolicyReports({
    DateTime? periodStart,
    DateTime? periodEnd,
  }) async {
    debugPrint('📊 [PolicyEngine] Generating policy report');

    final start = periodStart ?? DateTime.now().subtract(const Duration(days: 30));
    final end = periodEnd ?? DateTime.now();

    try {
      // Query violations in period
      final violationsQuery = await _violationsCollection
          .where('detectedAt', isGreaterThanOrEqualTo: start.toIso8601String())
          .where('detectedAt', isLessThanOrEqualTo: end.toIso8601String())
          .get();

      // Aggregate statistics
      final violationsByCategory = <String, int>{};
      final violationsBySeverity = <String, int>{};
      int actionsEnforced = 0;
      int appealsTotal = 0;
      int appealsGranted = 0;
      int automatedDetections = 0;
      int falsePositives = 0;

      for (final doc in violationsQuery.docs) {
        final data = doc.data();

        // Count by category
        final policyId = data['policyId'] as String?;
        if (policyId != null && _policies.containsKey(policyId)) {
          final category = _policies[policyId]!.category.name;
          violationsByCategory[category] = (violationsByCategory[category] ?? 0) + 1;

          final severity = _policies[policyId]!.severity.name;
          violationsBySeverity[severity] = (violationsBySeverity[severity] ?? 0) + 1;
        }

        // Count actions
        if (data['actionTaken'] != null) actionsEnforced++;

        // Count appeals
        if (data['status'] == ViolationStatus.appealed.name) {
          appealsTotal++;
        }
        if (data['status'] == ViolationStatus.dismissed.name) {
          appealsGranted++;
          falsePositives++;
        }

        // Count automated
        if (data['violationType'] == ViolationType.automated.name) {
          automatedDetections++;
        }
      }

      final totalViolations = violationsQuery.docs.length;
      final automatedRate = totalViolations > 0
          ? automatedDetections / totalViolations
          : 0.0;
      final falsePositiveRate = automatedDetections > 0
          ? falsePositives / automatedDetections
          : 0.0;

      // Generate recommendations
      final recommendations = _generateReportRecommendations(
        falsePositiveRate: falsePositiveRate,
        violationsByCategory: violationsByCategory,
      );

      final report = PolicyReport(
        reportId: 'report_${DateTime.now().millisecondsSinceEpoch}',
        periodStart: start,
        periodEnd: end,
        totalViolations: totalViolations,
        violationsByCategory: violationsByCategory,
        violationsBySeverity: violationsBySeverity,
        actionsEnforced: actionsEnforced,
        appealsFiled: appealsTotal,
        appealsGranted: appealsGranted,
        automatedDetectionRate: automatedRate,
        falsePositiveRate: falsePositiveRate,
        recommendations: recommendations,
      );

      // Store report
      await _reportsCollection.doc(report.reportId).set(report.toMap());

      debugPrint('✅ [PolicyEngine] Generated report with $totalViolations violations');
      return report;
    } catch (e) {
      debugPrint('❌ [PolicyEngine] Failed to generate report: $e');
      rethrow;
    }
  }

  List<String> _generateReportRecommendations({
    required double falsePositiveRate,
    required Map<String, int> violationsByCategory,
  }) {
    final recommendations = <String>[];

    if (falsePositiveRate > 0.1) {
      recommendations.add('High false positive rate (${(falsePositiveRate * 100).toStringAsFixed(1)}%) - consider tuning detection algorithms');
    }

    final sortedCategories = violationsByCategory.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    if (sortedCategories.isNotEmpty) {
      recommendations.add('Focus moderation resources on ${sortedCategories.first.key} category');
    }

    if (sortedCategories.length > 1 &&
        sortedCategories.first.value > sortedCategories[1].value * 3) {
      recommendations.add('Consider additional content filters for ${sortedCategories.first.key}');
    }

    return recommendations;
  }

  // ============================================================
  // POLICY MANAGEMENT
  // ============================================================

  /// Load policies from Firestore
  Future<void> loadPolicies() async {
    try {
      final snapshot = await _policiesCollection.get();

      for (final doc in snapshot.docs) {
        final data = doc.data();
        _policies[doc.id] = PolicyDefinition(
          id: data['id'] as String,
          name: data['name'] as String,
          description: data['description'] as String,
          category: PolicyCategory.values.firstWhere(
            (c) => c.name == data['category'],
            orElse: () => PolicyCategory.community,
          ),
          severity: PolicySeverity.values.firstWhere(
            (s) => s.name == data['severity'],
            orElse: () => PolicySeverity.warning,
          ),
          rules: List<String>.from(data['rules'] ?? []),
          examples: List<String>.from(data['examples'] ?? []),
          actions: (data['actions'] as List<dynamic>?)?.map((a) {
            final actionMap = a as Map<String, dynamic>;
            return PolicyAction(
              type: PolicyActionType.values.firstWhere(
                (t) => t.name == actionMap['type'],
                orElse: () => PolicyActionType.warning,
              ),
              duration: actionMap['durationMinutes'] != null
                  ? Duration(minutes: actionMap['durationMinutes'] as int)
                  : null,
              description: actionMap['description'] as String? ?? '',
              requiresReview: actionMap['requiresReview'] as bool? ?? false,
            );
          }).toList() ?? [],
          isActive: data['isActive'] as bool? ?? true,
          createdAt: DateTime.parse(data['createdAt'] as String),
          updatedAt: DateTime.parse(data['updatedAt'] as String),
          version: data['version'] as String? ?? '1.0.0',
        );
      }

      // Initialize default policies if none exist
      if (_policies.isEmpty) {
        await _initializeDefaultPolicies();
      }

      debugPrint('📜 [PolicyEngine] Loaded ${_policies.length} policies');
    } catch (e) {
      debugPrint('❌ [PolicyEngine] Failed to load policies: $e');
      await _initializeDefaultPolicies();
    }
  }

  Future<void> _initializeDefaultPolicies() async {
    final defaultPolicies = [
      PolicyDefinition(
        id: 'content_safety',
        name: 'Content Safety',
        description: 'Ensures all content is safe and appropriate',
        category: PolicyCategory.content,
        severity: PolicySeverity.severe,
        rules: [
          'No explicit or adult content',
          'No violence or graphic content',
          'No hate speech or discrimination',
        ],
        examples: [],
        actions: [
          const PolicyAction(
            type: PolicyActionType.contentRemoval,
            description: 'Remove violating content',
          ),
          const PolicyAction(
            type: PolicyActionType.warning,
            description: 'Issue warning to user',
          ),
        ],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        version: '1.0.0',
      ),
      PolicyDefinition(
        id: 'spam_prevention',
        name: 'Spam Prevention',
        description: 'Prevents spam and excessive messaging',
        category: PolicyCategory.behavior,
        severity: PolicySeverity.moderate,
        rules: [
          'No excessive repetitive messages',
          'No unsolicited promotional content',
          'No automated bot behavior',
        ],
        examples: [],
        actions: [
          const PolicyAction(
            type: PolicyActionType.temporaryMute,
            duration: Duration(minutes: 5),
            description: 'Temporary mute for spam',
          ),
        ],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        version: '1.0.0',
      ),
      PolicyDefinition(
        id: 'privacy_protection',
        name: 'Privacy Protection',
        description: 'Protects user privacy and personal information',
        category: PolicyCategory.privacy,
        severity: PolicySeverity.severe,
        rules: [
          'No sharing of personal information without consent',
          'No doxxing or identity exposure',
          'Respect recording consent requirements',
        ],
        examples: [],
        actions: [
          const PolicyAction(
            type: PolicyActionType.contentRemoval,
            description: 'Remove privacy-violating content',
            requiresReview: true,
          ),
        ],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        version: '1.0.0',
      ),
    ];

    for (final policy in defaultPolicies) {
      await _policiesCollection.doc(policy.id).set(policy.toMap());
      _policies[policy.id] = policy;
    }
  }

  /// Get all policies
  List<PolicyDefinition> getPolicies({PolicyCategory? category}) {
    if (category == null) return _policies.values.toList();
    return _policies.values.where((p) => p.category == category).toList();
  }

  /// Get policy by ID
  PolicyDefinition? getPolicy(String id) => _policies[id];

  /// Dispose resources
  void dispose() {
    _policyController.close();
    _violationController.close();
    _policies.clear();
  }
}
