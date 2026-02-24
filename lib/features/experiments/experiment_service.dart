/// Experiment Service
///
/// Manages A/B testing and experimentation including user assignment,
/// exposure tracking, and outcome measurement.
library;

import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/analytics/analytics_service.dart';
import 'experiment_config.dart';

/// Result of a statistical test
class ExperimentResult {
  final String experimentId;
  final String metric;
  final Map<VariantAssignment, double> variantValues;
  final VariantAssignment? winner;
  final double confidence;
  final bool isSignificant;
  final int totalSampleSize;
  final DateTime computedAt;

  const ExperimentResult({
    required this.experimentId,
    required this.metric,
    required this.variantValues,
    this.winner,
    required this.confidence,
    required this.isSignificant,
    required this.totalSampleSize,
    required this.computedAt,
  });

  Map<String, dynamic> toMap() => {
    'experimentId': experimentId,
    'metric': metric,
    'variantValues': variantValues.map((k, v) => MapEntry(k.name, v)),
    'winner': winner?.name,
    'confidence': confidence,
    'isSignificant': isSignificant,
    'totalSampleSize': totalSampleSize,
    'computedAt': computedAt.toIso8601String(),
  };
}

/// User experiment assignment
class UserExperimentAssignment {
  final String experimentId;
  final VariantAssignment variant;
  final DateTime assignedAt;
  final bool exposed;
  final DateTime? exposedAt;

  const UserExperimentAssignment({
    required this.experimentId,
    required this.variant,
    required this.assignedAt,
    this.exposed = false,
    this.exposedAt,
  });

  Map<String, dynamic> toMap() => {
    'experimentId': experimentId,
    'variant': variant.name,
    'assignedAt': assignedAt.toIso8601String(),
    'exposed': exposed,
    'exposedAt': exposedAt?.toIso8601String(),
  };

  factory UserExperimentAssignment.fromMap(Map<String, dynamic> map) {
    return UserExperimentAssignment(
      experimentId: map['experimentId'] ?? '',
      variant: VariantAssignment.values.firstWhere(
        (v) => v.name == map['variant'],
        orElse: () => VariantAssignment.control,
      ),
      assignedAt: DateTime.parse(map['assignedAt'] ?? DateTime.now().toIso8601String()),
      exposed: map['exposed'] ?? false,
      exposedAt: map['exposedAt'] != null ? DateTime.parse(map['exposedAt']) : null,
    );
  }
}

/// Service for managing experiments and A/B testing
class ExperimentService {
  static ExperimentService? _instance;
  static ExperimentService get instance => _instance ??= ExperimentService._();

  ExperimentService._();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  SharedPreferences? _prefs;

  // Cache of user assignments
  final Map<String, UserExperimentAssignment> _userAssignments = {};

  // Collections
  CollectionReference<Map<String, dynamic>> get _experimentsCollection =>
      _firestore.collection('experiments');

  CollectionReference<Map<String, dynamic>> get _exposuresCollection =>
      _firestore.collection('experiment_exposures');

  CollectionReference<Map<String, dynamic>> get _outcomesCollection =>
      _firestore.collection('experiment_outcomes');

  /// Initialize the service
  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
    await _loadUserAssignments();

    AnalyticsService.instance.logEvent(
      name: 'experiments_initialized',
      parameters: {'assigned_experiments': _userAssignments.length},
    );
  }

  /// Assign user to an experiment group
  ///
  /// Uses deterministic hashing to ensure consistent assignment
  Future<VariantAssignment> assignExperimentGroup(
    String experimentId, {
    String? userId,
  }) async {
    final uid = userId ?? _auth.currentUser?.uid;
    if (uid == null) return VariantAssignment.control;

    // Check cached assignment
    final cacheKey = '${experimentId}_$uid';
    if (_userAssignments.containsKey(cacheKey)) {
      return _userAssignments[cacheKey]!.variant;
    }

    // Check stored assignment
    final storedVariant = _prefs?.getString('exp_$cacheKey');
    if (storedVariant != null) {
      final variant = VariantAssignment.values.firstWhere(
        (v) => v.name == storedVariant,
        orElse: () => VariantAssignment.control,
      );
      _userAssignments[cacheKey] = UserExperimentAssignment(
        experimentId: experimentId,
        variant: variant,
        assignedAt: DateTime.now(),
      );
      return variant;
    }

    // Get experiment config
    final config = ExperimentRegistry.getExperiment(experimentId);
    if (config == null || !config.isActive) {
      return VariantAssignment.control;
    }

    // Deterministic assignment based on user ID hash
    final variant = _assignVariant(uid, experimentId, config.trafficAllocation);

    // Store assignment
    final assignment = UserExperimentAssignment(
      experimentId: experimentId,
      variant: variant,
      assignedAt: DateTime.now(),
    );
    _userAssignments[cacheKey] = assignment;
    await _prefs?.setString('exp_$cacheKey', variant.name);

    // Record assignment in Firestore
    await _recordAssignment(uid, experimentId, variant);

    return variant;
  }

  /// Track when user is exposed to an experiment variant
  Future<void> trackExperimentExposure(
    String experimentId, {
    String? userId,
    Map<String, dynamic>? context,
  }) async {
    final uid = userId ?? _auth.currentUser?.uid;
    if (uid == null) return;

    final cacheKey = '${experimentId}_$uid';
    final assignment = _userAssignments[cacheKey];

    if (assignment == null) {
      // User not assigned - assign first
      await assignExperimentGroup(experimentId, userId: uid);
      return trackExperimentExposure(experimentId, userId: uid, context: context);
    }

    if (assignment.exposed) return; // Already exposed

    // Update cache
    _userAssignments[cacheKey] = UserExperimentAssignment(
      experimentId: assignment.experimentId,
      variant: assignment.variant,
      assignedAt: assignment.assignedAt,
      exposed: true,
      exposedAt: DateTime.now(),
    );

    // Record exposure
    await _exposuresCollection.add({
      'userId': uid,
      'experimentId': experimentId,
      'variant': assignment.variant.name,
      'exposedAt': FieldValue.serverTimestamp(),
      'context': context ?? {},
    });

    // Log to analytics
    AnalyticsService.instance.logEvent(
      name: 'experiment_exposure',
      parameters: {
        'experiment_id': experimentId,
        'variant': assignment.variant.name,
        ...?context,
      },
    );
  }

  /// Track experiment outcome
  Future<void> trackExperimentOutcome(
    String experimentId, {
    required String metric,
    required double value,
    String? userId,
    Map<String, dynamic>? metadata,
  }) async {
    final uid = userId ?? _auth.currentUser?.uid;
    if (uid == null) return;

    final cacheKey = '${experimentId}_$uid';
    final assignment = _userAssignments[cacheKey];

    if (assignment == null || !assignment.exposed) {
      // Only track outcomes for exposed users
      return;
    }

    await _outcomesCollection.add({
      'userId': uid,
      'experimentId': experimentId,
      'variant': assignment.variant.name,
      'metric': metric,
      'value': value,
      'recordedAt': FieldValue.serverTimestamp(),
      'metadata': metadata ?? {},
    });

    // Log to analytics
    AnalyticsService.instance.logEvent(
      name: 'experiment_outcome',
      parameters: {
        'experiment_id': experimentId,
        'variant': assignment.variant.name,
        'metric': metric,
        'value': value,
        ...?metadata,
      },
    );
  }

  /// Get user's current variant for an experiment
  VariantAssignment? getUserVariant(String experimentId, {String? userId}) {
    final uid = userId ?? _auth.currentUser?.uid;
    if (uid == null) return null;

    final cacheKey = '${experimentId}_$uid';
    return _userAssignments[cacheKey]?.variant;
  }

  /// Get experiment settings for user's assigned variant
  Map<String, dynamic> getVariantSettings(String experimentId, {String? userId}) {
    final variant = getUserVariant(experimentId, userId: userId);
    if (variant == null) return {};

    final config = ExperimentRegistry.getExperiment(experimentId);
    if (config == null) return {};

    return config.getVariantSettings(variant);
  }

  /// Check if user is in a specific variant
  bool isInVariant(
    String experimentId,
    VariantAssignment variant, {
    String? userId,
  }) {
    return getUserVariant(experimentId, userId: userId) == variant;
  }

  /// Get all experiments user is assigned to
  List<UserExperimentAssignment> getUserExperiments({String? userId}) {
    final uid = userId ?? _auth.currentUser?.uid;
    if (uid == null) return [];

    return _userAssignments.entries
        .where((e) => e.key.endsWith('_$uid'))
        .map((e) => e.value)
        .toList();
  }

  /// Calculate experiment results (admin function)
  Future<ExperimentResult?> calculateResults(
    String experimentId,
    String metric,
  ) async {
    final config = ExperimentRegistry.getExperiment(experimentId);
    if (config == null) return null;

    final outcomes = await _outcomesCollection
        .where('experimentId', isEqualTo: experimentId)
        .where('metric', isEqualTo: metric)
        .get();

    if (outcomes.docs.isEmpty) return null;

    // Group outcomes by variant
    final variantOutcomes = <VariantAssignment, List<double>>{};
    for (final doc in outcomes.docs) {
      final data = doc.data();
      final variant = VariantAssignment.values.firstWhere(
        (v) => v.name == data['variant'],
        orElse: () => VariantAssignment.control,
      );
      variantOutcomes.putIfAbsent(variant, () => []);
      variantOutcomes[variant]!.add((data['value'] as num).toDouble());
    }

    // Calculate means
    final variantValues = variantOutcomes.map((variant, values) {
      final mean = values.reduce((a, b) => a + b) / values.length;
      return MapEntry(variant, mean);
    });

    // Simple significance test (t-test approximation)
    final totalSample = variantOutcomes.values.fold<int>(0, (a, b) => a + b.length);
    final confidence = _calculateConfidence(variantOutcomes);
    final isSignificant = confidence >= config.minConfidence &&
        totalSample >= config.minSampleSize;

    // Determine winner
    VariantAssignment? winner;
    if (isSignificant && variantValues.isNotEmpty) {
      winner = variantValues.entries
          .reduce((a, b) => a.value > b.value ? a : b)
          .key;
    }

    return ExperimentResult(
      experimentId: experimentId,
      metric: metric,
      variantValues: variantValues,
      winner: winner,
      confidence: confidence,
      isSignificant: isSignificant,
      totalSampleSize: totalSample,
      computedAt: DateTime.now(),
    );
  }

  /// Force override a user's variant (for testing)
  Future<void> overrideVariant(
    String experimentId,
    VariantAssignment variant, {
    String? userId,
  }) async {
    final uid = userId ?? _auth.currentUser?.uid;
    if (uid == null) return;

    final cacheKey = '${experimentId}_$uid';
    _userAssignments[cacheKey] = UserExperimentAssignment(
      experimentId: experimentId,
      variant: variant,
      assignedAt: DateTime.now(),
    );
    await _prefs?.setString('exp_$cacheKey', variant.name);
  }

  /// Clear user's experiment assignments (for testing)
  Future<void> clearAssignments({String? userId}) async {
    final uid = userId ?? _auth.currentUser?.uid;
    if (uid == null) return;

    final keysToRemove = _userAssignments.keys
        .where((k) => k.endsWith('_$uid'))
        .toList();

    for (final key in keysToRemove) {
      _userAssignments.remove(key);
      await _prefs?.remove('exp_$key');
    }
  }

  // Private methods

  Future<void> _loadUserAssignments() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    final keys = _prefs?.getKeys().where((k) => k.startsWith('exp_')) ?? [];

    for (final key in keys) {
      if (key.endsWith('_$uid')) {
        final experimentId = key.replaceFirst('exp_', '').replaceAll('_$uid', '');
        final variantName = _prefs?.getString(key);
        if (variantName != null) {
          final variant = VariantAssignment.values.firstWhere(
            (v) => v.name == variantName,
            orElse: () => VariantAssignment.control,
          );
          _userAssignments[key.replaceFirst('exp_', '')] = UserExperimentAssignment(
            experimentId: experimentId,
            variant: variant,
            assignedAt: DateTime.now(),
          );
        }
      }
    }
  }

  VariantAssignment _assignVariant(
    String userId,
    String experimentId,
    Map<VariantAssignment, double> allocation,
  ) {
    // Deterministic hash based on user ID and experiment ID
    final hash = '$userId$experimentId'.hashCode.abs();
    final bucket = (hash % 10000) / 10000.0;

    double cumulative = 0.0;
    for (final entry in allocation.entries) {
      cumulative += entry.value;
      if (bucket < cumulative) {
        return entry.key;
      }
    }

    return VariantAssignment.control;
  }

  Future<void> _recordAssignment(
    String userId,
    String experimentId,
    VariantAssignment variant,
  ) async {
    await _experimentsCollection.doc(experimentId).collection('assignments').doc(userId).set({
      'userId': userId,
      'variant': variant.name,
      'assignedAt': FieldValue.serverTimestamp(),
    });
  }

  double _calculateConfidence(Map<VariantAssignment, List<double>> outcomes) {
    if (outcomes.length < 2) return 0.0;

    // Simplified confidence calculation
    // In production, use proper statistical tests
    final control = outcomes[VariantAssignment.control] ?? [];
    if (control.isEmpty) return 0.0;

    final controlMean = control.reduce((a, b) => a + b) / control.length;
    final controlStd = _standardDeviation(control, controlMean);

    double maxDiff = 0.0;
    for (final entry in outcomes.entries) {
      if (entry.key == VariantAssignment.control) continue;

      final values = entry.value;
      if (values.isEmpty) continue;

      final mean = values.reduce((a, b) => a + b) / values.length;
      final diff = (mean - controlMean).abs();

      if (controlStd > 0) {
        final effectSize = diff / controlStd;
        if (effectSize > maxDiff) maxDiff = effectSize;
      }
    }

    // Convert effect size to approximate confidence
    // This is a simplification - use proper statistical libraries in production
    return (1 - 1 / (1 + maxDiff * maxDiff)).clamp(0.0, 0.99);
  }

  double _standardDeviation(List<double> values, double mean) {
    if (values.length < 2) return 0.0;
    final variance = values.map((v) => (v - mean) * (v - mean)).reduce((a, b) => a + b) / (values.length - 1);
    return variance > 0 ? variance : 0.0;
  }
}


