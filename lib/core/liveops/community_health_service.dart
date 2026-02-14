/// Community Health Service
///
/// Monitors and maintains community health by detecting toxic behavior,
/// spam, harassment, and automatically taking moderation actions.
library;

import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../analytics/analytics_service.dart';

/// Types of violations detected
enum ViolationType {
  toxicLanguage,
  spam,
  harassment,
  inappropriateContent,
  impersonation,
  scam,
  hateSpeech,
  bullying,
  explicitContent,
  threatOfViolence,
  minorSafety,
  privacyViolation,
}

/// Severity of community violations
enum ViolationSeverity {
  low, // Warning
  medium, // Temporary mute
  high, // Extended mute + review
  critical, // Immediate action + escalation
}

/// Moderation actions that can be taken
enum ModerationAction {
  warn,
  mute,
  kick,
  ban,
  shadowBan,
  contentRemoval,
  accountRestriction,
  escalateToHuman,
}

/// Status of a moderation case
enum ModerationCaseStatus {
  open,
  underReview,
  actionTaken,
  dismissed,
  escalated,
  appealed,
  resolved,
}

/// Model for detected violations
class DetectedViolation {
  final String id;
  final ViolationType type;
  final ViolationSeverity severity;
  final String offenderId;
  final String? targetId;
  final String? roomId;
  final String? contentId;
  final String contentSnippet;
  final double confidenceScore;
  final DateTime detectedAt;
  final Map<String, dynamic> analysisDetails;

  const DetectedViolation({
    required this.id,
    required this.type,
    required this.severity,
    required this.offenderId,
    this.targetId,
    this.roomId,
    this.contentId,
    required this.contentSnippet,
    required this.confidenceScore,
    required this.detectedAt,
    this.analysisDetails = const {},
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'type': type.name,
    'severity': severity.name,
    'offenderId': offenderId,
    'targetId': targetId,
    'roomId': roomId,
    'contentId': contentId,
    'contentSnippet': contentSnippet,
    'confidenceScore': confidenceScore,
    'detectedAt': detectedAt.toIso8601String(),
    'analysisDetails': analysisDetails,
  };
}

/// Model for moderation cases
class ModerationCase {
  final String id;
  final String offenderId;
  final String? targetId;
  final String? roomId;
  final ViolationType violationType;
  final ViolationSeverity severity;
  final ModerationCaseStatus status;
  final List<ModerationAction> actionsTaken;
  final String? reviewerId;
  final String? notes;
  final DateTime createdAt;
  final DateTime? resolvedAt;
  final List<String> relatedViolationIds;

  const ModerationCase({
    required this.id,
    required this.offenderId,
    this.targetId,
    this.roomId,
    required this.violationType,
    required this.severity,
    required this.status,
    this.actionsTaken = const [],
    this.reviewerId,
    this.notes,
    required this.createdAt,
    this.resolvedAt,
    this.relatedViolationIds = const [],
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'offenderId': offenderId,
    'targetId': targetId,
    'roomId': roomId,
    'violationType': violationType.name,
    'severity': severity.name,
    'status': status.name,
    'actionsTaken': actionsTaken.map((a) => a.name).toList(),
    'reviewerId': reviewerId,
    'notes': notes,
    'createdAt': createdAt.toIso8601String(),
    'resolvedAt': resolvedAt?.toIso8601String(),
    'relatedViolationIds': relatedViolationIds,
  };
}

/// User trust score and history
class UserTrustProfile {
  final String userId;
  final double trustScore;
  final int totalViolations;
  final int recentViolations;
  final DateTime? lastViolation;
  final bool isRestricted;
  final DateTime? restrictedUntil;
  final List<String> activeRestrictions;
  final Map<ViolationType, int> violationsByType;

  const UserTrustProfile({
    required this.userId,
    required this.trustScore,
    this.totalViolations = 0,
    this.recentViolations = 0,
    this.lastViolation,
    this.isRestricted = false,
    this.restrictedUntil,
    this.activeRestrictions = const [],
    this.violationsByType = const {},
  });

  bool get isHighRisk => trustScore < 0.3 || recentViolations >= 3;

  Map<String, dynamic> toMap() => {
    'userId': userId,
    'trustScore': trustScore,
    'totalViolations': totalViolations,
    'recentViolations': recentViolations,
    'lastViolation': lastViolation?.toIso8601String(),
    'isRestricted': isRestricted,
    'restrictedUntil': restrictedUntil?.toIso8601String(),
    'activeRestrictions': activeRestrictions,
    'violationsByType': violationsByType.map((k, v) => MapEntry(k.name, v)),
  };
}

/// Service for monitoring and maintaining community health
class CommunityHealthService {
  static CommunityHealthService? _instance;
  static CommunityHealthService get instance => _instance ??= CommunityHealthService._();

  CommunityHealthService._();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Collections
  CollectionReference<Map<String, dynamic>> get _violationsCollection =>
      _firestore.collection('community_violations');

  CollectionReference<Map<String, dynamic>> get _casesCollection =>
      _firestore.collection('moderation_cases');

  CollectionReference<Map<String, dynamic>> get _trustProfilesCollection =>
      _firestore.collection('user_trust_profiles');

  CollectionReference<Map<String, dynamic>> get _actionLogsCollection =>
      _firestore.collection('moderation_action_logs');

  // Cache
  final Map<String, UserTrustProfile> _trustProfileCache = {};
  final List<DetectedViolation> _recentViolations = [];

  // Stream controllers
  final _violationController = StreamController<DetectedViolation>.broadcast();
  final _actionController = StreamController<ModerationAction>.broadcast();
  final _escalationController = StreamController<ModerationCase>.broadcast();

  /// Stream of detected violations
  Stream<DetectedViolation> get violationStream => _violationController.stream;

  /// Stream of moderation actions
  Stream<ModerationAction> get actionStream => _actionController.stream;

  /// Stream of escalations
  Stream<ModerationCase> get escalationStream => _escalationController.stream;

  // Toxic patterns (basic - real implementation would use ML)
  static const List<String> _toxicPatterns = [
    'hate', 'kill', 'die', 'stupid', 'idiot', 'dumb', 'ugly',
    'racist', 'sexist', 'homophobic', 'slur',
  ];

  static const List<String> _spamPatterns = [
    'free coins', 'click here', 'follow me', 'dm me', 'check bio',
    'http://', 'https://', '.com', 'discount', 'promo code',
  ];

  static const List<String> _harassmentPatterns = [
    'stalk', 'follow you', 'find you', 'know where', 'watch you',
    'hurt you', 'come for you',
  ];

  /// Initialize the service
  Future<void> initialize() async {
    AnalyticsService.instance.logEvent(
      name: 'community_health_initialized',
      parameters: {},
    );
  }

  /// Detect toxic behavior in content
  Future<DetectedViolation?> detectToxicBehavior({
    required String content,
    required String userId,
    String? targetId,
    String? roomId,
    String? contentId,
  }) async {
    final lowerContent = content.toLowerCase();

    // Check for toxic patterns
    final toxicMatches = _toxicPatterns
        .where((p) => lowerContent.contains(p))
        .toList();

    if (toxicMatches.isEmpty) return null;

    // Calculate confidence based on number of matches and content length
    final confidence = (toxicMatches.length / _toxicPatterns.length)
        .clamp(0.3, 0.95);

    // Determine severity
    ViolationSeverity severity;
    if (toxicMatches.length >= 3 || confidence > 0.7) {
      severity = ViolationSeverity.high;
    } else if (toxicMatches.length >= 2 || confidence > 0.5) {
      severity = ViolationSeverity.medium;
    } else {
      severity = ViolationSeverity.low;
    }

    final violation = await _recordViolation(
      type: ViolationType.toxicLanguage,
      severity: severity,
      offenderId: userId,
      targetId: targetId,
      roomId: roomId,
      contentId: contentId,
      contentSnippet: content.length > 100 ? '${content.substring(0, 100)}...' : content,
      confidenceScore: confidence,
      analysisDetails: {
        'matchedPatterns': toxicMatches,
        'patternCount': toxicMatches.length,
      },
    );

    // Auto-action based on severity
    await _autoModerate(violation);

    return violation;
  }

  /// Detect spam in content
  Future<DetectedViolation?> detectSpam({
    required String content,
    required String userId,
    String? roomId,
    String? contentId,
    int? messageCount,
    Duration? timeWindow,
  }) async {
    final lowerContent = content.toLowerCase();

    // Check for spam patterns
    final spamMatches = _spamPatterns
        .where((p) => lowerContent.contains(p))
        .toList();

    // Check for repetitive content
    final isRepetitive = await _checkRepetitiveContent(
      userId: userId,
      content: content,
      messageCount: messageCount ?? 5,
      timeWindow: timeWindow ?? const Duration(minutes: 1),
    );

    if (spamMatches.isEmpty && !isRepetitive) return null;

    final confidence = isRepetitive
        ? 0.9
        : (spamMatches.length / _spamPatterns.length).clamp(0.3, 0.85);

    final severity = isRepetitive || spamMatches.length >= 2
        ? ViolationSeverity.medium
        : ViolationSeverity.low;

    final violation = await _recordViolation(
      type: ViolationType.spam,
      severity: severity,
      offenderId: userId,
      roomId: roomId,
      contentId: contentId,
      contentSnippet: content.length > 100 ? '${content.substring(0, 100)}...' : content,
      confidenceScore: confidence,
      analysisDetails: {
        'matchedPatterns': spamMatches,
        'isRepetitive': isRepetitive,
      },
    );

    await _autoModerate(violation);

    return violation;
  }

  /// Detect harassment patterns
  Future<DetectedViolation?> detectHarassment({
    required String content,
    required String userId,
    required String targetId,
    String? roomId,
    String? contentId,
  }) async {
    final lowerContent = content.toLowerCase();

    // Check for harassment patterns
    final harassmentMatches = _harassmentPatterns
        .where((p) => lowerContent.contains(p))
        .toList();

    // Check interaction history for repeated targeting
    final targetingHistory = await _checkTargetingHistory(
      userId: userId,
      targetId: targetId,
    );

    if (harassmentMatches.isEmpty && !targetingHistory) return null;

    final confidence = targetingHistory
        ? 0.85
        : (harassmentMatches.length / _harassmentPatterns.length).clamp(0.4, 0.9);

    ViolationSeverity severity;
    if (targetingHistory && harassmentMatches.isNotEmpty) {
      severity = ViolationSeverity.critical;
    } else if (targetingHistory || harassmentMatches.length >= 2) {
      severity = ViolationSeverity.high;
    } else {
      severity = ViolationSeverity.medium;
    }

    final violation = await _recordViolation(
      type: ViolationType.harassment,
      severity: severity,
      offenderId: userId,
      targetId: targetId,
      roomId: roomId,
      contentId: contentId,
      contentSnippet: content.length > 100 ? '${content.substring(0, 100)}...' : content,
      confidenceScore: confidence,
      analysisDetails: {
        'matchedPatterns': harassmentMatches,
        'hasTargetingHistory': targetingHistory,
      },
    );

    await _autoModerate(violation);

    return violation;
  }

  /// Auto-mute offenders based on violations
  Future<bool> autoMuteOffenders({
    required String userId,
    required String roomId,
    Duration? duration,
  }) async {
    final profile = await getUserTrustProfile(userId);

    // Determine mute duration based on history
    final muteDuration = duration ?? _calculateMuteDuration(profile);

    try {
      // Update room to mute user
      await _firestore.collection('rooms').doc(roomId).update({
        'mutedUsers': FieldValue.arrayUnion([{
          'userId': userId,
          'mutedUntil': Timestamp.fromDate(DateTime.now().add(muteDuration)),
          'reason': 'auto_moderation',
        }]),
      });

      // Log action
      await _logModerationAction(
        action: ModerationAction.mute,
        targetUserId: userId,
        roomId: roomId,
        details: {
          'duration_minutes': muteDuration.inMinutes,
          'automated': true,
        },
      );

      _actionController.add(ModerationAction.mute);

      AnalyticsService.instance.logEvent(
        name: 'user_auto_muted',
        parameters: {
          'user_id': userId,
          'room_id': roomId,
          'duration_minutes': muteDuration.inMinutes,
        },
      );

      return true;
    } catch (e) {
      return false;
    }
  }

  /// Escalate to human moderators
  Future<ModerationCase> escalateToModerators({
    required String offenderId,
    required ViolationType violationType,
    required ViolationSeverity severity,
    String? targetId,
    String? roomId,
    List<String> relatedViolationIds = const [],
    String? notes,
  }) async {
    final docRef = _casesCollection.doc();

    final moderationCase = ModerationCase(
      id: docRef.id,
      offenderId: offenderId,
      targetId: targetId,
      roomId: roomId,
      violationType: violationType,
      severity: severity,
      status: ModerationCaseStatus.escalated,
      createdAt: DateTime.now(),
      relatedViolationIds: relatedViolationIds,
      notes: notes,
    );

    await docRef.set(moderationCase.toMap());

    _escalationController.add(moderationCase);

    // Notify moderators (would integrate with notification system)
    AnalyticsService.instance.logEvent(
      name: 'case_escalated',
      parameters: {
        'case_id': moderationCase.id,
        'violation_type': violationType.name,
        'severity': severity.name,
      },
    );

    return moderationCase;
  }

  /// Get user's trust profile
  Future<UserTrustProfile> getUserTrustProfile(String userId) async {
    // Check cache
    if (_trustProfileCache.containsKey(userId)) {
      return _trustProfileCache[userId]!;
    }

    // Fetch from Firestore
    final doc = await _trustProfilesCollection.doc(userId).get();

    if (!doc.exists) {
      // Create default profile for new users
      final profile = UserTrustProfile(
        userId: userId,
        trustScore: 1.0,
      );
      await _trustProfilesCollection.doc(userId).set(profile.toMap());
      _trustProfileCache[userId] = profile;
      return profile;
    }

    final data = doc.data()!;
    final profile = UserTrustProfile(
      userId: userId,
      trustScore: (data['trustScore'] as num?)?.toDouble() ?? 1.0,
      totalViolations: data['totalViolations'] ?? 0,
      recentViolations: data['recentViolations'] ?? 0,
      lastViolation: data['lastViolation'] != null
          ? DateTime.parse(data['lastViolation'])
          : null,
      isRestricted: data['isRestricted'] ?? false,
      restrictedUntil: data['restrictedUntil'] != null
          ? DateTime.parse(data['restrictedUntil'])
          : null,
      activeRestrictions: List<String>.from(data['activeRestrictions'] ?? []),
      violationsByType: (data['violationsByType'] as Map<String, dynamic>?)
          ?.map((k, v) => MapEntry(
                ViolationType.values.firstWhere((e) => e.name == k),
                v as int,
              )) ??
          {},
    );

    _trustProfileCache[userId] = profile;
    return profile;
  }

  /// Update user trust score
  Future<void> updateTrustScore(String userId, double adjustment) async {
    final profile = await getUserTrustProfile(userId);
    final newScore = (profile.trustScore + adjustment).clamp(0.0, 1.0);

    await _trustProfilesCollection.doc(userId).update({
      'trustScore': newScore,
      'lastUpdated': FieldValue.serverTimestamp(),
    });

    // Invalidate cache
    _trustProfileCache.remove(userId);
  }

  /// Check content before posting (pre-moderation)
  Future<Map<String, dynamic>> preModerateContent({
    required String content,
    required String userId,
    String? targetId,
    String? roomId,
  }) async {
    final results = <String, dynamic>{
      'allowed': true,
      'warnings': <String>[],
      'blocked': false,
      'blockReason': null,
    };

    // Check user trust score
    final profile = await getUserTrustProfile(userId);
    if (profile.isRestricted) {
      results['allowed'] = false;
      results['blocked'] = true;
      results['blockReason'] = 'Account restricted';
      return results;
    }

    // Run all detections
    final toxicResult = await detectToxicBehavior(
      content: content,
      userId: userId,
      targetId: targetId,
      roomId: roomId,
    );

    if (toxicResult != null) {
      if (toxicResult.severity == ViolationSeverity.critical ||
          toxicResult.severity == ViolationSeverity.high) {
        results['allowed'] = false;
        results['blocked'] = true;
        results['blockReason'] = 'Content violates community guidelines';
      } else {
        results['warnings'].add('Content may be flagged for review');
      }
    }

    return results;
  }

  /// Get community health metrics
  Future<Map<String, dynamic>> getCommunityHealthMetrics({
    Duration window = const Duration(days: 1),
  }) async {
    final startTime = DateTime.now().subtract(window);

    final violationsSnapshot = await _violationsCollection
        .where('detectedAt', isGreaterThan: Timestamp.fromDate(startTime))
        .get();

    final casesSnapshot = await _casesCollection
        .where('createdAt', isGreaterThan: Timestamp.fromDate(startTime))
        .get();

    // Calculate metrics
    final violationsByType = <ViolationType, int>{};
    final violationsBySeverity = <ViolationSeverity, int>{};

    for (final doc in violationsSnapshot.docs) {
      final type = ViolationType.values.firstWhere(
        (t) => t.name == doc.data()['type'],
        orElse: () => ViolationType.toxicLanguage,
      );
      final severity = ViolationSeverity.values.firstWhere(
        (s) => s.name == doc.data()['severity'],
        orElse: () => ViolationSeverity.low,
      );

      violationsByType[type] = (violationsByType[type] ?? 0) + 1;
      violationsBySeverity[severity] = (violationsBySeverity[severity] ?? 0) + 1;
    }

    return {
      'totalViolations': violationsSnapshot.docs.length,
      'totalCases': casesSnapshot.docs.length,
      'violationsByType': violationsByType.map((k, v) => MapEntry(k.name, v)),
      'violationsBySeverity': violationsBySeverity.map((k, v) => MapEntry(k.name, v)),
      'escalatedCases': casesSnapshot.docs
          .where((d) => d.data()['status'] == ModerationCaseStatus.escalated.name)
          .length,
      'resolvedCases': casesSnapshot.docs
          .where((d) => d.data()['status'] == ModerationCaseStatus.resolved.name)
          .length,
      'window': window.inHours,
    };
  }

  // Private methods

  Future<DetectedViolation> _recordViolation({
    required ViolationType type,
    required ViolationSeverity severity,
    required String offenderId,
    String? targetId,
    String? roomId,
    String? contentId,
    required String contentSnippet,
    required double confidenceScore,
    Map<String, dynamic> analysisDetails = const {},
  }) async {
    final docRef = _violationsCollection.doc();

    final violation = DetectedViolation(
      id: docRef.id,
      type: type,
      severity: severity,
      offenderId: offenderId,
      targetId: targetId,
      roomId: roomId,
      contentId: contentId,
      contentSnippet: contentSnippet,
      confidenceScore: confidenceScore,
      detectedAt: DateTime.now(),
      analysisDetails: analysisDetails,
    );

    await docRef.set(violation.toMap());

    // Update user profile
    await _updateUserViolationHistory(offenderId, type);

    _recentViolations.insert(0, violation);
    if (_recentViolations.length > 100) {
      _recentViolations.removeRange(100, _recentViolations.length);
    }

    _violationController.add(violation);

    return violation;
  }

  Future<void> _autoModerate(DetectedViolation violation) async {
    switch (violation.severity) {
      case ViolationSeverity.low:
        // Just record, no action
        break;

      case ViolationSeverity.medium:
        // Auto-mute for short duration
        if (violation.roomId != null) {
          await autoMuteOffenders(
            userId: violation.offenderId,
            roomId: violation.roomId!,
            duration: const Duration(minutes: 5),
          );
        }
        break;

      case ViolationSeverity.high:
        // Auto-mute for longer duration
        if (violation.roomId != null) {
          await autoMuteOffenders(
            userId: violation.offenderId,
            roomId: violation.roomId!,
            duration: const Duration(minutes: 30),
          );
        }
        // Reduce trust score
        await updateTrustScore(violation.offenderId, -0.1);
        break;

      case ViolationSeverity.critical:
        // Escalate to moderators
        await escalateToModerators(
          offenderId: violation.offenderId,
          violationType: violation.type,
          severity: violation.severity,
          targetId: violation.targetId,
          roomId: violation.roomId,
          relatedViolationIds: [violation.id],
        );
        // Significant trust score reduction
        await updateTrustScore(violation.offenderId, -0.3);
        break;
    }
  }

  Future<void> _updateUserViolationHistory(
    String userId,
    ViolationType type,
  ) async {
    await _trustProfilesCollection.doc(userId).set({
      'totalViolations': FieldValue.increment(1),
      'recentViolations': FieldValue.increment(1),
      'lastViolation': DateTime.now().toIso8601String(),
      'violationsByType.${type.name}': FieldValue.increment(1),
    }, SetOptions(merge: true));

    // Invalidate cache
    _trustProfileCache.remove(userId);
  }

  Future<bool> _checkRepetitiveContent({
    required String userId,
    required String content,
    required int messageCount,
    required Duration timeWindow,
  }) async {
    // In a real implementation, this would check recent messages
    // For now, return false as placeholder
    return false;
  }

  Future<bool> _checkTargetingHistory({
    required String userId,
    required String targetId,
  }) async {
    final recentViolations = await _violationsCollection
        .where('offenderId', isEqualTo: userId)
        .where('targetId', isEqualTo: targetId)
        .orderBy('detectedAt', descending: true)
        .limit(5)
        .get();

    return recentViolations.docs.length >= 2;
  }

  Duration _calculateMuteDuration(UserTrustProfile profile) {
    if (profile.recentViolations >= 5) {
      return const Duration(hours: 24);
    } else if (profile.recentViolations >= 3) {
      return const Duration(hours: 1);
    } else if (profile.recentViolations >= 2) {
      return const Duration(minutes: 30);
    } else {
      return const Duration(minutes: 5);
    }
  }

  Future<void> _logModerationAction({
    required ModerationAction action,
    required String targetUserId,
    String? roomId,
    Map<String, dynamic>? details,
  }) async {
    await _actionLogsCollection.add({
      'action': action.name,
      'targetUserId': targetUserId,
      'roomId': roomId,
      'performedBy': _auth.currentUser?.uid ?? 'system',
      'timestamp': FieldValue.serverTimestamp(),
      'details': details ?? {},
    });
  }

  /// Dispose resources
  void dispose() {
    _violationController.close();
    _actionController.close();
    _escalationController.close();
  }
}
