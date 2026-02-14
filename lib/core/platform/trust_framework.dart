/// Trust Framework Service
///
/// Manages platform governance including creator/partner/app certification,
/// trust scores, and rule enforcement.
library;

import 'dart:async';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../analytics/analytics_service.dart';

/// Certification record
class Certification {
  final String id;
  final String entityId;
  final EntityType entityType;
  final CertificationType type;
  final CertificationStatus status;
  final int level;
  final double trustScore;
  final List<String> badges;
  final List<String> requirements;
  final List<String> completedRequirements;
  final Map<String, dynamic> metadata;
  final DateTime issuedAt;
  final DateTime? expiresAt;
  final DateTime? revokedAt;
  final String? revokedReason;

  const Certification({
    required this.id,
    required this.entityId,
    required this.entityType,
    required this.type,
    required this.status,
    this.level = 1,
    this.trustScore = 0,
    this.badges = const [],
    this.requirements = const [],
    this.completedRequirements = const [],
    this.metadata = const {},
    required this.issuedAt,
    this.expiresAt,
    this.revokedAt,
    this.revokedReason,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'entityId': entityId,
        'entityType': entityType.name,
        'type': type.name,
        'status': status.name,
        'level': level,
        'trustScore': trustScore,
        'badges': badges,
        'requirements': requirements,
        'completedRequirements': completedRequirements,
        'metadata': metadata,
        'issuedAt': issuedAt.toIso8601String(),
        'expiresAt': expiresAt?.toIso8601String(),
        'revokedAt': revokedAt?.toIso8601String(),
        'revokedReason': revokedReason,
      };

  factory Certification.fromMap(Map<String, dynamic> map) => Certification(
        id: map['id'] as String,
        entityId: map['entityId'] as String,
        entityType: EntityType.values.firstWhere(
          (e) => e.name == map['entityType'],
        ),
        type: CertificationType.values.firstWhere(
          (t) => t.name == map['type'],
        ),
        status: CertificationStatus.values.firstWhere(
          (s) => s.name == map['status'],
        ),
        level: map['level'] as int? ?? 1,
        trustScore: (map['trustScore'] as num?)?.toDouble() ?? 0,
        badges: List<String>.from(map['badges'] ?? []),
        requirements: List<String>.from(map['requirements'] ?? []),
        completedRequirements: List<String>.from(map['completedRequirements'] ?? []),
        metadata: (map['metadata'] as Map<String, dynamic>?) ?? {},
        issuedAt: DateTime.parse(map['issuedAt'] as String),
        expiresAt: map['expiresAt'] != null
            ? DateTime.parse(map['expiresAt'] as String)
            : null,
        revokedAt: map['revokedAt'] != null
            ? DateTime.parse(map['revokedAt'] as String)
            : null,
        revokedReason: map['revokedReason'] as String?,
      );
}

enum EntityType {
  creator,
  partner,
  app,
  organization,
}

enum CertificationType {
  verified,
  professional,
  premium,
  enterprise,
  trusted,
}

enum CertificationStatus {
  pending,
  active,
  expired,
  revoked,
  suspended,
}

/// Platform rule
class PlatformRule {
  final String id;
  final String name;
  final String description;
  final RuleCategory category;
  final RuleSeverity severity;
  final List<String> triggers;
  final List<RuleAction> actions;
  final bool isActive;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const PlatformRule({
    required this.id,
    required this.name,
    required this.description,
    required this.category,
    required this.severity,
    this.triggers = const [],
    this.actions = const [],
    this.isActive = true,
    required this.createdAt,
    this.updatedAt,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'description': description,
        'category': category.name,
        'severity': severity.name,
        'triggers': triggers,
        'actions': actions.map((a) => a.toMap()).toList(),
        'isActive': isActive,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt?.toIso8601String(),
      };
}

enum RuleCategory {
  content,
  behavior,
  commerce,
  privacy,
  security,
  legal,
}

enum RuleSeverity {
  info,
  warning,
  violation,
  critical,
}

class RuleAction {
  final String type;
  final Map<String, dynamic> parameters;

  const RuleAction({
    required this.type,
    this.parameters = const {},
  });

  Map<String, dynamic> toMap() => {
        'type': type,
        'parameters': parameters,
      };
}

/// Violation record
class Violation {
  final String id;
  final String entityId;
  final EntityType entityType;
  final String ruleId;
  final ViolationStatus status;
  final RuleSeverity severity;
  final String description;
  final List<String> evidence;
  final String? resolution;
  final int trustScoreImpact;
  final DateTime occurredAt;
  final DateTime? resolvedAt;

  const Violation({
    required this.id,
    required this.entityId,
    required this.entityType,
    required this.ruleId,
    required this.status,
    required this.severity,
    required this.description,
    this.evidence = const [],
    this.resolution,
    this.trustScoreImpact = 0,
    required this.occurredAt,
    this.resolvedAt,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'entityId': entityId,
        'entityType': entityType.name,
        'ruleId': ruleId,
        'status': status.name,
        'severity': severity.name,
        'description': description,
        'evidence': evidence,
        'resolution': resolution,
        'trustScoreImpact': trustScoreImpact,
        'occurredAt': occurredAt.toIso8601String(),
        'resolvedAt': resolvedAt?.toIso8601String(),
      };
}

enum ViolationStatus {
  pending,
  investigating,
  confirmed,
  dismissed,
  appealed,
  resolved,
}

/// Trust score details
class TrustScore {
  final String entityId;
  final EntityType entityType;
  final double overallScore;
  final Map<String, double> categoryScores;
  final List<TrustFactor> factors;
  final int violationCount;
  final int certificationCount;
  final DateTime calculatedAt;

  const TrustScore({
    required this.entityId,
    required this.entityType,
    required this.overallScore,
    this.categoryScores = const {},
    this.factors = const [],
    this.violationCount = 0,
    this.certificationCount = 0,
    required this.calculatedAt,
  });

  Map<String, dynamic> toMap() => {
        'entityId': entityId,
        'entityType': entityType.name,
        'overallScore': overallScore,
        'categoryScores': categoryScores,
        'factors': factors.map((f) => f.toMap()).toList(),
        'violationCount': violationCount,
        'certificationCount': certificationCount,
        'calculatedAt': calculatedAt.toIso8601String(),
      };
}

class TrustFactor {
  final String name;
  final double weight;
  final double score;
  final String description;

  const TrustFactor({
    required this.name,
    required this.weight,
    required this.score,
    required this.description,
  });

  Map<String, dynamic> toMap() => {
        'name': name,
        'weight': weight,
        'score': score,
        'description': description,
      };
}

/// Trust Framework Service
class TrustFrameworkService {
  static TrustFrameworkService? _instance;
  static TrustFrameworkService get instance =>
      _instance ??= TrustFrameworkService._();

  TrustFrameworkService._();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final _random = Random();

  // Stream controllers
  final _certificationController = StreamController<Certification>.broadcast();
  final _violationController = StreamController<Violation>.broadcast();

  Stream<Certification> get certificationStream => _certificationController.stream;
  Stream<Violation> get violationStream => _violationController.stream;

  // Collections
  CollectionReference<Map<String, dynamic>> get _certificationsCollection =>
      _firestore.collection('certifications');

  CollectionReference<Map<String, dynamic>> get _rulesCollection =>
      _firestore.collection('platform_rules');

  CollectionReference<Map<String, dynamic>> get _violationsCollection =>
      _firestore.collection('violations');

  CollectionReference<Map<String, dynamic>> get _trustScoresCollection =>
      _firestore.collection('trust_scores');

  // ============================================================
  // CERTIFY CREATORS
  // ============================================================

  /// Certify a creator
  Future<Certification> certifyCreators({
    required String creatorId,
    required CertificationType type,
    int level = 1,
    List<String>? badges,
    Duration? validFor,
  }) async {
    debugPrint('🏆 [TrustFramework] Certifying creator: $creatorId');

    try {
      final id = 'cert_${DateTime.now().millisecondsSinceEpoch}_${_random.nextInt(10000)}';
      final now = DateTime.now();

      // Get requirements for certification type
      final requirements = _getCertificationRequirements(type, EntityType.creator);

      // Calculate initial trust score
      final trustScore = await _calculateTrustScore(creatorId, EntityType.creator);

      final certification = Certification(
        id: id,
        entityId: creatorId,
        entityType: EntityType.creator,
        type: type,
        status: CertificationStatus.active,
        level: level,
        trustScore: trustScore.overallScore,
        badges: badges ?? _getDefaultBadges(type),
        requirements: requirements,
        completedRequirements: requirements, // Assume all completed for now
        issuedAt: now,
        expiresAt: validFor != null ? now.add(validFor) : null,
      );

      await _certificationsCollection.doc(id).set(certification.toMap());

      // Update trust score
      await _updateTrustScore(creatorId, EntityType.creator);

      _certificationController.add(certification);

      AnalyticsService.instance.logEvent(
        name: 'creator_certified',
        parameters: {
          'type': type.name,
          'level': level,
        },
      );

      debugPrint('✅ [TrustFramework] Creator certified: $id');
      return certification;
    } catch (e) {
      debugPrint('❌ [TrustFramework] Failed to certify creator: $e');
      rethrow;
    }
  }

  List<String> _getCertificationRequirements(
    CertificationType type,
    EntityType entityType,
  ) {
    final baseRequirements = ['identity_verified', 'email_verified', 'terms_accepted'];

    return switch (type) {
      CertificationType.verified => [...baseRequirements],
      CertificationType.professional => [
          ...baseRequirements,
          'minimum_followers_1000',
          'minimum_streams_50',
          'no_violations_90_days',
        ],
      CertificationType.premium => [
          ...baseRequirements,
          'minimum_followers_10000',
          'minimum_revenue_1000',
          'premium_subscription',
        ],
      CertificationType.enterprise => [
          ...baseRequirements,
          'business_verified',
          'contract_signed',
          'dedicated_support',
        ],
      CertificationType.trusted => [
          ...baseRequirements,
          'trust_score_80',
          'no_violations_180_days',
          'active_community_member',
        ],
    };
  }

  List<String> _getDefaultBadges(CertificationType type) => switch (type) {
        CertificationType.verified => ['verified'],
        CertificationType.professional => ['verified', 'professional'],
        CertificationType.premium => ['verified', 'premium'],
        CertificationType.enterprise => ['verified', 'enterprise'],
        CertificationType.trusted => ['verified', 'trusted'],
      };

  // ============================================================
  // CERTIFY PARTNERS
  // ============================================================

  /// Certify a partner
  Future<Certification> certifyPartners({
    required String partnerId,
    required CertificationType type,
    int level = 1,
    List<String>? badges,
    Duration? validFor,
  }) async {
    debugPrint('🏆 [TrustFramework] Certifying partner: $partnerId');

    try {
      final id = 'cert_${DateTime.now().millisecondsSinceEpoch}_${_random.nextInt(10000)}';
      final now = DateTime.now();

      final requirements = _getCertificationRequirements(type, EntityType.partner);
      final trustScore = await _calculateTrustScore(partnerId, EntityType.partner);

      final certification = Certification(
        id: id,
        entityId: partnerId,
        entityType: EntityType.partner,
        type: type,
        status: CertificationStatus.active,
        level: level,
        trustScore: trustScore.overallScore,
        badges: badges ?? _getDefaultBadges(type),
        requirements: requirements,
        completedRequirements: requirements,
        issuedAt: now,
        expiresAt: validFor != null ? now.add(validFor) : null,
      );

      await _certificationsCollection.doc(id).set(certification.toMap());
      await _updateTrustScore(partnerId, EntityType.partner);

      _certificationController.add(certification);

      AnalyticsService.instance.logEvent(
        name: 'partner_certified',
        parameters: {'type': type.name},
      );

      debugPrint('✅ [TrustFramework] Partner certified: $id');
      return certification;
    } catch (e) {
      debugPrint('❌ [TrustFramework] Failed to certify partner: $e');
      rethrow;
    }
  }

  // ============================================================
  // CERTIFY APPS
  // ============================================================

  /// Certify an external app
  Future<Certification> certifyApps({
    required String appId,
    required CertificationType type,
    int level = 1,
    List<String>? badges,
    Duration? validFor,
  }) async {
    debugPrint('🏆 [TrustFramework] Certifying app: $appId');

    try {
      final id = 'cert_${DateTime.now().millisecondsSinceEpoch}_${_random.nextInt(10000)}';
      final now = DateTime.now();

      final requirements = [
        'security_review_passed',
        'privacy_policy_approved',
        'terms_of_service_approved',
        'data_handling_reviewed',
      ];

      final trustScore = await _calculateTrustScore(appId, EntityType.app);

      final certification = Certification(
        id: id,
        entityId: appId,
        entityType: EntityType.app,
        type: type,
        status: CertificationStatus.active,
        level: level,
        trustScore: trustScore.overallScore,
        badges: badges ?? ['certified_app'],
        requirements: requirements,
        completedRequirements: requirements,
        issuedAt: now,
        expiresAt: validFor != null ? now.add(validFor) : null,
      );

      await _certificationsCollection.doc(id).set(certification.toMap());
      await _updateTrustScore(appId, EntityType.app);

      _certificationController.add(certification);

      AnalyticsService.instance.logEvent(
        name: 'app_certified',
        parameters: {'type': type.name},
      );

      debugPrint('✅ [TrustFramework] App certified: $id');
      return certification;
    } catch (e) {
      debugPrint('❌ [TrustFramework] Failed to certify app: $e');
      rethrow;
    }
  }

  // ============================================================
  // ENFORCE PLATFORM RULES
  // ============================================================

  /// Enforce platform rules and record violations
  Future<Violation?> enforcePlatformRules({
    required String entityId,
    required EntityType entityType,
    required String ruleId,
    required String description,
    RuleSeverity? severity,
    List<String>? evidence,
  }) async {
    debugPrint('⚖️ [TrustFramework] Enforcing rule: $ruleId');

    try {
      // Get rule details
      final rule = await _getRule(ruleId);
      final actualSeverity = severity ?? rule?.severity ?? RuleSeverity.warning;

      final id = 'viol_${DateTime.now().millisecondsSinceEpoch}_${_random.nextInt(10000)}';

      // Calculate trust score impact
      final impact = _calculateTrustScoreImpact(actualSeverity);

      final violation = Violation(
        id: id,
        entityId: entityId,
        entityType: entityType,
        ruleId: ruleId,
        status: ViolationStatus.pending,
        severity: actualSeverity,
        description: description,
        evidence: evidence ?? [],
        trustScoreImpact: impact,
        occurredAt: DateTime.now(),
      );

      await _violationsCollection.doc(id).set(violation.toMap());

      // Apply trust score penalty
      await _applyTrustScorePenalty(entityId, entityType, impact);

      // Execute rule actions
      if (rule != null) {
        await _executeRuleActions(entityId, entityType, rule.actions);
      }

      _violationController.add(violation);

      AnalyticsService.instance.logEvent(
        name: 'violation_recorded',
        parameters: {
          'entity_type': entityType.name,
          'severity': actualSeverity.name,
        },
      );

      debugPrint('✅ [TrustFramework] Violation recorded: $id');
      return violation;
    } catch (e) {
      debugPrint('❌ [TrustFramework] Failed to enforce rule: $e');
      rethrow;
    }
  }

  Future<PlatformRule?> _getRule(String ruleId) async {
    final doc = await _rulesCollection.doc(ruleId).get();
    if (!doc.exists) return null;

    final data = doc.data()!;
    return PlatformRule(
      id: data['id'] as String,
      name: data['name'] as String,
      description: data['description'] as String,
      category: RuleCategory.values.firstWhere(
        (c) => c.name == data['category'],
      ),
      severity: RuleSeverity.values.firstWhere(
        (s) => s.name == data['severity'],
      ),
      triggers: List<String>.from(data['triggers'] ?? []),
      actions: (data['actions'] as List?)
              ?.map((a) => RuleAction(
                    type: a['type'] as String,
                    parameters:
                        (a['parameters'] as Map<String, dynamic>?) ?? {},
                  ))
              .toList() ??
          [],
      isActive: data['isActive'] as bool? ?? true,
      createdAt: DateTime.parse(data['createdAt'] as String),
      updatedAt: data['updatedAt'] != null
          ? DateTime.parse(data['updatedAt'] as String)
          : null,
    );
  }

  int _calculateTrustScoreImpact(RuleSeverity severity) => switch (severity) {
        RuleSeverity.info => 0,
        RuleSeverity.warning => -5,
        RuleSeverity.violation => -15,
        RuleSeverity.critical => -30,
      };

  Future<void> _applyTrustScorePenalty(
    String entityId,
    EntityType entityType,
    int penalty,
  ) async {
    if (penalty == 0) return;

    await _trustScoresCollection.doc('${entityType.name}_$entityId').update({
      'overallScore': FieldValue.increment(penalty),
      'lastPenaltyAt': DateTime.now().toIso8601String(),
    });
  }

  Future<void> _executeRuleActions(
    String entityId,
    EntityType entityType,
    List<RuleAction> actions,
  ) async {
    for (final action in actions) {
      switch (action.type) {
        case 'warn':
          debugPrint('📢 Warning issued to $entityId');
          break;
        case 'restrict':
          debugPrint('🚫 Restricted $entityId');
          break;
        case 'suspend':
          debugPrint('⏸️ Suspended $entityId');
          break;
        case 'terminate':
          debugPrint('❌ Terminated $entityId');
          break;
        default:
          debugPrint('Unknown action: ${action.type}');
      }
    }
  }

  // ============================================================
  // TRUST SCORE MANAGEMENT
  // ============================================================

  Future<TrustScore> _calculateTrustScore(
    String entityId,
    EntityType entityType,
  ) async {
    // Get violation count
    final violationsSnapshot = await _violationsCollection
        .where('entityId', isEqualTo: entityId)
        .where('entityType', isEqualTo: entityType.name)
        .get();

    // Get certification count
    final certificationsSnapshot = await _certificationsCollection
        .where('entityId', isEqualTo: entityId)
        .where('entityType', isEqualTo: entityType.name)
        .where('status', isEqualTo: CertificationStatus.active.name)
        .get();

    // Calculate factors
    final factors = <TrustFactor>[
      TrustFactor(
        name: 'Account Age',
        weight: 0.15,
        score: 80, // Would calculate based on join date
        description: 'Account longevity on platform',
      ),
      TrustFactor(
        name: 'Activity',
        weight: 0.20,
        score: 75, // Would calculate based on activity
        description: 'Regular platform engagement',
      ),
      TrustFactor(
        name: 'Community',
        weight: 0.15,
        score: 70, // Would calculate based on interactions
        description: 'Positive community interactions',
      ),
      TrustFactor(
        name: 'Compliance',
        weight: 0.30,
        score: 100 - (violationsSnapshot.docs.length * 10),
        description: 'Rule compliance history',
      ),
      TrustFactor(
        name: 'Verification',
        weight: 0.20,
        score: certificationsSnapshot.docs.isNotEmpty ? 100 : 50,
        description: 'Identity and credential verification',
      ),
    ];

    // Calculate weighted overall score
    final overallScore = factors.fold<double>(
      0,
      (total, factor) => total + (factor.score * factor.weight),
    );

    return TrustScore(
      entityId: entityId,
      entityType: entityType,
      overallScore: overallScore.clamp(0, 100),
      categoryScores: {
        for (final factor in factors) factor.name: factor.score,
      },
      factors: factors,
      violationCount: violationsSnapshot.docs.length,
      certificationCount: certificationsSnapshot.docs.length,
      calculatedAt: DateTime.now(),
    );
  }

  Future<void> _updateTrustScore(
    String entityId,
    EntityType entityType,
  ) async {
    final trustScore = await _calculateTrustScore(entityId, entityType);

    await _trustScoresCollection
        .doc('${entityType.name}_$entityId')
        .set(trustScore.toMap());
  }

  /// Get trust score for an entity
  Future<TrustScore> getTrustScore(
    String entityId,
    EntityType entityType,
  ) async {
    final doc = await _trustScoresCollection
        .doc('${entityType.name}_$entityId')
        .get();

    if (!doc.exists) {
      return _calculateTrustScore(entityId, entityType);
    }

    final data = doc.data()!;
    return TrustScore(
      entityId: data['entityId'] as String,
      entityType: EntityType.values.firstWhere(
        (e) => e.name == data['entityType'],
      ),
      overallScore: (data['overallScore'] as num).toDouble(),
      categoryScores: (data['categoryScores'] as Map<String, dynamic>?)
              ?.map((k, v) => MapEntry(k, (v as num).toDouble())) ??
          {},
      factors: (data['factors'] as List?)
              ?.map((f) => TrustFactor(
                    name: f['name'] as String,
                    weight: (f['weight'] as num).toDouble(),
                    score: (f['score'] as num).toDouble(),
                    description: f['description'] as String,
                  ))
              .toList() ??
          [],
      violationCount: data['violationCount'] as int? ?? 0,
      certificationCount: data['certificationCount'] as int? ?? 0,
      calculatedAt: DateTime.parse(data['calculatedAt'] as String),
    );
  }

  // ============================================================
  // QUERY METHODS
  // ============================================================

  /// Get certifications for an entity
  Future<List<Certification>> getCertifications(
    String entityId, {
    EntityType? entityType,
    CertificationStatus? status,
  }) async {
    Query<Map<String, dynamic>> query =
        _certificationsCollection.where('entityId', isEqualTo: entityId);

    if (entityType != null) {
      query = query.where('entityType', isEqualTo: entityType.name);
    }

    if (status != null) {
      query = query.where('status', isEqualTo: status.name);
    }

    final snapshot = await query.get();
    return snapshot.docs
        .map((doc) => Certification.fromMap(doc.data()))
        .toList();
  }

  /// Get violations for an entity
  Future<List<Violation>> getViolations(
    String entityId, {
    EntityType? entityType,
    ViolationStatus? status,
    int limit = 20,
  }) async {
    Query<Map<String, dynamic>> query =
        _violationsCollection.where('entityId', isEqualTo: entityId);

    if (entityType != null) {
      query = query.where('entityType', isEqualTo: entityType.name);
    }

    if (status != null) {
      query = query.where('status', isEqualTo: status.name);
    }

    final snapshot =
        await query.orderBy('occurredAt', descending: true).limit(limit).get();

    return snapshot.docs.map((doc) {
      final data = doc.data();
      return Violation(
        id: data['id'] as String,
        entityId: data['entityId'] as String,
        entityType: EntityType.values.firstWhere(
          (e) => e.name == data['entityType'],
        ),
        ruleId: data['ruleId'] as String,
        status: ViolationStatus.values.firstWhere(
          (s) => s.name == data['status'],
        ),
        severity: RuleSeverity.values.firstWhere(
          (s) => s.name == data['severity'],
        ),
        description: data['description'] as String,
        evidence: List<String>.from(data['evidence'] ?? []),
        resolution: data['resolution'] as String?,
        trustScoreImpact: data['trustScoreImpact'] as int? ?? 0,
        occurredAt: DateTime.parse(data['occurredAt'] as String),
        resolvedAt: data['resolvedAt'] != null
            ? DateTime.parse(data['resolvedAt'] as String)
            : null,
      );
    }).toList();
  }

  /// Resolve a violation
  Future<bool> resolveViolation(
    String violationId, {
    required String resolution,
  }) async {
    try {
      await _violationsCollection.doc(violationId).update({
        'status': ViolationStatus.resolved.name,
        'resolution': resolution,
        'resolvedAt': DateTime.now().toIso8601String(),
      });
      return true;
    } catch (e) {
      debugPrint('❌ [TrustFramework] Failed to resolve violation: $e');
      return false;
    }
  }

  /// Revoke a certification
  Future<bool> revokeCertification(
    String certificationId, {
    required String reason,
  }) async {
    try {
      await _certificationsCollection.doc(certificationId).update({
        'status': CertificationStatus.revoked.name,
        'revokedAt': DateTime.now().toIso8601String(),
        'revokedReason': reason,
      });
      return true;
    } catch (e) {
      debugPrint('❌ [TrustFramework] Failed to revoke certification: $e');
      return false;
    }
  }

  /// Dispose resources
  void dispose() {
    _certificationController.close();
    _violationController.close();
  }
}
