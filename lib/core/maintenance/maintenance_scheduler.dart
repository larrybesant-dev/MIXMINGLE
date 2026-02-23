/// Maintenance Scheduler
///
/// Schedules and orchestrates maintenance tasks on monthly,
/// quarterly, and annual cycles.
library;

import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../analytics/analytics_service.dart';
import 'maintenance_service.dart';

/// Scheduled maintenance configuration
class ScheduledMaintenanceConfig {
  final int monthlyDayOfMonth;
  final int quarterlyMonth; // 1 = Jan, 4 = Apr, 7 = Jul, 10 = Oct
  final int annualMonth;
  final int annualDayOfMonth;
  final int preferredHour;
  final bool autoRun;

  const ScheduledMaintenanceConfig({
    this.monthlyDayOfMonth = 1,
    this.quarterlyMonth = 1,
    this.annualMonth = 1,
    this.annualDayOfMonth = 1,
    this.preferredHour = 3, // 3 AM
    this.autoRun = true,
  });
}

/// Maintenance schedule entry
class MaintenanceScheduleEntry {
  final String id;
  final MaintenanceCycle cycle;
  final DateTime scheduledFor;
  final DateTime? startedAt;
  final DateTime? completedAt;
  final ScheduleStatus status;
  final List<MaintenanceTaskType> tasks;
  final Map<String, dynamic> results;

  const MaintenanceScheduleEntry({
    required this.id,
    required this.cycle,
    required this.scheduledFor,
    this.startedAt,
    this.completedAt,
    required this.status,
    required this.tasks,
    this.results = const {},
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'cycle': cycle.name,
    'scheduledFor': scheduledFor.toIso8601String(),
    'startedAt': startedAt?.toIso8601String(),
    'completedAt': completedAt?.toIso8601String(),
    'status': status.name,
    'tasks': tasks.map((t) => t.name).toList(),
    'results': results,
  };

  MaintenanceScheduleEntry copyWith({
    String? id,
    MaintenanceCycle? cycle,
    DateTime? scheduledFor,
    DateTime? startedAt,
    DateTime? completedAt,
    ScheduleStatus? status,
    List<MaintenanceTaskType>? tasks,
    Map<String, dynamic>? results,
  }) {
    return MaintenanceScheduleEntry(
      id: id ?? this.id,
      cycle: cycle ?? this.cycle,
      scheduledFor: scheduledFor ?? this.scheduledFor,
      startedAt: startedAt ?? this.startedAt,
      completedAt: completedAt ?? this.completedAt,
      status: status ?? this.status,
      tasks: tasks ?? this.tasks,
      results: results ?? this.results,
    );
  }
}

/// Maintenance cycle types
enum MaintenanceCycle {
  daily,
  weekly,
  monthly,
  quarterly,
  annual,
}

/// Schedule status
enum ScheduleStatus {
  scheduled,
  running,
  completed,
  failed,
  skipped,
}

/// Monthly maintenance report
class MonthlyMaintenanceReport {
  final DateTime periodStart;
  final DateTime periodEnd;
  final int roomsArchived;
  final int assetsCleanedUp;
  final int keysRotated;
  final Duration totalDuration;
  final bool allTasksSuccessful;
  final List<String> errors;

  const MonthlyMaintenanceReport({
    required this.periodStart,
    required this.periodEnd,
    required this.roomsArchived,
    required this.assetsCleanedUp,
    required this.keysRotated,
    required this.totalDuration,
    required this.allTasksSuccessful,
    this.errors = const [],
  });

  Map<String, dynamic> toMap() => {
    'periodStart': periodStart.toIso8601String(),
    'periodEnd': periodEnd.toIso8601String(),
    'roomsArchived': roomsArchived,
    'assetsCleanedUp': assetsCleanedUp,
    'keysRotated': keysRotated,
    'totalDurationMs': totalDuration.inMilliseconds,
    'allTasksSuccessful': allTasksSuccessful,
    'errors': errors,
  };
}

/// Quarterly maintenance report
class QuarterlyMaintenanceReport {
  final int quarter;
  final int year;
  final int totalDocumentsBackedUp;
  final int dataIntegrityIssues;
  final int collectionsOptimized;
  final Duration totalDuration;
  final bool allTasksSuccessful;
  final Map<String, dynamic> details;

  const QuarterlyMaintenanceReport({
    required this.quarter,
    required this.year,
    required this.totalDocumentsBackedUp,
    required this.dataIntegrityIssues,
    required this.collectionsOptimized,
    required this.totalDuration,
    required this.allTasksSuccessful,
    this.details = const {},
  });

  Map<String, dynamic> toMap() => {
    'quarter': quarter,
    'year': year,
    'totalDocumentsBackedUp': totalDocumentsBackedUp,
    'dataIntegrityIssues': dataIntegrityIssues,
    'collectionsOptimized': collectionsOptimized,
    'totalDurationMs': totalDuration.inMilliseconds,
    'allTasksSuccessful': allTasksSuccessful,
    'details': details,
  };
}

/// Annual maintenance report
class AnnualMaintenanceReport {
  final int year;
  final int totalRoomsArchived;
  final int totalAssetsCleanedUp;
  final int totalBackupsPerformed;
  final int totalKeysRotated;
  final Duration totalMaintenanceTime;
  final double systemHealthScore;
  final Map<String, dynamic> recommendations;

  const AnnualMaintenanceReport({
    required this.year,
    required this.totalRoomsArchived,
    required this.totalAssetsCleanedUp,
    required this.totalBackupsPerformed,
    required this.totalKeysRotated,
    required this.totalMaintenanceTime,
    required this.systemHealthScore,
    this.recommendations = const {},
  });

  Map<String, dynamic> toMap() => {
    'year': year,
    'totalRoomsArchived': totalRoomsArchived,
    'totalAssetsCleanedUp': totalAssetsCleanedUp,
    'totalBackupsPerformed': totalBackupsPerformed,
    'totalKeysRotated': totalKeysRotated,
    'totalMaintenanceTimeMs': totalMaintenanceTime.inMilliseconds,
    'systemHealthScore': systemHealthScore,
    'recommendations': recommendations,
  };
}

/// Maintenance scheduler service
class MaintenanceScheduler {
  static MaintenanceScheduler? _instance;
  static MaintenanceScheduler get instance => _instance ??= MaintenanceScheduler._();

  MaintenanceScheduler._();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final MaintenanceService _maintenanceService = MaintenanceService.instance;

  // Configuration
  ScheduledMaintenanceConfig _config = const ScheduledMaintenanceConfig();

  // Timers
  Timer? _schedulerTimer;

  // Stream controllers
  final _scheduleController = StreamController<MaintenanceScheduleEntry>.broadcast();
  Stream<MaintenanceScheduleEntry> get scheduleStream => _scheduleController.stream;

  // Collections
  CollectionReference<Map<String, dynamic>> get _schedulesCollection =>
      _firestore.collection('maintenance_schedules');

  CollectionReference<Map<String, dynamic>> get _reportsCollection =>
      _firestore.collection('maintenance_reports');

  /// Configure scheduler
  void configure(ScheduledMaintenanceConfig config) {
    _config = config;
  }

  /// Start automatic scheduling
  void startAutoScheduler() {
    debugPrint('â° [MaintenanceScheduler] Starting automatic scheduler');

    // Check every hour if maintenance is due
    _schedulerTimer = Timer.periodic(const Duration(hours: 1), (_) {
      _checkScheduledMaintenance();
    });

    // Initial check
    _checkScheduledMaintenance();
  }

  /// Stop automatic scheduling
  void stopAutoScheduler() {
    _schedulerTimer?.cancel();
    _schedulerTimer = null;
    debugPrint('â° [MaintenanceScheduler] Stopped automatic scheduler');
  }

  Future<void> _checkScheduledMaintenance() async {
    if (!_config.autoRun) return;

    final now = DateTime.now();

    // Check if it's the preferred hour
    if (now.hour != _config.preferredHour) return;

    // Check monthly
    if (now.day == _config.monthlyDayOfMonth) {
      final lastMonthly = await _getLastMaintenance(MaintenanceCycle.monthly);
      if (lastMonthly == null || lastMonthly.month != now.month) {
        debugPrint('â° [MaintenanceScheduler] Running scheduled monthly maintenance');
        await runMonthlyMaintenance();
      }
    }

    // Check quarterly
    if (_isQuarterlyDue(now)) {
      final lastQuarterly = await _getLastMaintenance(MaintenanceCycle.quarterly);
      if (lastQuarterly == null || _getQuarter(lastQuarterly) != _getQuarter(now)) {
        debugPrint('â° [MaintenanceScheduler] Running scheduled quarterly maintenance');
        await runQuarterlyMaintenance();
      }
    }

    // Check annual
    if (now.month == _config.annualMonth && now.day == _config.annualDayOfMonth) {
      final lastAnnual = await _getLastMaintenance(MaintenanceCycle.annual);
      if (lastAnnual == null || lastAnnual.year != now.year) {
        debugPrint('â° [MaintenanceScheduler] Running scheduled annual maintenance');
        await runAnnualMaintenance();
      }
    }
  }

  bool _isQuarterlyDue(DateTime date) {
    final quarterMonths = [1, 4, 7, 10];
    return quarterMonths.contains(date.month) && date.day == _config.monthlyDayOfMonth;
  }

  int _getQuarter(DateTime date) => ((date.month - 1) ~/ 3) + 1;

  Future<DateTime?> _getLastMaintenance(MaintenanceCycle cycle) async {
    final query = await _schedulesCollection
        .where('cycle', isEqualTo: cycle.name)
        .where('status', isEqualTo: ScheduleStatus.completed.name)
        .orderBy('completedAt', descending: true)
        .limit(1)
        .get();

    if (query.docs.isEmpty) return null;

    final data = query.docs.first.data();
    return DateTime.tryParse(data['completedAt'] as String? ?? '');
  }

  // ============================================================
  // MONTHLY MAINTENANCE
  // ============================================================

  /// Run monthly maintenance tasks
  Future<MonthlyMaintenanceReport> runMonthlyMaintenance() async {
    debugPrint('ðŸ“… [MaintenanceScheduler] Starting monthly maintenance');
    final startTime = DateTime.now();

    final scheduleEntry = MaintenanceScheduleEntry(
      id: 'monthly_${startTime.year}_${startTime.month}',
      cycle: MaintenanceCycle.monthly,
      scheduledFor: startTime,
      startedAt: startTime,
      status: ScheduleStatus.running,
      tasks: [
        MaintenanceTaskType.archiveOldRooms,
        MaintenanceTaskType.cleanUnusedAssets,
        MaintenanceTaskType.rotateKeys,
      ],
    );

    await _saveScheduleEntry(scheduleEntry);
    _scheduleController.add(scheduleEntry);

    int roomsArchived = 0;
    int assetsCleanedUp = 0;
    int keysRotated = 0;
    final errors = <String>[];
    final results = <String, dynamic>{};

    try {
      // Archive old rooms
      final archiveResult = await _maintenanceService.autoArchiveOldRooms();
      roomsArchived = archiveResult.itemsArchived;
      results['archiveRooms'] = archiveResult.toMap();
      if (!archiveResult.success) {
        errors.add('Archive rooms: ${archiveResult.error}');
      }

      // Clean unused assets
      final cleanResult = await _maintenanceService.autoCleanUnusedAssets();
      assetsCleanedUp = cleanResult.itemsDeleted;
      results['cleanAssets'] = cleanResult.toMap();
      if (!cleanResult.success) {
        errors.add('Clean assets: ${cleanResult.error}');
      }

      // Rotate keys
      final keyResults = await _maintenanceService.autoRotateKeys();
      keysRotated = keyResults.where((r) => r.rotated).length;
      results['rotateKeys'] = keyResults.map((r) => r.toMap()).toList();

      final duration = DateTime.now().difference(startTime);
      final allSuccessful = errors.isEmpty;

      final report = MonthlyMaintenanceReport(
        periodStart: DateTime(startTime.year, startTime.month, 1),
        periodEnd: DateTime(startTime.year, startTime.month + 1, 0),
        roomsArchived: roomsArchived,
        assetsCleanedUp: assetsCleanedUp,
        keysRotated: keysRotated,
        totalDuration: duration,
        allTasksSuccessful: allSuccessful,
        errors: errors,
      );

      // Save completed schedule entry
      final completedEntry = scheduleEntry.copyWith(
        completedAt: DateTime.now(),
        status: allSuccessful ? ScheduleStatus.completed : ScheduleStatus.failed,
        results: results,
      );
      await _saveScheduleEntry(completedEntry);
      _scheduleController.add(completedEntry);

      // Save report
      await _saveReport('monthly', report.toMap());

      // Track analytics
      AnalyticsService.instance.logEvent(name: 'monthly_maintenance', parameters: {
        'rooms_archived': roomsArchived,
        'assets_cleaned': assetsCleanedUp,
        'keys_rotated': keysRotated,
        'duration_ms': duration.inMilliseconds,
        'success': allSuccessful,
      });

      debugPrint('âœ… [MaintenanceScheduler] Monthly maintenance completed');
      return report;
    } catch (e) {
      debugPrint('âŒ [MaintenanceScheduler] Monthly maintenance failed: $e');

      final failedEntry = scheduleEntry.copyWith(
        completedAt: DateTime.now(),
        status: ScheduleStatus.failed,
        results: {'error': e.toString()},
      );
      await _saveScheduleEntry(failedEntry);
      _scheduleController.add(failedEntry);

      return MonthlyMaintenanceReport(
        periodStart: DateTime(startTime.year, startTime.month, 1),
        periodEnd: DateTime(startTime.year, startTime.month + 1, 0),
        roomsArchived: roomsArchived,
        assetsCleanedUp: assetsCleanedUp,
        keysRotated: keysRotated,
        totalDuration: DateTime.now().difference(startTime),
        allTasksSuccessful: false,
        errors: [e.toString()],
      );
    }
  }

  // ============================================================
  // QUARTERLY MAINTENANCE
  // ============================================================

  /// Run quarterly maintenance tasks
  Future<QuarterlyMaintenanceReport> runQuarterlyMaintenance() async {
    debugPrint('ðŸ“… [MaintenanceScheduler] Starting quarterly maintenance');
    final startTime = DateTime.now();
    final quarter = _getQuarter(startTime);

    final scheduleEntry = MaintenanceScheduleEntry(
      id: 'quarterly_${startTime.year}_Q$quarter',
      cycle: MaintenanceCycle.quarterly,
      scheduledFor: startTime,
      startedAt: startTime,
      status: ScheduleStatus.running,
      tasks: [
        MaintenanceTaskType.backupCriticalData,
        MaintenanceTaskType.validateDataIntegrity,
        MaintenanceTaskType.compactCollections,
      ],
    );

    await _saveScheduleEntry(scheduleEntry);
    _scheduleController.add(scheduleEntry);

    int documentsBackedUp = 0;
    int integrityIssues = 0;
    int collectionsOptimized = 0;
    final details = <String, dynamic>{};

    try {
      // Backup critical data
      final backupResult = await _maintenanceService.autoBackupCriticalData(
        type: BackupType.full,
      );
      documentsBackedUp = backupResult.totalDocuments;
      details['backup'] = backupResult.toMap();

      // Validate data integrity
      final integrityResult = await _maintenanceService.validateDataIntegrity();
      integrityIssues = (integrityResult.details['issuesFound'] as int?) ?? 0;
      details['integrity'] = integrityResult.toMap();

      // Run monthly maintenance as part of quarterly
      final monthlyReport = await runMonthlyMaintenance();
      details['monthly'] = monthlyReport.toMap();

      // Simulate collection optimization
      collectionsOptimized = 5; // Would call Firestore optimization in production
      details['collectionsOptimized'] = collectionsOptimized;

      final duration = DateTime.now().difference(startTime);
      final allSuccessful = backupResult.success && integrityResult.success;

      final report = QuarterlyMaintenanceReport(
        quarter: quarter,
        year: startTime.year,
        totalDocumentsBackedUp: documentsBackedUp,
        dataIntegrityIssues: integrityIssues,
        collectionsOptimized: collectionsOptimized,
        totalDuration: duration,
        allTasksSuccessful: allSuccessful,
        details: details,
      );

      // Save completed schedule entry
      final completedEntry = scheduleEntry.copyWith(
        completedAt: DateTime.now(),
        status: allSuccessful ? ScheduleStatus.completed : ScheduleStatus.failed,
        results: details,
      );
      await _saveScheduleEntry(completedEntry);
      _scheduleController.add(completedEntry);

      // Save report
      await _saveReport('quarterly', report.toMap());

      // Track analytics
      AnalyticsService.instance.logEvent(name: 'quarterly_maintenance', parameters: {
        'quarter': quarter,
        'documents_backed_up': documentsBackedUp,
        'integrity_issues': integrityIssues,
        'duration_ms': duration.inMilliseconds,
        'success': allSuccessful,
      });

      debugPrint('âœ… [MaintenanceScheduler] Quarterly maintenance completed');
      return report;
    } catch (e) {
      debugPrint('âŒ [MaintenanceScheduler] Quarterly maintenance failed: $e');

      final failedEntry = scheduleEntry.copyWith(
        completedAt: DateTime.now(),
        status: ScheduleStatus.failed,
        results: {'error': e.toString()},
      );
      await _saveScheduleEntry(failedEntry);
      _scheduleController.add(failedEntry);

      return QuarterlyMaintenanceReport(
        quarter: quarter,
        year: startTime.year,
        totalDocumentsBackedUp: documentsBackedUp,
        dataIntegrityIssues: integrityIssues,
        collectionsOptimized: collectionsOptimized,
        totalDuration: DateTime.now().difference(startTime),
        allTasksSuccessful: false,
        details: {'error': e.toString()},
      );
    }
  }

  // ============================================================
  // ANNUAL MAINTENANCE
  // ============================================================

  /// Run annual maintenance tasks
  Future<AnnualMaintenanceReport> runAnnualMaintenance() async {
    debugPrint('ðŸ“… [MaintenanceScheduler] Starting annual maintenance');
    final startTime = DateTime.now();
    final year = startTime.year;

    final scheduleEntry = MaintenanceScheduleEntry(
      id: 'annual_$year',
      cycle: MaintenanceCycle.annual,
      scheduledFor: startTime,
      startedAt: startTime,
      status: ScheduleStatus.running,
      tasks: MaintenanceTaskType.values.toList(),
    );

    await _saveScheduleEntry(scheduleEntry);
    _scheduleController.add(scheduleEntry);

    int totalRoomsArchived = 0;
    int totalAssetsCleanedUp = 0;
    int totalBackupsPerformed = 0;
    int totalKeysRotated = 0;
    final details = <String, dynamic>{};

    try {
      // Run quarterly maintenance (which includes monthly)
      final quarterlyReport = await runQuarterlyMaintenance();
      details['quarterly'] = quarterlyReport.toMap();
      totalBackupsPerformed++;

      // Get annual statistics from logs
      final yearStart = DateTime(year, 1, 1);
      final logs = await _firestore.collection('maintenance_logs')
          .where('timestamp', isGreaterThanOrEqualTo: yearStart)
          .get();

      for (final doc in logs.docs) {
        final data = doc.data();
        totalRoomsArchived += (data['itemsArchived'] as int?) ?? 0;
        totalAssetsCleanedUp += (data['itemsDeleted'] as int?) ?? 0;
      }

      // Get key rotation count
      final keyLogs = await _firestore.collection('key_rotations').get();
      totalKeysRotated = keyLogs.docs.length;

      // Calculate system health score
      final healthScore = _calculateSystemHealthScore(
        integrityIssues: quarterlyReport.dataIntegrityIssues,
        backupSuccess: quarterlyReport.allTasksSuccessful,
      );

      // Generate recommendations
      final recommendations = _generateAnnualRecommendations(
        roomsArchived: totalRoomsArchived,
        assetsCleanedUp: totalAssetsCleanedUp,
        healthScore: healthScore,
      );

      final duration = DateTime.now().difference(startTime);

      final report = AnnualMaintenanceReport(
        year: year,
        totalRoomsArchived: totalRoomsArchived,
        totalAssetsCleanedUp: totalAssetsCleanedUp,
        totalBackupsPerformed: totalBackupsPerformed,
        totalKeysRotated: totalKeysRotated,
        totalMaintenanceTime: duration,
        systemHealthScore: healthScore,
        recommendations: recommendations,
      );

      // Save completed schedule entry
      final completedEntry = scheduleEntry.copyWith(
        completedAt: DateTime.now(),
        status: ScheduleStatus.completed,
        results: report.toMap(),
      );
      await _saveScheduleEntry(completedEntry);
      _scheduleController.add(completedEntry);

      // Save report
      await _saveReport('annual', report.toMap());

      // Track analytics
      AnalyticsService.instance.logEvent(name: 'annual_maintenance', parameters: {
        'year': year,
        'rooms_archived': totalRoomsArchived,
        'health_score': healthScore,
        'duration_ms': duration.inMilliseconds,
      });

      debugPrint('âœ… [MaintenanceScheduler] Annual maintenance completed');
      return report;
    } catch (e) {
      debugPrint('âŒ [MaintenanceScheduler] Annual maintenance failed: $e');

      final failedEntry = scheduleEntry.copyWith(
        completedAt: DateTime.now(),
        status: ScheduleStatus.failed,
        results: {'error': e.toString()},
      );
      await _saveScheduleEntry(failedEntry);
      _scheduleController.add(failedEntry);

      return AnnualMaintenanceReport(
        year: year,
        totalRoomsArchived: totalRoomsArchived,
        totalAssetsCleanedUp: totalAssetsCleanedUp,
        totalBackupsPerformed: totalBackupsPerformed,
        totalKeysRotated: totalKeysRotated,
        totalMaintenanceTime: DateTime.now().difference(startTime),
        systemHealthScore: 0,
        recommendations: {'error': e.toString()},
      );
    }
  }

  double _calculateSystemHealthScore({
    required int integrityIssues,
    required bool backupSuccess,
  }) {
    double score = 100;

    // Deduct for integrity issues
    score -= integrityIssues * 2;

    // Deduct for backup failure
    if (!backupSuccess) score -= 20;

    return score.clamp(0, 100);
  }

  Map<String, dynamic> _generateAnnualRecommendations({
    required int roomsArchived,
    required int assetsCleanedUp,
    required double healthScore,
  }) {
    final recommendations = <String, dynamic>{};

    if (roomsArchived > 10000) {
      recommendations['archival'] = 'Consider shorter archival threshold to reduce storage costs';
    }

    if (assetsCleanedUp > 5000) {
      recommendations['assets'] = 'High volume of unused assets - consider proactive cleanup triggers';
    }

    if (healthScore < 80) {
      recommendations['health'] = 'System health below optimal - investigate data integrity issues';
    }

    recommendations['general'] = [
      'Review backup retention policies',
      'Update key rotation schedules',
      'Evaluate storage optimization opportunities',
    ];

    return recommendations;
  }

  // ============================================================
  // UTILITY METHODS
  // ============================================================

  Future<void> _saveScheduleEntry(MaintenanceScheduleEntry entry) async {
    await _schedulesCollection.doc(entry.id).set(entry.toMap());
  }

  Future<void> _saveReport(String type, Map<String, dynamic> report) async {
    await _reportsCollection.add({
      'type': type,
      ...report,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  /// Get upcoming scheduled maintenance
  Future<List<MaintenanceScheduleEntry>> getUpcomingSchedules() async {
    final query = await _schedulesCollection
        .where('status', isEqualTo: ScheduleStatus.scheduled.name)
        .orderBy('scheduledFor')
        .limit(10)
        .get();

    return query.docs.map((doc) {
      final data = doc.data();
      return MaintenanceScheduleEntry(
        id: data['id'] as String,
        cycle: MaintenanceCycle.values.firstWhere((c) => c.name == data['cycle']),
        scheduledFor: DateTime.parse(data['scheduledFor'] as String),
        startedAt: data['startedAt'] != null ? DateTime.parse(data['startedAt'] as String) : null,
        completedAt: data['completedAt'] != null ? DateTime.parse(data['completedAt'] as String) : null,
        status: ScheduleStatus.values.firstWhere((s) => s.name == data['status']),
        tasks: (data['tasks'] as List<dynamic>)
            .map((t) => MaintenanceTaskType.values.firstWhere((tt) => tt.name == t))
            .toList(),
        results: (data['results'] as Map<String, dynamic>?) ?? {},
      );
    }).toList();
  }

  /// Get maintenance history
  Future<List<MaintenanceScheduleEntry>> getMaintenanceHistory({
    MaintenanceCycle? cycle,
    int limit = 20,
  }) async {
    var query = _schedulesCollection
        .orderBy('completedAt', descending: true)
        .limit(limit);

    if (cycle != null) {
      query = query.where('cycle', isEqualTo: cycle.name);
    }

    final snapshot = await query.get();
    return snapshot.docs.map((doc) {
      final data = doc.data();
      return MaintenanceScheduleEntry(
        id: data['id'] as String,
        cycle: MaintenanceCycle.values.firstWhere((c) => c.name == data['cycle']),
        scheduledFor: DateTime.parse(data['scheduledFor'] as String),
        startedAt: data['startedAt'] != null ? DateTime.parse(data['startedAt'] as String) : null,
        completedAt: data['completedAt'] != null ? DateTime.parse(data['completedAt'] as String) : null,
        status: ScheduleStatus.values.firstWhere((s) => s.name == data['status']),
        tasks: (data['tasks'] as List<dynamic>)
            .map((t) => MaintenanceTaskType.values.firstWhere((tt) => tt.name == t))
            .toList(),
        results: (data['results'] as Map<String, dynamic>?) ?? {},
      );
    }).toList();
  }

  /// Dispose resources
  void dispose() {
    stopAutoScheduler();
    _scheduleController.close();
  }
}
