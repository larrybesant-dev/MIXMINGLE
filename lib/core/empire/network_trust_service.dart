/// Network Trust Service
///
/// Provides global ban propagation, cross-app safety signals, federated toxicity detection,
/// and global appeals system.
library;

import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

/// Trust level
enum TrustLevel {
  unknown,
  untrusted,
  limited,
  standard,
  verified,
  trusted,
}

/// Ban type
enum BanType {
  local,
  network,
  global,
  permanent,
}

/// Ban status
enum BanStatus {
  active,
  appealed,
  overturned,
  expired,
}

/// Safety signal type
enum SafetySignalType {
  harassment,
  spam,
  scam,
  impersonation,
  csam,
  terrorism,
  violence,
  hateSpeech,
  selfHarm,
  other,
}

/// Appeal status
enum AppealStatus {
  pending,
  underReview,
  approved,
  denied,
  escalated,
}

/// Toxicity severity
enum ToxicitySeverity {
  low,
  medium,
  high,
  severe,
  critical,
}

/// Network ban
class NetworkBan {
  final String banId;
  final String userId;
  final BanType type;
  final BanStatus status;
  final SafetySignalType reason;
  final String description;
  final String issuedBy;
  final DateTime issuedAt;
  final DateTime? expiresAt;
  final List<String> originPartners;
  final List<String> propagatedTo;
  final Map<String, dynamic> evidence;

  const NetworkBan({
    required this.banId,
    required this.userId,
    required this.type,
    required this.status,
    required this.reason,
    required this.description,
    required this.issuedBy,
    required this.issuedAt,
    this.expiresAt,
    this.originPartners = const [],
    this.propagatedTo = const [],
    this.evidence = const {},
  });

  factory NetworkBan.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return NetworkBan(
      banId: doc.id,
      userId: data['userId'] ?? '',
      type: BanType.values.firstWhere(
        (t) => t.name == data['type'],
        orElse: () => BanType.local,
      ),
      status: BanStatus.values.firstWhere(
        (s) => s.name == data['status'],
        orElse: () => BanStatus.active,
      ),
      reason: SafetySignalType.values.firstWhere(
        (r) => r.name == data['reason'],
        orElse: () => SafetySignalType.other,
      ),
      description: data['description'] ?? '',
      issuedBy: data['issuedBy'] ?? '',
      issuedAt: (data['issuedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      expiresAt: (data['expiresAt'] as Timestamp?)?.toDate(),
      originPartners: List<String>.from(data['originPartners'] ?? []),
      propagatedTo: List<String>.from(data['propagatedTo'] ?? []),
      evidence: Map<String, dynamic>.from(data['evidence'] ?? {}),
    );
  }

  Map<String, dynamic> toFirestore() => {
        'userId': userId,
        'type': type.name,
        'status': status.name,
        'reason': reason.name,
        'description': description,
        'issuedBy': issuedBy,
        'issuedAt': Timestamp.fromDate(issuedAt),
        'expiresAt': expiresAt != null ? Timestamp.fromDate(expiresAt!) : null,
        'originPartners': originPartners,
        'propagatedTo': propagatedTo,
        'evidence': evidence,
      };

  bool get isExpired => expiresAt != null && DateTime.now().isAfter(expiresAt!);
  bool get isActive => status == BanStatus.active && !isExpired;
}

/// Cross-app safety signal
class SafetySignal {
  final String signalId;
  final String userId;
  final SafetySignalType type;
  final ToxicitySeverity severity;
  final String sourceApp;
  final String description;
  final double confidenceScore;
  final DateTime detectedAt;
  final DateTime? expiresAt;
  final Map<String, dynamic> context;

  const SafetySignal({
    required this.signalId,
    required this.userId,
    required this.type,
    required this.severity,
    required this.sourceApp,
    required this.description,
    required this.confidenceScore,
    required this.detectedAt,
    this.expiresAt,
    this.context = const {},
  });

  factory SafetySignal.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return SafetySignal(
      signalId: doc.id,
      userId: data['userId'] ?? '',
      type: SafetySignalType.values.firstWhere(
        (t) => t.name == data['type'],
        orElse: () => SafetySignalType.other,
      ),
      severity: ToxicitySeverity.values.firstWhere(
        (s) => s.name == data['severity'],
        orElse: () => ToxicitySeverity.low,
      ),
      sourceApp: data['sourceApp'] ?? '',
      description: data['description'] ?? '',
      confidenceScore: (data['confidenceScore'] ?? 0.0).toDouble(),
      detectedAt: (data['detectedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      expiresAt: (data['expiresAt'] as Timestamp?)?.toDate(),
      context: Map<String, dynamic>.from(data['context'] ?? {}),
    );
  }

  Map<String, dynamic> toFirestore() => {
        'userId': userId,
        'type': type.name,
        'severity': severity.name,
        'sourceApp': sourceApp,
        'description': description,
        'confidenceScore': confidenceScore,
        'detectedAt': Timestamp.fromDate(detectedAt),
        'expiresAt': expiresAt != null ? Timestamp.fromDate(expiresAt!) : null,
        'context': context,
      };
}

/// Toxicity detection result
class ToxicityResult {
  final String analysisId;
  final String contentId;
  final String contentType;
  final bool isToxic;
  final ToxicitySeverity severity;
  final Map<SafetySignalType, double> categoryScores;
  final double overallScore;
  final List<String> flaggedPhrases;
  final DateTime analyzedAt;
  final String modelVersion;

  const ToxicityResult({
    required this.analysisId,
    required this.contentId,
    required this.contentType,
    required this.isToxic,
    required this.severity,
    required this.categoryScores,
    required this.overallScore,
    this.flaggedPhrases = const [],
    required this.analyzedAt,
    required this.modelVersion,
  });

  factory ToxicityResult.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ToxicityResult(
      analysisId: doc.id,
      contentId: data['contentId'] ?? '',
      contentType: data['contentType'] ?? '',
      isToxic: data['isToxic'] ?? false,
      severity: ToxicitySeverity.values.firstWhere(
        (s) => s.name == data['severity'],
        orElse: () => ToxicitySeverity.low,
      ),
      categoryScores: (data['categoryScores'] as Map<String, dynamic>? ?? {}).map(
        (k, v) => MapEntry(
          SafetySignalType.values.firstWhere(
            (t) => t.name == k,
            orElse: () => SafetySignalType.other,
          ),
          (v as num).toDouble(),
        ),
      ),
      overallScore: (data['overallScore'] ?? 0.0).toDouble(),
      flaggedPhrases: List<String>.from(data['flaggedPhrases'] ?? []),
      analyzedAt: (data['analyzedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      modelVersion: data['modelVersion'] ?? '1.0',
    );
  }

  Map<String, dynamic> toFirestore() => {
        'contentId': contentId,
        'contentType': contentType,
        'isToxic': isToxic,
        'severity': severity.name,
        'categoryScores': categoryScores.map((k, v) => MapEntry(k.name, v)),
        'overallScore': overallScore,
        'flaggedPhrases': flaggedPhrases,
        'analyzedAt': Timestamp.fromDate(analyzedAt),
        'modelVersion': modelVersion,
      };
}

/// Appeal
class Appeal {
  final String appealId;
  final String userId;
  final String banId;
  final AppealStatus status;
  final String reason;
  final String? additionalContext;
  final DateTime submittedAt;
  final DateTime? reviewedAt;
  final String? reviewedBy;
  final String? reviewNotes;
  final List<String> attachments;

  const Appeal({
    required this.appealId,
    required this.userId,
    required this.banId,
    required this.status,
    required this.reason,
    this.additionalContext,
    required this.submittedAt,
    this.reviewedAt,
    this.reviewedBy,
    this.reviewNotes,
    this.attachments = const [],
  });

  factory Appeal.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Appeal(
      appealId: doc.id,
      userId: data['userId'] ?? '',
      banId: data['banId'] ?? '',
      status: AppealStatus.values.firstWhere(
        (s) => s.name == data['status'],
        orElse: () => AppealStatus.pending,
      ),
      reason: data['reason'] ?? '',
      additionalContext: data['additionalContext'],
      submittedAt: (data['submittedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      reviewedAt: (data['reviewedAt'] as Timestamp?)?.toDate(),
      reviewedBy: data['reviewedBy'],
      reviewNotes: data['reviewNotes'],
      attachments: List<String>.from(data['attachments'] ?? []),
    );
  }

  Map<String, dynamic> toFirestore() => {
        'userId': userId,
        'banId': banId,
        'status': status.name,
        'reason': reason,
        'additionalContext': additionalContext,
        'submittedAt': Timestamp.fromDate(submittedAt),
        'reviewedAt': reviewedAt != null ? Timestamp.fromDate(reviewedAt!) : null,
        'reviewedBy': reviewedBy,
        'reviewNotes': reviewNotes,
        'attachments': attachments,
      };
}

/// User trust profile
class UserTrustProfile {
  final String userId;
  final TrustLevel level;
  final double trustScore;
  final int totalReports;
  final int confirmedViolations;
  final int appealsWon;
  final int appealsLost;
  final List<NetworkBan> activeBans;
  final List<SafetySignal> recentSignals;
  final DateTime lastUpdated;

  const UserTrustProfile({
    required this.userId,
    required this.level,
    required this.trustScore,
    this.totalReports = 0,
    this.confirmedViolations = 0,
    this.appealsWon = 0,
    this.appealsLost = 0,
    this.activeBans = const [],
    this.recentSignals = const [],
    required this.lastUpdated,
  });
}

/// Network trust service singleton
class NetworkTrustService {
  static NetworkTrustService? _instance;
  static NetworkTrustService get instance => _instance ??= NetworkTrustService._();

  NetworkTrustService._();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference get _bansCollection =>
      _firestore.collection('network_bans');
  CollectionReference get _signalsCollection =>
      _firestore.collection('safety_signals');
  CollectionReference get _toxicityCollection =>
      _firestore.collection('toxicity_results');
  CollectionReference get _appealsCollection =>
      _firestore.collection('appeals');
  CollectionReference get _trustProfilesCollection =>
      _firestore.collection('trust_profiles');

  final StreamController<NetworkBan> _banController =
      StreamController<NetworkBan>.broadcast();
  final StreamController<SafetySignal> _signalController =
      StreamController<SafetySignal>.broadcast();
  final StreamController<Appeal> _appealController =
      StreamController<Appeal>.broadcast();

  Stream<NetworkBan> get banStream => _banController.stream;
  Stream<SafetySignal> get signalStream => _signalController.stream;
  Stream<Appeal> get appealStream => _appealController.stream;

  // ============================================================
  // GLOBAL BAN PROPAGATION
  // ============================================================

  /// Issue and propagate a global ban
  Future<NetworkBan> globalBanPropagation({
    required String userId,
    required BanType type,
    required SafetySignalType reason,
    required String description,
    required String issuedBy,
    Duration? duration,
    List<String>? targetPartners,
    Map<String, dynamic>? evidence,
  }) async {
    debugPrint('ðŸš« [Trust] Issuing ${type.name} ban for: $userId');

    final banRef = _bansCollection.doc();
    final ban = NetworkBan(
      banId: banRef.id,
      userId: userId,
      type: type,
      status: BanStatus.active,
      reason: reason,
      description: description,
      issuedBy: issuedBy,
      issuedAt: DateTime.now(),
      expiresAt: duration != null ? DateTime.now().add(duration) : null,
      originPartners: ['mixmingle'],
      propagatedTo: targetPartners ?? [],
      evidence: evidence ?? {},
    );

    await banRef.set(ban.toFirestore());

    // Propagate to federation partners
    if (type == BanType.network || type == BanType.global) {
      await _propagateBan(ban);
    }

    // Update user trust profile
    await _updateTrustProfile(userId);

    _banController.add(ban);

    debugPrint('âœ… [Trust] Ban issued: ${ban.banId}');
    return ban;
  }

  Future<void> _propagateBan(NetworkBan ban) async {
    debugPrint('ðŸ“¤ [Trust] Propagating ban to federation partners');

    // In production, this would send to federation partners via API
    // For now, store propagation record
    await _firestore.collection('ban_propagation').add({
      'banId': ban.banId,
      'userId': ban.userId,
      'type': ban.type.name,
      'reason': ban.reason.name,
      'propagatedAt': Timestamp.now(),
      'targetPartners': ban.propagatedTo,
    });
  }

  /// Check if user is banned
  Future<List<NetworkBan>> getActiveBans(String userId) async {
    final snapshot = await _bansCollection
        .where('userId', isEqualTo: userId)
        .where('status', isEqualTo: BanStatus.active.name)
        .get();

    return snapshot.docs
        .map((doc) => NetworkBan.fromFirestore(doc))
        .where((ban) => ban.isActive)
        .toList();
  }

  /// Revoke a ban
  Future<void> revokeBan(String banId, {String? reason}) async {
    await _bansCollection.doc(banId).update({
      'status': BanStatus.overturned.name,
      'revokedAt': Timestamp.now(),
      'revokeReason': reason,
    });

    debugPrint('âœ… [Trust] Ban revoked: $banId');
  }

  // ============================================================
  // CROSS-APP SAFETY SIGNALS
  // ============================================================

  /// Report or receive cross-app safety signal
  Future<SafetySignal> crossAppSafetySignals({
    required String userId,
    required SafetySignalType type,
    required ToxicitySeverity severity,
    required String sourceApp,
    required String description,
    double confidenceScore = 0.5,
    Duration? validFor,
    Map<String, dynamic>? context,
  }) async {
    debugPrint('ðŸš¨ [Trust] Recording safety signal: ${type.name} from $sourceApp');

    final signalRef = _signalsCollection.doc();
    final signal = SafetySignal(
      signalId: signalRef.id,
      userId: userId,
      type: type,
      severity: severity,
      sourceApp: sourceApp,
      description: description,
      confidenceScore: confidenceScore,
      detectedAt: DateTime.now(),
      expiresAt: validFor != null ? DateTime.now().add(validFor) : null,
      context: context ?? {},
    );

    await signalRef.set(signal.toFirestore());

    // Update trust profile
    await _updateTrustProfile(userId);

    _signalController.add(signal);

    debugPrint('âœ… [Trust] Safety signal recorded: ${signal.signalId}');
    return signal;
  }

  /// Get safety signals for a user
  Future<List<SafetySignal>> getSafetySignals(
    String userId, {
    SafetySignalType? type,
    int limit = 50,
  }) async {
    var query = _signalsCollection
        .where('userId', isEqualTo: userId)
        .orderBy('detectedAt', descending: true)
        .limit(limit);

    if (type != null) {
      query = query.where('type', isEqualTo: type.name);
    }

    final snapshot = await query.get();
    return snapshot.docs.map((doc) => SafetySignal.fromFirestore(doc)).toList();
  }

  // ============================================================
  // FEDERATED TOXICITY DETECTION
  // ============================================================

  /// Analyze content for toxicity using federated models
  Future<ToxicityResult> federatedToxicityDetection({
    required String contentId,
    required String contentType,
    required String content,
    String? userId,
  }) async {
    debugPrint('ðŸ” [Trust] Analyzing content for toxicity: $contentId');

    // Simulated toxicity analysis (in production, use ML model)
    final scores = _analyzeContent(content);
    final overallScore = scores.values.fold<double>(
      0.0,
      (total, score) => total + score,
    ) / scores.length;

    final severity = _determineSeverity(overallScore);
    final isToxic = overallScore > 0.5;

    final resultRef = _toxicityCollection.doc();
    final result = ToxicityResult(
      analysisId: resultRef.id,
      contentId: contentId,
      contentType: contentType,
      isToxic: isToxic,
      severity: severity,
      categoryScores: scores,
      overallScore: overallScore,
      flaggedPhrases: _extractFlaggedPhrases(content),
      analyzedAt: DateTime.now(),
      modelVersion: '1.0.0',
    );

    await resultRef.set(result.toFirestore());

    // If toxic and user provided, create safety signal
    if (isToxic && userId != null) {
      final topCategory = scores.entries.reduce(
        (a, b) => a.value > b.value ? a : b,
      );

      await crossAppSafetySignals(
        userId: userId,
        type: topCategory.key,
        severity: severity,
        sourceApp: 'mixmingle',
        description: 'Toxic content detected in $contentType',
        confidenceScore: overallScore,
      );
    }

    debugPrint('âœ… [Trust] Toxicity analysis complete: ${isToxic ? 'TOXIC' : 'CLEAN'}');
    return result;
  }

  Map<SafetySignalType, double> _analyzeContent(String content) {
    // Simplified toxicity analysis (in production, use actual ML)
    final lowered = content.toLowerCase();
    final scores = <SafetySignalType, double>{};

    // Basic keyword-based scoring (placeholder for ML)
    for (final type in SafetySignalType.values) {
      scores[type] = 0.0;
    }

    // Harassment indicators
    if (lowered.contains('hate') || lowered.contains('idiot') || lowered.contains('stupid')) {
      scores[SafetySignalType.harassment] = 0.6;
    }

    // Spam indicators
    if (lowered.contains('click here') ||
        lowered.contains('free money') ||
        lowered.contains('limited offer')) {
      scores[SafetySignalType.spam] = 0.7;
    }

    // Scam indicators
    if (lowered.contains('send me') ||
        lowered.contains('wire transfer') ||
        lowered.contains('bank details')) {
      scores[SafetySignalType.scam] = 0.8;
    }

    return scores;
  }

  ToxicitySeverity _determineSeverity(double score) {
    if (score >= 0.9) return ToxicitySeverity.critical;
    if (score >= 0.7) return ToxicitySeverity.severe;
    if (score >= 0.5) return ToxicitySeverity.high;
    if (score >= 0.3) return ToxicitySeverity.medium;
    return ToxicitySeverity.low;
  }

  List<String> _extractFlaggedPhrases(String content) {
    // Simplified phrase extraction (in production, use NLP)
    final flagged = <String>[];
    final words = content.split(RegExp(r'\s+'));

    final flagWords = ['hate', 'scam', 'spam', 'free', 'click'];
    for (var i = 0; i < words.length; i++) {
      final word = words[i].toLowerCase();
      if (flagWords.any((fw) => word.contains(fw))) {
        final start = (i - 2).clamp(0, words.length);
        final end = (i + 3).clamp(0, words.length);
        flagged.add(words.sublist(start, end).join(' '));
      }
    }

    return flagged.take(5).toList();
  }

  // ============================================================
  // GLOBAL APPEALS SYSTEM
  // ============================================================

  /// Submit an appeal
  Future<Appeal> globalAppealsSystem({
    required String userId,
    required String banId,
    required String reason,
    String? additionalContext,
    List<String>? attachments,
  }) async {
    debugPrint('ðŸ“ [Trust] Submitting appeal for ban: $banId');

    // Verify ban exists
    final banDoc = await _bansCollection.doc(banId).get();
    if (!banDoc.exists) {
      throw Exception('Ban not found');
    }

    final ban = NetworkBan.fromFirestore(banDoc);
    if (ban.userId != userId) {
      throw Exception('User not authorized to appeal this ban');
    }

    // Check for existing pending appeal
    final existingAppeals = await _appealsCollection
        .where('banId', isEqualTo: banId)
        .where('status', isEqualTo: AppealStatus.pending.name)
        .get();

    if (existingAppeals.docs.isNotEmpty) {
      throw Exception('An appeal for this ban is already pending');
    }

    final appealRef = _appealsCollection.doc();
    final appeal = Appeal(
      appealId: appealRef.id,
      userId: userId,
      banId: banId,
      status: AppealStatus.pending,
      reason: reason,
      additionalContext: additionalContext,
      submittedAt: DateTime.now(),
      attachments: attachments ?? [],
    );

    await appealRef.set(appeal.toFirestore());

    // Update ban status
    await _bansCollection.doc(banId).update({
      'status': BanStatus.appealed.name,
    });

    _appealController.add(appeal);

    debugPrint('âœ… [Trust] Appeal submitted: ${appeal.appealId}');
    return appeal;
  }

  /// Review an appeal
  Future<void> reviewAppeal({
    required String appealId,
    required AppealStatus decision,
    required String reviewedBy,
    String? notes,
  }) async {
    debugPrint('âš–ï¸ [Trust] Reviewing appeal: $appealId -> $decision');

    final appealDoc = await _appealsCollection.doc(appealId).get();
    if (!appealDoc.exists) {
      throw Exception('Appeal not found');
    }

    final appeal = Appeal.fromFirestore(appealDoc);

    await _appealsCollection.doc(appealId).update({
      'status': decision.name,
      'reviewedAt': Timestamp.now(),
      'reviewedBy': reviewedBy,
      'reviewNotes': notes,
    });

    // If approved, revoke the ban
    if (decision == AppealStatus.approved) {
      await revokeBan(appeal.banId, reason: 'Appeal approved');
    } else if (decision == AppealStatus.denied) {
      await _bansCollection.doc(appeal.banId).update({
        'status': BanStatus.active.name,
      });
    }

    // Update trust profile
    await _updateTrustProfile(appeal.userId);

    debugPrint('âœ… [Trust] Appeal reviewed: $appealId');
  }

  /// Get appeals for a user
  Future<List<Appeal>> getUserAppeals(String userId) async {
    final snapshot = await _appealsCollection
        .where('userId', isEqualTo: userId)
        .orderBy('submittedAt', descending: true)
        .get();

    return snapshot.docs.map((doc) => Appeal.fromFirestore(doc)).toList();
  }

  /// Get pending appeals (for moderators)
  Future<List<Appeal>> getPendingAppeals({int limit = 50}) async {
    final snapshot = await _appealsCollection
        .where('status', whereIn: [AppealStatus.pending.name, AppealStatus.underReview.name])
        .orderBy('submittedAt')
        .limit(limit)
        .get();

    return snapshot.docs.map((doc) => Appeal.fromFirestore(doc)).toList();
  }

  // ============================================================
  // TRUST PROFILE
  // ============================================================

  Future<void> _updateTrustProfile(String userId) async {
    debugPrint('ðŸ“Š [Trust] Updating trust profile: $userId');

    final bans = await getActiveBans(userId);
    final signals = await getSafetySignals(userId, limit: 100);
    final appeals = await getUserAppeals(userId);

    final appealsWon = appeals.where((a) => a.status == AppealStatus.approved).length;
    final appealsLost = appeals.where((a) => a.status == AppealStatus.denied).length;

    // Calculate trust score
    final trustScore = _calculateTrustScore(
      bans: bans,
      signals: signals,
      appealsWon: appealsWon,
      appealsLost: appealsLost,
    );

    final level = _determineTrustLevel(trustScore);

    await _trustProfilesCollection.doc(userId).set({
      'userId': userId,
      'level': level.name,
      'trustScore': trustScore,
      'totalReports': signals.length,
      'confirmedViolations': bans.length,
      'appealsWon': appealsWon,
      'appealsLost': appealsLost,
      'lastUpdated': Timestamp.now(),
    }, SetOptions(merge: true));
  }

  double _calculateTrustScore({
    required List<NetworkBan> bans,
    required List<SafetySignal> signals,
    required int appealsWon,
    required int appealsLost,
  }) {
    // Start with base score
    double score = 100.0;

    // Deduct for bans
    for (final ban in bans) {
      switch (ban.type) {
        case BanType.permanent:
          score -= 100;
          break;
        case BanType.global:
          score -= 50;
          break;
        case BanType.network:
          score -= 30;
          break;
        case BanType.local:
          score -= 10;
          break;
      }
    }

    // Deduct for signals
    for (final signal in signals) {
      switch (signal.severity) {
        case ToxicitySeverity.critical:
          score -= 20;
          break;
        case ToxicitySeverity.severe:
          score -= 15;
          break;
        case ToxicitySeverity.high:
          score -= 10;
          break;
        case ToxicitySeverity.medium:
          score -= 5;
          break;
        case ToxicitySeverity.low:
          score -= 2;
          break;
      }
    }

    // Adjust for appeals
    score += appealsWon * 10;
    score -= appealsLost * 5;

    return score.clamp(0.0, 100.0);
  }

  TrustLevel _determineTrustLevel(double score) {
    if (score >= 90) return TrustLevel.trusted;
    if (score >= 75) return TrustLevel.verified;
    if (score >= 50) return TrustLevel.standard;
    if (score >= 25) return TrustLevel.limited;
    if (score >= 10) return TrustLevel.untrusted;
    return TrustLevel.unknown;
  }

  /// Get user trust profile
  Future<UserTrustProfile?> getUserTrustProfile(String userId) async {
    final doc = await _trustProfilesCollection.doc(userId).get();
    if (!doc.exists) return null;

    final data = doc.data() as Map<String, dynamic>;
    final bans = await getActiveBans(userId);
    final signals = await getSafetySignals(userId, limit: 10);

    return UserTrustProfile(
      userId: userId,
      level: TrustLevel.values.firstWhere(
        (l) => l.name == data['level'],
        orElse: () => TrustLevel.unknown,
      ),
      trustScore: (data['trustScore'] ?? 50.0).toDouble(),
      totalReports: data['totalReports'] ?? 0,
      confirmedViolations: data['confirmedViolations'] ?? 0,
      appealsWon: data['appealsWon'] ?? 0,
      appealsLost: data['appealsLost'] ?? 0,
      activeBans: bans,
      recentSignals: signals,
      lastUpdated: (data['lastUpdated'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  /// Get global trust statistics
  Future<Map<String, dynamic>> getTrustStatistics() async {
    final bansSnapshot = await _bansCollection
        .where('status', isEqualTo: BanStatus.active.name)
        .get();

    final signalsSnapshot = await _signalsCollection
        .where('detectedAt',
            isGreaterThan: Timestamp.fromDate(
              DateTime.now().subtract(const Duration(days: 30)),
            ))
        .get();

    final appealsSnapshot = await _appealsCollection
        .where('status', isEqualTo: AppealStatus.pending.name)
        .get();

    final toxicitySnapshot = await _toxicityCollection
        .where('isToxic', isEqualTo: true)
        .where('analyzedAt',
            isGreaterThan: Timestamp.fromDate(
              DateTime.now().subtract(const Duration(days: 7)),
            ))
        .get();

    return {
      'activeBans': bansSnapshot.docs.length,
      'recentSignals30d': signalsSnapshot.docs.length,
      'pendingAppeals': appealsSnapshot.docs.length,
      'toxicContent7d': toxicitySnapshot.docs.length,
    };
  }

  void dispose() {
    _banController.close();
    _signalController.close();
    _appealController.close();
  }
}
