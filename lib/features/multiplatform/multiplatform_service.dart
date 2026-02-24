/// Multi-Platform Deployment Service
///
/// Manages deployment and distribution across web, desktop, TV, VR, and wearables.
library;

import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

/// Platform deployment target
enum DeploymentPlatform {
  web,
  desktop,
  tv,
  vr,
  wearables,
  mobile,
}

/// Deployment status
enum DeploymentStatus {
  pending,
  building,
  testing,
  deploying,
  deployed,
  failed,
  rolledBack,
}

/// Build configuration
enum BuildConfig {
  debug,
  profile,
  release,
}

/// Deployment record
class Deployment {
  final String id;
  final DeploymentPlatform platform;
  final String version;
  final BuildConfig config;
  final DeploymentStatus status;
  final DateTime startedAt;
  final DateTime? completedAt;
  final String? buildUrl;
  final String? errorMessage;
  final Map<String, dynamic> metadata;
  final List<DeploymentStep> steps;

  const Deployment({
    required this.id,
    required this.platform,
    required this.version,
    required this.config,
    required this.status,
    required this.startedAt,
    this.completedAt,
    this.buildUrl,
    this.errorMessage,
    this.metadata = const {},
    this.steps = const [],
  });

  factory Deployment.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Deployment(
      id: doc.id,
      platform: DeploymentPlatform.values.firstWhere(
        (p) => p.name == data['platform'],
        orElse: () => DeploymentPlatform.web,
      ),
      version: data['version'] ?? '1.0.0',
      config: BuildConfig.values.firstWhere(
        (c) => c.name == data['config'],
        orElse: () => BuildConfig.release,
      ),
      status: DeploymentStatus.values.firstWhere(
        (s) => s.name == data['status'],
        orElse: () => DeploymentStatus.pending,
      ),
      startedAt: (data['startedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      completedAt: (data['completedAt'] as Timestamp?)?.toDate(),
      buildUrl: data['buildUrl'],
      errorMessage: data['errorMessage'],
      metadata: Map<String, dynamic>.from(data['metadata'] ?? {}),
      steps: (data['steps'] as List<dynamic>? ?? [])
          .map((s) => DeploymentStep.fromMap(s))
          .toList(),
    );
  }

  Map<String, dynamic> toFirestore() => {
        'platform': platform.name,
        'version': version,
        'config': config.name,
        'status': status.name,
        'startedAt': Timestamp.fromDate(startedAt),
        'completedAt': completedAt != null ? Timestamp.fromDate(completedAt!) : null,
        'buildUrl': buildUrl,
        'errorMessage': errorMessage,
        'metadata': metadata,
        'steps': steps.map((s) => s.toMap()).toList(),
      };

  Duration? get duration => completedAt?.difference(startedAt);
}

/// Deployment step
class DeploymentStep {
  final String name;
  final DeploymentStatus status;
  final DateTime? startedAt;
  final DateTime? completedAt;
  final String? output;

  const DeploymentStep({
    required this.name,
    required this.status,
    this.startedAt,
    this.completedAt,
    this.output,
  });

  factory DeploymentStep.fromMap(Map<String, dynamic> data) {
    return DeploymentStep(
      name: data['name'] ?? '',
      status: DeploymentStatus.values.firstWhere(
        (s) => s.name == data['status'],
        orElse: () => DeploymentStatus.pending,
      ),
      startedAt: (data['startedAt'] as Timestamp?)?.toDate(),
      completedAt: (data['completedAt'] as Timestamp?)?.toDate(),
      output: data['output'],
    );
  }

  Map<String, dynamic> toMap() => {
        'name': name,
        'status': status.name,
        'startedAt': startedAt != null ? Timestamp.fromDate(startedAt!) : null,
        'completedAt': completedAt != null ? Timestamp.fromDate(completedAt!) : null,
        'output': output,
      };
}

/// Platform-specific configuration
class PlatformConfig {
  final DeploymentPlatform platform;
  final String name;
  final String description;
  final bool isEnabled;
  final Map<String, dynamic> buildSettings;
  final Map<String, dynamic> deploySettings;
  final List<String> requiredCapabilities;
  final String? cdnEndpoint;
  final String? storeUrl;

  const PlatformConfig({
    required this.platform,
    required this.name,
    required this.description,
    this.isEnabled = true,
    this.buildSettings = const {},
    this.deploySettings = const {},
    this.requiredCapabilities = const [],
    this.cdnEndpoint,
    this.storeUrl,
  });

  factory PlatformConfig.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return PlatformConfig(
      platform: DeploymentPlatform.values.firstWhere(
        (p) => p.name == data['platform'],
        orElse: () => DeploymentPlatform.web,
      ),
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      isEnabled: data['isEnabled'] ?? true,
      buildSettings: Map<String, dynamic>.from(data['buildSettings'] ?? {}),
      deploySettings: Map<String, dynamic>.from(data['deploySettings'] ?? {}),
      requiredCapabilities: List<String>.from(data['requiredCapabilities'] ?? []),
      cdnEndpoint: data['cdnEndpoint'],
      storeUrl: data['storeUrl'],
    );
  }
}

/// Multi-platform deployment service
class MultiplatformService {
  static MultiplatformService? _instance;
  static MultiplatformService get instance => _instance ??= MultiplatformService._();

  MultiplatformService._();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference get _deploymentsCollection =>
      _firestore.collection('deployments');

  CollectionReference get _platformConfigsCollection =>
      _firestore.collection('platform_configs');

  final StreamController<Deployment> _deploymentController =
      StreamController<Deployment>.broadcast();

  Stream<Deployment> get deploymentStream => _deploymentController.stream;

  // ============================================================
  // PLATFORM DEPLOYMENT
  // ============================================================

  /// Deploy to web platform
  Future<Deployment> deployToWeb({
    required String version,
    BuildConfig config = BuildConfig.release,
    Map<String, dynamic>? options,
  }) async {
    debugPrint('ðŸŒ [Multiplatform] Deploying to web: v$version');

    return _deploy(
      platform: DeploymentPlatform.web,
      version: version,
      config: config,
      steps: [
        'flutter_build_web',
        'optimize_assets',
        'deploy_to_firebase_hosting',
        'invalidate_cdn_cache',
        'smoke_test',
      ],
      options: options,
    );
  }

  /// Deploy to desktop platforms (Windows, macOS, Linux)
  Future<Deployment> deployToDesktop({
    required String version,
    BuildConfig config = BuildConfig.release,
    List<String> targets = const ['windows', 'macos', 'linux'],
    Map<String, dynamic>? options,
  }) async {
    debugPrint('ðŸ–¥ï¸ [Multiplatform] Deploying to desktop: v$version');

    return _deploy(
      platform: DeploymentPlatform.desktop,
      version: version,
      config: config,
      steps: [
        ...targets.map((t) => 'flutter_build_$t'),
        'code_sign',
        'package_installer',
        'upload_to_distribution',
        'notarize_macos',
      ],
      options: {
        'targets': targets,
        ...?options,
      },
    );
  }

  /// Deploy to TV platforms (Android TV, Apple TV, Fire TV)
  Future<Deployment> deployToTV({
    required String version,
    BuildConfig config = BuildConfig.release,
    List<String> targets = const ['android_tv', 'apple_tv', 'fire_tv'],
    Map<String, dynamic>? options,
  }) async {
    debugPrint('ðŸ“º [Multiplatform] Deploying to TV: v$version');

    return _deploy(
      platform: DeploymentPlatform.tv,
      version: version,
      config: config,
      steps: [
        'build_tv_ui_variant',
        'optimize_for_10ft_experience',
        ...targets.map((t) => 'build_$t'),
        'submit_to_stores',
        'living_room_qa',
      ],
      options: {
        'targets': targets,
        ...?options,
      },
    );
  }

  /// Deploy to VR platforms (Meta Quest, PSVR, etc.)
  Future<Deployment> deployToVR({
    required String version,
    BuildConfig config = BuildConfig.release,
    List<String> targets = const ['meta_quest', 'psvr'],
    Map<String, dynamic>? options,
  }) async {
    debugPrint('ðŸ¥½ [Multiplatform] Deploying to VR: v$version');

    return _deploy(
      platform: DeploymentPlatform.vr,
      version: version,
      config: config,
      steps: [
        'build_vr_ui_variant',
        'integrate_xr_sdk',
        'optimize_for_90fps',
        ...targets.map((t) => 'build_$t'),
        'submit_to_meta_store',
        'vr_comfort_testing',
      ],
      options: {
        'targets': targets,
        ...?options,
      },
    );
  }

  /// Deploy to wearables (Apple Watch, Wear OS)
  Future<Deployment> deployToWearables({
    required String version,
    BuildConfig config = BuildConfig.release,
    List<String> targets = const ['apple_watch', 'wear_os'],
    Map<String, dynamic>? options,
  }) async {
    debugPrint('âŒš [Multiplatform] Deploying to wearables: v$version');

    return _deploy(
      platform: DeploymentPlatform.wearables,
      version: version,
      config: config,
      steps: [
        'build_companion_app',
        'build_glances_widgets',
        'optimize_for_battery',
        ...targets.map((t) => 'build_$t'),
        'submit_to_stores',
        'wearable_qa',
      ],
      options: {
        'targets': targets,
        ...?options,
      },
    );
  }

  /// Core deployment logic
  Future<Deployment> _deploy({
    required DeploymentPlatform platform,
    required String version,
    required BuildConfig config,
    required List<String> steps,
    Map<String, dynamic>? options,
  }) async {
    final deploymentRef = _deploymentsCollection.doc();

    final deployment = Deployment(
      id: deploymentRef.id,
      platform: platform,
      version: version,
      config: config,
      status: DeploymentStatus.pending,
      startedAt: DateTime.now(),
      metadata: options ?? {},
      steps: steps
          .map((s) => DeploymentStep(
                name: s,
                status: DeploymentStatus.pending,
              ))
          .toList(),
    );

    await deploymentRef.set(deployment.toFirestore());
    _deploymentController.add(deployment);

    // Simulate deployment pipeline (in production, this would trigger CI/CD)
    _runDeploymentPipeline(deploymentRef.id, steps);

    return deployment;
  }

  /// Simulate deployment pipeline
  Future<void> _runDeploymentPipeline(String deploymentId, List<String> steps) async {
    try {
      await _deploymentsCollection.doc(deploymentId).update({
        'status': DeploymentStatus.building.name,
      });

      for (int i = 0; i < steps.length; i++) {
        // Update step to in-progress
        await _deploymentsCollection.doc(deploymentId).update({
          'steps.$i.status': DeploymentStatus.building.name,
          'steps.$i.startedAt': Timestamp.now(),
        });

        // Simulate step execution
        await Future.delayed(const Duration(milliseconds: 500));

        // Update step to completed
        await _deploymentsCollection.doc(deploymentId).update({
          'steps.$i.status': DeploymentStatus.deployed.name,
          'steps.$i.completedAt': Timestamp.now(),
          'steps.$i.output': 'Step completed successfully',
        });
      }

      // Mark deployment as complete
      await _deploymentsCollection.doc(deploymentId).update({
        'status': DeploymentStatus.deployed.name,
        'completedAt': Timestamp.now(),
        'buildUrl': 'https://cdn.mixmingle.app/builds/$deploymentId',
      });

      debugPrint('âœ… [Multiplatform] Deployment $deploymentId completed');
    } catch (e) {
      await _deploymentsCollection.doc(deploymentId).update({
        'status': DeploymentStatus.failed.name,
        'completedAt': Timestamp.now(),
        'errorMessage': e.toString(),
      });

      debugPrint('âŒ [Multiplatform] Deployment $deploymentId failed: $e');
    }
  }

  // ============================================================
  // DEPLOYMENT MANAGEMENT
  // ============================================================

  /// Get deployment by ID
  Future<Deployment?> getDeployment(String deploymentId) async {
    final doc = await _deploymentsCollection.doc(deploymentId).get();
    if (!doc.exists) return null;
    return Deployment.fromFirestore(doc);
  }

  /// Get deployments for platform
  Future<List<Deployment>> getDeploymentsForPlatform(
    DeploymentPlatform platform, {
    int limit = 20,
  }) async {
    final snapshot = await _deploymentsCollection
        .where('platform', isEqualTo: platform.name)
        .orderBy('startedAt', descending: true)
        .limit(limit)
        .get();

    return snapshot.docs.map((doc) => Deployment.fromFirestore(doc)).toList();
  }

  /// Get recent deployments
  Future<List<Deployment>> getRecentDeployments({int limit = 50}) async {
    final snapshot = await _deploymentsCollection
        .orderBy('startedAt', descending: true)
        .limit(limit)
        .get();

    return snapshot.docs.map((doc) => Deployment.fromFirestore(doc)).toList();
  }

  /// Cancel deployment
  Future<bool> cancelDeployment(String deploymentId) async {
    try {
      await _deploymentsCollection.doc(deploymentId).update({
        'status': DeploymentStatus.failed.name,
        'completedAt': Timestamp.now(),
        'errorMessage': 'Deployment cancelled by user',
      });

      debugPrint('ðŸ›‘ [Multiplatform] Deployment $deploymentId cancelled');
      return true;
    } catch (e) {
      debugPrint('âŒ [Multiplatform] Failed to cancel deployment: $e');
      return false;
    }
  }

  /// Rollback deployment
  Future<bool> rollbackDeployment(String deploymentId) async {
    try {
      final deployment = await getDeployment(deploymentId);
      if (deployment == null) return false;

      // Get previous successful deployment
      final previousSnapshot = await _deploymentsCollection
          .where('platform', isEqualTo: deployment.platform.name)
          .where('status', isEqualTo: DeploymentStatus.deployed.name)
          .orderBy('completedAt', descending: true)
          .limit(2)
          .get();

      if (previousSnapshot.docs.length < 2) {
        debugPrint('âš ï¸ [Multiplatform] No previous deployment to rollback to');
        return false;
      }

      // Mark current as rolled back
      await _deploymentsCollection.doc(deploymentId).update({
        'status': DeploymentStatus.rolledBack.name,
      });

      debugPrint('â†©ï¸ [Multiplatform] Deployment $deploymentId rolled back');
      return true;
    } catch (e) {
      debugPrint('âŒ [Multiplatform] Failed to rollback deployment: $e');
      return false;
    }
  }

  // ============================================================
  // PLATFORM CONFIGURATION
  // ============================================================

  /// Get platform config
  Future<PlatformConfig?> getPlatformConfig(DeploymentPlatform platform) async {
    final doc = await _platformConfigsCollection.doc(platform.name).get();
    if (!doc.exists) return null;
    return PlatformConfig.fromFirestore(doc);
  }

  /// Get all platform configs
  Future<List<PlatformConfig>> getAllPlatformConfigs() async {
    final snapshot = await _platformConfigsCollection.get();
    return snapshot.docs.map((doc) => PlatformConfig.fromFirestore(doc)).toList();
  }

  /// Update platform config
  Future<void> updatePlatformConfig(
    DeploymentPlatform platform,
    Map<String, dynamic> updates,
  ) async {
    await _platformConfigsCollection.doc(platform.name).update(updates);
    debugPrint('âœ… [Multiplatform] Platform config updated: ${platform.name}');
  }

  /// Enable/disable platform
  Future<void> setPlatformEnabled(DeploymentPlatform platform, bool enabled) async {
    await _platformConfigsCollection.doc(platform.name).update({
      'isEnabled': enabled,
    });
    debugPrint('${enabled ? 'âœ…' : 'âŒ'} [Multiplatform] Platform ${platform.name} ${enabled ? 'enabled' : 'disabled'}');
  }

  // ============================================================
  // STATISTICS
  // ============================================================

  /// Get deployment statistics
  Future<Map<String, dynamic>> getDeploymentStatistics({
    DateTime? since,
  }) async {
    final query = since != null
        ? _deploymentsCollection.where(
            'startedAt',
            isGreaterThanOrEqualTo: Timestamp.fromDate(since),
          )
        : _deploymentsCollection;

    final snapshot = await query.get();
    final deployments = snapshot.docs.map((d) => Deployment.fromFirestore(d)).toList();

    final byPlatform = <DeploymentPlatform, int>{};
    final byStatus = <DeploymentStatus, int>{};
    var totalDuration = Duration.zero;
    var completedCount = 0;

    for (final deployment in deployments) {
      byPlatform[deployment.platform] = (byPlatform[deployment.platform] ?? 0) + 1;
      byStatus[deployment.status] = (byStatus[deployment.status] ?? 0) + 1;

      if (deployment.duration != null) {
        totalDuration += deployment.duration!;
        completedCount++;
      }
    }

    return {
      'total': deployments.length,
      'byPlatform': byPlatform.map((k, v) => MapEntry(k.name, v)),
      'byStatus': byStatus.map((k, v) => MapEntry(k.name, v)),
      'averageDuration': completedCount > 0
          ? Duration(milliseconds: totalDuration.inMilliseconds ~/ completedCount)
          : Duration.zero,
      'successRate': deployments.isNotEmpty
          ? (byStatus[DeploymentStatus.deployed] ?? 0) / deployments.length
          : 0.0,
    };
  }

  void dispose() {
    _deploymentController.close();
  }
}
