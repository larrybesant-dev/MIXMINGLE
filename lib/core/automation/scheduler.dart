/// Scheduler
///
/// Manages scheduled tasks including hourly, daily, and weekly
/// maintenance and automation routines.
library;

import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../analytics/analytics_service.dart';
import 'automation_service.dart';

/// Represents a scheduled task
class ScheduledTask {
  final String id;
  final String name;
  final TaskFrequency frequency;
  final Future<void> Function() action;
  final bool isEnabled;
  final DateTime? lastRun;
  final DateTime? nextRun;
  final int consecutiveFailures;

  ScheduledTask({
    required this.id,
    required this.name,
    required this.frequency,
    required this.action,
    this.isEnabled = true,
    this.lastRun,
    this.nextRun,
    this.consecutiveFailures = 0,
  });

  ScheduledTask copyWith({
    DateTime? lastRun,
    DateTime? nextRun,
    int? consecutiveFailures,
    bool? isEnabled,
  }) {
    return ScheduledTask(
      id: id,
      name: name,
      frequency: frequency,
      action: action,
      isEnabled: isEnabled ?? this.isEnabled,
      lastRun: lastRun ?? this.lastRun,
      nextRun: nextRun ?? this.nextRun,
      consecutiveFailures: consecutiveFailures ?? this.consecutiveFailures,
    );
  }
}

enum TaskFrequency {
  hourly,
  daily,
  weekly,
  custom,
}

/// Result of a scheduled run
class ScheduleRunResult {
  final TaskFrequency frequency;
  final int tasksRun;
  final int tasksSucceeded;
  final int tasksFailed;
  final Duration totalDuration;
  final DateTime completedAt;
  final List<String> errors;

  const ScheduleRunResult({
    required this.frequency,
    required this.tasksRun,
    required this.tasksSucceeded,
    required this.tasksFailed,
    required this.totalDuration,
    required this.completedAt,
    this.errors = const [],
  });

  Map<String, dynamic> toMap() => {
    'frequency': frequency.name,
    'tasksRun': tasksRun,
    'tasksSucceeded': tasksSucceeded,
    'tasksFailed': tasksFailed,
    'totalDurationMs': totalDuration.inMilliseconds,
    'completedAt': completedAt.toIso8601String(),
    'errors': errors,
  };
}

/// Service for managing scheduled tasks
class Scheduler {
  static Scheduler? _instance;
  static Scheduler get instance => _instance ??= Scheduler._();

  Scheduler._();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Collections
  CollectionReference<Map<String, dynamic>> get _scheduleLogsCollection =>
      _firestore.collection('schedule_logs');

  // Timers
  Timer? _hourlyTimer;
  Timer? _dailyTimer;
  Timer? _weeklyTimer;

  // Task registries
  final Map<String, ScheduledTask> _hourlyTasks = {};
  final Map<String, ScheduledTask> _dailyTasks = {};
  final Map<String, ScheduledTask> _weeklyTasks = {};

  // Stream controllers
  final _runResultController = StreamController<ScheduleRunResult>.broadcast();

  /// Stream of run results
  Stream<ScheduleRunResult> get runResultStream => _runResultController.stream;

  /// Initialize scheduler and register default tasks
  Future<void> initialize() async {
    _registerDefaultTasks();
    _startScheduler();

    AnalyticsService.instance.logEvent(
      name: 'scheduler_initialized',
      parameters: {
        'hourly_tasks': _hourlyTasks.length,
        'daily_tasks': _dailyTasks.length,
        'weekly_tasks': _weeklyTasks.length,
      },
    );
  }

  /// Register a task
  void registerTask(ScheduledTask task) {
    switch (task.frequency) {
      case TaskFrequency.hourly:
        _hourlyTasks[task.id] = task;
        break;
      case TaskFrequency.daily:
        _dailyTasks[task.id] = task;
        break;
      case TaskFrequency.weekly:
        _weeklyTasks[task.id] = task;
        break;
      case TaskFrequency.custom:
        // Custom tasks need special handling
        break;
    }

    debugPrint('📋 [Scheduler] Registered task: ${task.name} (${task.frequency.name})');
  }

  /// Unregister a task
  void unregisterTask(String taskId, TaskFrequency frequency) {
    switch (frequency) {
      case TaskFrequency.hourly:
        _hourlyTasks.remove(taskId);
        break;
      case TaskFrequency.daily:
        _dailyTasks.remove(taskId);
        break;
      case TaskFrequency.weekly:
        _weeklyTasks.remove(taskId);
        break;
      case TaskFrequency.custom:
        break;
    }
  }

  /// Enable or disable a task
  void setTaskEnabled(String taskId, TaskFrequency frequency, bool enabled) {
    final tasks = _getTaskMap(frequency);
    if (tasks.containsKey(taskId)) {
      tasks[taskId] = tasks[taskId]!.copyWith(isEnabled: enabled);
    }
  }

  /// Run hourly tasks
  Future<ScheduleRunResult> runHourlyTasks() async {
    return _runTasks(TaskFrequency.hourly, _hourlyTasks.values.toList());
  }

  /// Run daily tasks
  Future<ScheduleRunResult> runDailyTasks() async {
    return _runTasks(TaskFrequency.daily, _dailyTasks.values.toList());
  }

  /// Run weekly tasks
  Future<ScheduleRunResult> runWeeklyTasks() async {
    return _runTasks(TaskFrequency.weekly, _weeklyTasks.values.toList());
  }

  /// Manually trigger a specific task
  Future<bool> runTask(String taskId, TaskFrequency frequency) async {
    final tasks = _getTaskMap(frequency);
    final task = tasks[taskId];
    if (task == null) return false;

    try {
      await task.action();
      tasks[taskId] = task.copyWith(
        lastRun: DateTime.now(),
        consecutiveFailures: 0,
      );
      return true;
    } catch (e) {
      tasks[taskId] = task.copyWith(
        lastRun: DateTime.now(),
        consecutiveFailures: task.consecutiveFailures + 1,
      );
      debugPrint('❌ [Scheduler] Task ${task.name} failed: $e');
      return false;
    }
  }

  /// Get all registered tasks
  Map<TaskFrequency, List<ScheduledTask>> getAllTasks() {
    return {
      TaskFrequency.hourly: _hourlyTasks.values.toList(),
      TaskFrequency.daily: _dailyTasks.values.toList(),
      TaskFrequency.weekly: _weeklyTasks.values.toList(),
    };
  }

  /// Get scheduler statistics
  Future<Map<String, dynamic>> getSchedulerStats() async {
    final now = DateTime.now();
    final weekAgo = now.subtract(const Duration(days: 7));

    final logsSnapshot = await _scheduleLogsCollection
        .where('completedAt', isGreaterThan: weekAgo.toIso8601String())
        .get();

    int totalRuns = 0;
    int successfulRuns = 0;
    int failedTasks = 0;
    Duration totalDuration = Duration.zero;

    for (final doc in logsSnapshot.docs) {
      final data = doc.data();
      totalRuns++;
      if ((data['tasksFailed'] as int? ?? 0) == 0) successfulRuns++;
      failedTasks += (data['tasksFailed'] as int?) ?? 0;
      totalDuration += Duration(milliseconds: (data['totalDurationMs'] as int?) ?? 0);
    }

    return {
      'total_registered_tasks': _hourlyTasks.length + _dailyTasks.length + _weeklyTasks.length,
      'hourly_tasks': _hourlyTasks.length,
      'daily_tasks': _dailyTasks.length,
      'weekly_tasks': _weeklyTasks.length,
      'runs_last_7_days': totalRuns,
      'successful_runs': successfulRuns,
      'failed_tasks': failedTasks,
      'total_processing_time_minutes': totalDuration.inMinutes,
    };
  }

  /// Get next scheduled run times
  Map<TaskFrequency, DateTime?> getNextRunTimes() {
    final now = DateTime.now();

    // Next hour
    final nextHour = DateTime(now.year, now.month, now.day, now.hour + 1);

    // Next day at midnight
    final nextDay = DateTime(now.year, now.month, now.day + 1);

    // Next Sunday at midnight
    final daysUntilSunday = DateTime.sunday - now.weekday;
    final nextWeek = DateTime(
      now.year,
      now.month,
      now.day + (daysUntilSunday <= 0 ? 7 + daysUntilSunday : daysUntilSunday),
    );

    return {
      TaskFrequency.hourly: nextHour,
      TaskFrequency.daily: nextDay,
      TaskFrequency.weekly: nextWeek,
    };
  }

  // Private methods

  void _registerDefaultTasks() {
    final automation = AutomationService.instance;

    // Hourly tasks
    registerTask(ScheduledTask(
      id: 'stale_presence_check',
      name: 'Stale Presence Check',
      frequency: TaskFrequency.hourly,
      action: () => automation.autoDetectStalePresence(),
    ));

    // Daily tasks
    registerTask(ScheduledTask(
      id: 'clean_inactive_rooms',
      name: 'Clean Inactive Rooms',
      frequency: TaskFrequency.daily,
      action: () => automation.autoCleanInactiveRooms(),
    ));

    registerTask(ScheduledTask(
      id: 'fix_room_state',
      name: 'Fix Corrupted Room State',
      frequency: TaskFrequency.daily,
      action: () => automation.autoFixCorruptedRoomState(),
    ));

    registerTask(ScheduledTask(
      id: 'purge_old_logs',
      name: 'Purge Old Logs',
      frequency: TaskFrequency.daily,
      action: () => automation.autoPurgeOldLogs(),
    ));

    // Weekly tasks
    registerTask(ScheduledTask(
      id: 'archive_old_messages',
      name: 'Archive Old Messages',
      frequency: TaskFrequency.weekly,
      action: () => automation.autoArchiveOldMessages(),
    ));

    registerTask(ScheduledTask(
      id: 'weekly_cleanup',
      name: 'Weekly Comprehensive Cleanup',
      frequency: TaskFrequency.weekly,
      action: () => _runWeeklyCleanup(),
    ));
  }

  void _startScheduler() {
    // Run hourly tasks at the start of each hour
    final now = DateTime.now();
    final nextHour = DateTime(now.year, now.month, now.day, now.hour + 1);
    final delayToNextHour = nextHour.difference(now);

    Timer(delayToNextHour, () {
      runHourlyTasks();
      _hourlyTimer = Timer.periodic(const Duration(hours: 1), (_) {
        runHourlyTasks();
      });
    });

    // Run daily tasks at midnight
    final nextMidnight = DateTime(now.year, now.month, now.day + 1);
    final delayToMidnight = nextMidnight.difference(now);

    Timer(delayToMidnight, () {
      runDailyTasks();
      _dailyTimer = Timer.periodic(const Duration(days: 1), (_) {
        runDailyTasks();
      });
    });

    // Run weekly tasks on Sunday at midnight
    final daysUntilSunday = DateTime.sunday - now.weekday;
    final nextSunday = DateTime(
      now.year,
      now.month,
      now.day + (daysUntilSunday <= 0 ? 7 + daysUntilSunday : daysUntilSunday),
    );
    final delayToSunday = nextSunday.difference(now);

    Timer(delayToSunday, () {
      runWeeklyTasks();
      _weeklyTimer = Timer.periodic(const Duration(days: 7), (_) {
        runWeeklyTasks();
      });
    });

    debugPrint('⏰ [Scheduler] Started');
    debugPrint('   Next hourly: $nextHour');
    debugPrint('   Next daily: $nextMidnight');
    debugPrint('   Next weekly: $nextSunday');
  }

  Future<ScheduleRunResult> _runTasks(
    TaskFrequency frequency,
    List<ScheduledTask> tasks,
  ) async {
    final startTime = DateTime.now();
    int succeeded = 0;
    int failed = 0;
    final errors = <String>[];

    final enabledTasks = tasks.where((t) => t.isEnabled).toList();

    debugPrint('🏃 [Scheduler] Running ${frequency.name} tasks (${enabledTasks.length} enabled)');

    for (final task in enabledTasks) {
      try {
        await task.action();
        succeeded++;

        // Update task state
        final taskMap = _getTaskMap(frequency);
        taskMap[task.id] = task.copyWith(
          lastRun: DateTime.now(),
          consecutiveFailures: 0,
        );

        debugPrint('✅ [Scheduler] Task "${task.name}" completed');
      } catch (e) {
        failed++;
        errors.add('${task.name}: $e');

        // Update task state
        final taskMap = _getTaskMap(frequency);
        taskMap[task.id] = task.copyWith(
          lastRun: DateTime.now(),
          consecutiveFailures: task.consecutiveFailures + 1,
        );

        debugPrint('❌ [Scheduler] Task "${task.name}" failed: $e');
      }
    }

    final result = ScheduleRunResult(
      frequency: frequency,
      tasksRun: enabledTasks.length,
      tasksSucceeded: succeeded,
      tasksFailed: failed,
      totalDuration: DateTime.now().difference(startTime),
      completedAt: DateTime.now(),
      errors: errors,
    );

    await _recordRunResult(result);
    _runResultController.add(result);

    AnalyticsService.instance.logEvent(
      name: 'scheduled_tasks_run',
      parameters: {
        'frequency': frequency.name,
        'tasks_run': enabledTasks.length,
        'succeeded': succeeded,
        'failed': failed,
      },
    );

    return result;
  }

  Future<void> _runWeeklyCleanup() async {
    final automation = AutomationService.instance;

    // Run all cleanup tasks
    await automation.autoCleanInactiveRooms();
    await automation.autoArchiveOldMessages();
    await automation.autoPurgeOldLogs();
    await automation.autoDetectStalePresence();
    await automation.autoFixCorruptedRoomState();
  }

  Map<String, ScheduledTask> _getTaskMap(TaskFrequency frequency) {
    switch (frequency) {
      case TaskFrequency.hourly:
        return _hourlyTasks;
      case TaskFrequency.daily:
        return _dailyTasks;
      case TaskFrequency.weekly:
        return _weeklyTasks;
      case TaskFrequency.custom:
        return {};
    }
  }

  Future<void> _recordRunResult(ScheduleRunResult result) async {
    await _scheduleLogsCollection.add(result.toMap());
  }

  /// Dispose resources
  void dispose() {
    _hourlyTimer?.cancel();
    _dailyTimer?.cancel();
    _weeklyTimer?.cancel();
    _runResultController.close();
  }
}
