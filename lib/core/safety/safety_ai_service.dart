/// Safety AI Service
///
/// AI-powered content moderation and safety features including
/// toxicity detection, harassment prevention, spam filtering,
/// underage user detection, and account risk flagging.
library;

import 'dart:async';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../analytics/analytics_service.dart';

/// Safety check result
class SafetyCheckResult {
  final String id;
  final SafetyCheckType type;
  final String contentId;
  final String? userId;
  final double confidenceScore;
  final bool isFlagged;
  final SafetySeverity severity;
  final List<String> detectedIssues;
  final Map<String, double> categoryScores;
  final SafetyAction recommendedAction;
  final DateTime timestamp;

  const SafetyCheckResult({
    required this.id,
    required this.type,
    required this.contentId,
    this.userId,
    required this.confidenceScore,
    required this.isFlagged,
    required this.severity,
    required this.detectedIssues,
    required this.categoryScores,
    required this.recommendedAction,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'type': type.name,
        'contentId': contentId,
        'userId': userId,
        'confidenceScore': confidenceScore,
        'isFlagged': isFlagged,
        'severity': severity.name,
        'detectedIssues': detectedIssues,
        'categoryScores': categoryScores,
        'recommendedAction': recommendedAction.name,
        'timestamp': timestamp.toIso8601String(),
      };
}

enum SafetyCheckType {
  message,
  username,
  bio,
  roomTitle,
  roomDescription,
  image,
  voice,
  behavior,
}

enum SafetySeverity {
  low,
  medium,
  high,
  critical,
}

enum SafetyAction {
  none,
  warn,
  filter,
  hide,
  delete,
  mute,
  tempBan,
  permaBan,
  escalate,
}

/// Account risk assessment
class AccountRiskAssessment {
  final String userId;
  final double overallRiskScore;
  final RiskLevel riskLevel;
  final Map<String, double> riskFactors;
  final List<String> flags;
  final List<SafetyAction> recommendedActions;
  final DateTime assessedAt;

  const AccountRiskAssessment({
    required this.userId,
    required this.overallRiskScore,
    required this.riskLevel,
    required this.riskFactors,
    required this.flags,
    required this.recommendedActions,
    required this.assessedAt,
  });

  Map<String, dynamic> toMap() => {
        'userId': userId,
        'overallRiskScore': overallRiskScore,
        'riskLevel': riskLevel.name,
        'riskFactors': riskFactors,
        'flags': flags,
        'recommendedActions': recommendedActions.map((a) => a.name).toList(),
        'assessedAt': assessedAt.toIso8601String(),
      };
}

enum RiskLevel {
  minimal,
  low,
  medium,
  high,
  critical,
}

/// Safety configuration
class SafetyConfig {
  final double toxicityThreshold;
  final double harassmentThreshold;
  final double spamThreshold;
  final double minAgeRequired;
  final bool autoModerateEnabled;
  final bool shadowBanEnabled;
  final int maxWarningsBeforeBan;

  const SafetyConfig({
    this.toxicityThreshold = 0.7,
    this.harassmentThreshold = 0.6,
    this.spamThreshold = 0.8,
    this.minAgeRequired = 18,
    this.autoModerateEnabled = true,
    this.shadowBanEnabled = true,
    this.maxWarningsBeforeBan = 3,
  });
}

/// Toxicity patterns for detection
class ToxicityPatterns {
  // Simplified patterns - in production use ML model
  static final List<String> severePatterns = [
    'hate_speech',
    'explicit_threat',
    'extreme_profanity',
  ];

  static final List<String> moderatePatterns = [
    'mild_profanity',
    'insult',
    'negative_stereotype',
  ];

  static final List<String> lowPatterns = [
    'rude_language',
    'sarcasm',
    'passive_aggressive',
  ];
}

/// Safety AI Service
class SafetyAIService {
  static SafetyAIService? _instance;
  static SafetyAIService get instance => _instance ??= SafetyAIService._();

  SafetyAIService._();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  SafetyConfig _config = const SafetyConfig();

  // Collections
  CollectionReference<Map<String, dynamic>> get _safetyChecksCollection =>
      _firestore.collection('safety_checks');

  CollectionReference<Map<String, dynamic>> get _riskAssessmentsCollection =>
      _firestore.collection('risk_assessments');

  CollectionReference<Map<String, dynamic>> get _userWarningsCollection =>
      _firestore.collection('user_warnings');

  CollectionReference<Map<String, dynamic>> get _bannedUsersCollection =>
      _firestore.collection('banned_users');

  // Stream controllers
  final _safetyAlertController =
      StreamController<SafetyCheckResult>.broadcast();
  final _riskAlertController =
      StreamController<AccountRiskAssessment>.broadcast();

  /// Stream of safety alerts
  Stream<SafetyCheckResult> get safetyAlerts => _safetyAlertController.stream;

  /// Stream of risk alerts
  Stream<AccountRiskAssessment> get riskAlerts => _riskAlertController.stream;

  /// Initialize the service
  Future<void> initialize({SafetyConfig? config}) async {
    if (config != null) {
      _config = config;
    }

    AnalyticsService.instance.logEvent(
      name: 'safety_ai_initialized',
      parameters: {
        'auto_moderate': _config.autoModerateEnabled,
      },
    );
  }

  /// Detect toxicity in text content
  Future<SafetyCheckResult> detectToxicity({
    required String content,
    required String contentId,
    required SafetyCheckType type,
    String? userId,
  }) async {
    // Simulated ML-based toxicity detection
    // In production, this would call an AI/ML service
    final analysisResult = await _analyzeTextForToxicity(content);

    final isFlagged =
        analysisResult['toxicityScore']! >= _config.toxicityThreshold;
    final severity = _calculateSeverity(analysisResult['toxicityScore']!);

    final result = SafetyCheckResult(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      type: type,
      contentId: contentId,
      userId: userId,
      confidenceScore: analysisResult['confidence']!,
      isFlagged: isFlagged,
      severity: severity,
      detectedIssues: analysisResult['issues'] as List<String>? ?? [],
      categoryScores: {
        'toxicity': analysisResult['toxicityScore']!,
        'profanity': analysisResult['profanityScore']!,
        'insult': analysisResult['insultScore']!,
        'threat': analysisResult['threatScore']!,
      },
      recommendedAction: _determineAction(severity, isFlagged),
      timestamp: DateTime.now(),
    );

    if (isFlagged) {
      await _safetyChecksCollection.add(result.toMap());
      _safetyAlertController.add(result);

      if (_config.autoModerateEnabled && userId != null) {
        await _handleAutoModeration(userId, result);
      }
    }

    AnalyticsService.instance.logEvent(
      name: 'toxicity_checked',
      parameters: {
        'type': type.name,
        'flagged': isFlagged,
        'severity': severity.name,
      },
    );

    return result;
  }

  /// Detect harassment patterns
  Future<SafetyCheckResult> detectHarassment({
    required String content,
    required String contentId,
    required SafetyCheckType type,
    String? userId,
    String? targetUserId,
  }) async {
    final analysisResult = await _analyzeForHarassment(content, targetUserId);

    final isFlagged =
        analysisResult['harassmentScore']! >= _config.harassmentThreshold;
    final severity = _calculateSeverity(analysisResult['harassmentScore']!);

    final result = SafetyCheckResult(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      type: type,
      contentId: contentId,
      userId: userId,
      confidenceScore: analysisResult['confidence']!,
      isFlagged: isFlagged,
      severity: severity,
      detectedIssues: analysisResult['patterns'] as List<String>? ?? [],
      categoryScores: {
        'harassment': analysisResult['harassmentScore']!,
        'targeting': analysisResult['targetingScore']!,
        'repetition': analysisResult['repetitionScore']!,
        'intimidation': analysisResult['intimidationScore']!,
      },
      recommendedAction: _determineAction(severity, isFlagged),
      timestamp: DateTime.now(),
    );

    if (isFlagged) {
      await _safetyChecksCollection.add(result.toMap());
      _safetyAlertController.add(result);

      if (_config.autoModerateEnabled && userId != null) {
        await _handleAutoModeration(userId, result);
      }
    }

    AnalyticsService.instance.logEvent(
      name: 'harassment_checked',
      parameters: {
        'type': type.name,
        'flagged': isFlagged,
        'severity': severity.name,
      },
    );

    return result;
  }

  /// Detect spam and automation
  Future<SafetyCheckResult> detectSpam({
    required String content,
    required String contentId,
    required SafetyCheckType type,
    String? userId,
  }) async {
    final analysisResult = await _analyzeForSpam(content, userId);

    final isFlagged = analysisResult['spamScore']! >= _config.spamThreshold;
    final severity = isFlagged ? SafetySeverity.medium : SafetySeverity.low;

    final result = SafetyCheckResult(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      type: type,
      contentId: contentId,
      userId: userId,
      confidenceScore: analysisResult['confidence']!,
      isFlagged: isFlagged,
      severity: severity,
      detectedIssues: analysisResult['indicators'] as List<String>? ?? [],
      categoryScores: {
        'spam': analysisResult['spamScore']!,
        'automation': analysisResult['automationScore']!,
        'repetition': analysisResult['repetitionScore']!,
        'promotion': analysisResult['promotionScore']!,
      },
      recommendedAction: isFlagged ? SafetyAction.filter : SafetyAction.none,
      timestamp: DateTime.now(),
    );

    if (isFlagged) {
      await _safetyChecksCollection.add(result.toMap());
      _safetyAlertController.add(result);
    }

    AnalyticsService.instance.logEvent(
      name: 'spam_checked',
      parameters: {
        'type': type.name,
        'flagged': isFlagged,
      },
    );

    return result;
  }

  /// Detect potential underage users
  Future<Map<String, dynamic>> detectUnderageUsers({
    required String userId,
  }) async {
    final userDoc = await _firestore.collection('users').doc(userId).get();
    if (!userDoc.exists) return {'detected': false, 'reason': 'User not found'};

    final userData = userDoc.data()!;
    final indicators = <String>[];
    double riskScore = 0;

    // Check stated age
    final birthDate = userData['birthDate'] as Timestamp?;
    if (birthDate != null) {
      final age = DateTime.now().difference(birthDate.toDate()).inDays / 365;
      if (age < _config.minAgeRequired) {
        indicators.add('stated_age_below_minimum');
        riskScore += 0.8;
      } else if (age < 21) {
        indicators.add('young_adult');
        riskScore += 0.2;
      }
    } else {
      indicators.add('no_age_provided');
      riskScore += 0.1;
    }

    // Analyze bio and username for age indicators
    final bio = userData['bio'] as String? ?? '';
    final username = userData['displayName'] as String? ?? '';

    final ageIndicatorScore = await _analyzeAgeIndicators(bio, username);
    if (ageIndicatorScore > 0.5) {
      indicators.add('content_suggests_minor');
      riskScore += ageIndicatorScore * 0.5;
    }

    // Check account behavior patterns
    final behaviorScore = await _analyzeBehaviorForAge(userId);
    if (behaviorScore > 0.5) {
      indicators.add('behavior_suggests_minor');
      riskScore += behaviorScore * 0.3;
    }

    final isDetected = riskScore >= 0.7;

    if (isDetected) {
      // Flag account for review
      await _firestore.collection('users').doc(userId).update({
        'ageVerificationRequired': true,
        'ageVerificationReason': indicators.join(', '),
      });

      AnalyticsService.instance.logEvent(
        name: 'underage_user_flagged',
        parameters: {
          'user_id': userId,
          'risk_score': riskScore,
        },
      );
    }

    return {
      'detected': isDetected,
      'riskScore': riskScore,
      'indicators': indicators,
      'requiresReview': isDetected,
    };
  }

  /// Auto-flag high-risk accounts
  Future<AccountRiskAssessment> autoFlagHighRiskAccounts({
    required String userId,
  }) async {
    final riskFactors = <String, double>{};
    final flags = <String>[];

    // Get user data
    final userDoc = await _firestore.collection('users').doc(userId).get();
    if (!userDoc.exists) {
      return AccountRiskAssessment(
        userId: userId,
        overallRiskScore: 0,
        riskLevel: RiskLevel.minimal,
        riskFactors: {},
        flags: ['user_not_found'],
        recommendedActions: [],
        assessedAt: DateTime.now(),
      );
    }

    final userData = userDoc.data()!;

    // Check account age
    final createdAt = userData['createdAt'] as Timestamp?;
    if (createdAt != null) {
      final accountAgeHours =
          DateTime.now().difference(createdAt.toDate()).inHours;
      if (accountAgeHours < 24) {
        riskFactors['new_account'] = 0.3;
        flags.add('account_less_than_24h');
      }
    }

    // Check previous violations
    final warningsSnapshot = await _userWarningsCollection
        .where('userId', isEqualTo: userId)
        .where('createdAt',
            isGreaterThan: Timestamp.fromDate(
                DateTime.now().subtract(const Duration(days: 30))))
        .get();

    if (warningsSnapshot.docs.isNotEmpty) {
      final warningCount = warningsSnapshot.docs.length;
      riskFactors['previous_warnings'] =
          (warningCount / _config.maxWarningsBeforeBan).clamp(0.0, 1.0);
      flags.add('has_recent_warnings:$warningCount');
    }

    // Check for ban history
    final banDoc = await _bannedUsersCollection.doc(userId).get();
    if (banDoc.exists) {
      final banData = banDoc.data()!;
      if (banData['type'] == 'permanent') {
        riskFactors['ban_evasion'] = 1.0;
        flags.add('previous_permanent_ban');
      } else if (banData['liftedAt'] != null) {
        riskFactors['previous_ban'] = 0.5;
        flags.add('previously_banned');
      }
    }

    // Check report count
    final reportsSnapshot = await _firestore
        .collection('reports')
        .where('reportedUserId', isEqualTo: userId)
        .where('createdAt',
            isGreaterThan: Timestamp.fromDate(
                DateTime.now().subtract(const Duration(days: 7))))
        .get();

    if (reportsSnapshot.docs.isNotEmpty) {
      final reportCount = reportsSnapshot.docs.length;
      riskFactors['recent_reports'] = (reportCount / 5).clamp(0.0, 1.0);
      flags.add('reported_$reportCount times');
    }

    // Check behavior metrics
    final behaviorScore = await _analyzeSuspiciousBehavior(userId);
    if (behaviorScore > 0.3) {
      riskFactors['suspicious_behavior'] = behaviorScore;
      flags.add('suspicious_patterns');
    }

    // Calculate overall risk
    double overallRisk = 0;
    for (final score in riskFactors.values) {
      overallRisk = max(overallRisk, score);
    }
    overallRisk = riskFactors.values.fold(0.0, (total, v) => total + v) /
        max(riskFactors.length, 1);

    final riskLevel = _determineRiskLevel(overallRisk);
    final actions = _determineRiskActions(riskLevel, flags);

    final assessment = AccountRiskAssessment(
      userId: userId,
      overallRiskScore: overallRisk,
      riskLevel: riskLevel,
      riskFactors: riskFactors,
      flags: flags,
      recommendedActions: actions,
      assessedAt: DateTime.now(),
    );

    // Save assessment
    await _riskAssessmentsCollection.doc(userId).set(assessment.toMap());

    // Alert if high risk
    if (riskLevel == RiskLevel.high || riskLevel == RiskLevel.critical) {
      _riskAlertController.add(assessment);
    }

    AnalyticsService.instance.logEvent(
      name: 'account_risk_assessed',
      parameters: {
        'user_id': userId,
        'risk_level': riskLevel.name,
        'overall_score': overallRisk,
      },
    );

    return assessment;
  }

  /// Content moderation for real-time content
  Future<SafetyCheckResult> moderateContent({
    required String content,
    required String contentId,
    required SafetyCheckType type,
    String? userId,
  }) async {
    // Run all checks in parallel
    final results = await Future.wait([
      detectToxicity(
          content: content, contentId: contentId, type: type, userId: userId),
      detectHarassment(
          content: content, contentId: contentId, type: type, userId: userId),
      detectSpam(
          content: content, contentId: contentId, type: type, userId: userId),
    ]);

    // Find the most severe result
    SafetyCheckResult? mostSevere;
    for (final result in results) {
      if (result.isFlagged) {
        if (mostSevere == null ||
            result.severity.index > mostSevere.severity.index) {
          mostSevere = result;
        }
      }
    }

    return mostSevere ?? results.first;
  }

  // Private helper methods

  Future<Map<String, dynamic>> _analyzeTextForToxicity(String content) async {
    // Simulated analysis - in production use ML model
    await Future.delayed(const Duration(milliseconds: 50));

    // Simple heuristic for demo
    final lowerContent = content.toLowerCase();
    double toxicity = 0;
    const double profanity = 0;
    double insult = 0;
    double threat = 0;
    final issues = <String>[];

    // Check for common patterns (simplified)
    if (lowerContent.contains('kill') || lowerContent.contains('die')) {
      threat = 0.7;
      issues.add('potential_threat');
    }
    if (lowerContent.contains('stupid') || lowerContent.contains('idiot')) {
      insult = 0.5;
      issues.add('insult_detected');
    }

    toxicity = (profanity + insult + threat) / 3;

    return {
      'toxicityScore': toxicity,
      'profanityScore': profanity,
      'insultScore': insult,
      'threatScore': threat,
      'confidence': 0.85,
      'issues': issues,
    };
  }

  Future<Map<String, dynamic>> _analyzeForHarassment(
      String content, String? targetId) async {
    await Future.delayed(const Duration(milliseconds: 50));

    double harassment = 0;
    double targeting = targetId != null ? 0.3 : 0;
    const double repetition = 0;
    const double intimidation = 0;
    final patterns = <String>[];

    // Simplified pattern detection
    if (content.contains('@') && targetId != null) {
      targeting += 0.2;
      patterns.add('direct_mention');
    }

    harassment = (targeting + repetition + intimidation) / 3;

    return {
      'harassmentScore': harassment,
      'targetingScore': targeting,
      'repetitionScore': repetition,
      'intimidationScore': intimidation,
      'confidence': 0.80,
      'patterns': patterns,
    };
  }

  Future<Map<String, dynamic>> _analyzeForSpam(
      String content, String? userId) async {
    await Future.delayed(const Duration(milliseconds: 50));

    double spam = 0;
    const double automation = 0;
    double repetition = 0;
    double promotion = 0;
    final indicators = <String>[];

    // Check for common spam patterns
    if (content.contains('http') || content.contains('www.')) {
      promotion += 0.4;
      indicators.add('contains_link');
    }
    if (content.length > 500) {
      spam += 0.2;
      indicators.add('long_message');
    }
    if (content.split(' ').toSet().length < content.split(' ').length * 0.5) {
      repetition += 0.3;
      indicators.add('repetitive_words');
    }

    spam = (promotion + repetition + automation) / 3;

    return {
      'spamScore': spam,
      'automationScore': automation,
      'repetitionScore': repetition,
      'promotionScore': promotion,
      'confidence': 0.75,
      'indicators': indicators,
    };
  }

  Future<double> _analyzeAgeIndicators(String bio, String username) async {
    // Simplified age indicator analysis
    double score = 0;

    final combinedText = '$bio $username'.toLowerCase();

    // Check for age mentions
    final agePattern = RegExp(r'\b(1[0-7])\s*(yo|years?\s*old|y\.o\.?)\b');
    if (agePattern.hasMatch(combinedText)) {
      score += 0.8;
    }

    // Check for school-related terms
    if (combinedText.contains('high school') ||
        combinedText.contains('freshman') ||
        combinedText.contains('sophomore')) {
      score += 0.5;
    }

    return score.clamp(0.0, 1.0);
  }

  Future<double> _analyzeBehaviorForAge(String userId) async {
    // Analyze user behavior patterns that might indicate age
    // This would use ML in production
    return 0.0; // Default to no indicators
  }

  Future<double> _analyzeSuspiciousBehavior(String userId) async {
    // Analyze for suspicious patterns
    // - Rapid account creation
    // - Mass messaging
    // - Unusual login patterns
    return 0.0; // Default to no suspicious behavior
  }

  SafetySeverity _calculateSeverity(double score) {
    if (score >= 0.9) return SafetySeverity.critical;
    if (score >= 0.7) return SafetySeverity.high;
    if (score >= 0.5) return SafetySeverity.medium;
    return SafetySeverity.low;
  }

  SafetyAction _determineAction(SafetySeverity severity, bool flagged) {
    if (!flagged) return SafetyAction.none;

    switch (severity) {
      case SafetySeverity.critical:
        return SafetyAction.permaBan;
      case SafetySeverity.high:
        return SafetyAction.tempBan;
      case SafetySeverity.medium:
        return SafetyAction.mute;
      case SafetySeverity.low:
        return SafetyAction.warn;
    }
  }

  RiskLevel _determineRiskLevel(double score) {
    if (score >= 0.8) return RiskLevel.critical;
    if (score >= 0.6) return RiskLevel.high;
    if (score >= 0.4) return RiskLevel.medium;
    if (score >= 0.2) return RiskLevel.low;
    return RiskLevel.minimal;
  }

  List<SafetyAction> _determineRiskActions(
      RiskLevel level, List<String> flags) {
    switch (level) {
      case RiskLevel.critical:
        return [SafetyAction.permaBan, SafetyAction.escalate];
      case RiskLevel.high:
        return [SafetyAction.tempBan, SafetyAction.escalate];
      case RiskLevel.medium:
        return [SafetyAction.warn, SafetyAction.mute];
      case RiskLevel.low:
        return [SafetyAction.warn];
      case RiskLevel.minimal:
        return [];
    }
  }

  Future<void> _handleAutoModeration(
      String userId, SafetyCheckResult result) async {
    // Add warning
    await _userWarningsCollection.add({
      'userId': userId,
      'checkId': result.id,
      'type': result.type.name,
      'severity': result.severity.name,
      'action': result.recommendedAction.name,
      'createdAt': FieldValue.serverTimestamp(),
    });

    // Check if user should be banned
    final warningsSnapshot = await _userWarningsCollection
        .where('userId', isEqualTo: userId)
        .where('createdAt',
            isGreaterThan: Timestamp.fromDate(
                DateTime.now().subtract(const Duration(days: 30))))
        .get();

    if (warningsSnapshot.docs.length >= _config.maxWarningsBeforeBan ||
        result.severity == SafetySeverity.critical) {
      await _applyBan(userId, result);
    }
  }

  Future<void> _applyBan(String userId, SafetyCheckResult result) async {
    final isPermanent = result.severity == SafetySeverity.critical;

    await _bannedUsersCollection.doc(userId).set({
      'userId': userId,
      'type': isPermanent ? 'permanent' : 'temporary',
      'reason': result.detectedIssues.join(', '),
      'severity': result.severity.name,
      'bannedAt': FieldValue.serverTimestamp(),
      'expiresAt': isPermanent
          ? null
          : Timestamp.fromDate(DateTime.now().add(const Duration(days: 7))),
    });

    // Update user document
    await _firestore.collection('users').doc(userId).update({
      'isBanned': true,
      'banType': isPermanent ? 'permanent' : 'temporary',
    });

    AnalyticsService.instance.logEvent(
      name: 'user_banned',
      parameters: {
        'user_id': userId,
        'type': isPermanent ? 'permanent' : 'temporary',
        'reason': result.severity.name,
      },
    );
  }

  /// Dispose resources
  void dispose() {
    _safetyAlertController.close();
    _riskAlertController.close();
  }
}
