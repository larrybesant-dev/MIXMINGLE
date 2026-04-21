import 'runtime_telemetry.dart';

enum AlertLevel { info, warning, critical }

class ProductionAlert {
  final String id;
  final String message;
  final AlertLevel level;
  final DateTime timestamp;

  ProductionAlert({
    required this.id,
    required this.message,
    required this.level,
    required this.timestamp,
  });
}

class ProductionAlertSystem {
  static final List<ProductionAlert> _alerts = [];

  // ─────────────────────────────
  // ALERT STREAM (simple in-memory)
  // ─────────────────────────────

  static List<ProductionAlert> get alerts => _alerts;

  static void _emit(String id, String message, AlertLevel level) {
    _alerts.add(
      ProductionAlert(
        id: id,
        message: message,
        level: level,
        timestamp: DateTime.now(),
      ),
    );
  }

  // ─────────────────────────────
  // FIRESTORE / LISTENER RULES
  // ─────────────────────────────

  static void checkListeners() {
    final listeners = RuntimeTelemetry.listeners;

    listeners.forEach((key, count) {
      if (count > 50) {
        _emit(
          "listener_spike",
          "High listener count detected on $key: $count",
          AlertLevel.critical,
        );
      } else if (count > 20) {
        _emit(
          "listener_warning",
          "Elevated listeners on $key: $count",
          AlertLevel.warning,
        );
      }
    });
  }

  // ─────────────────────────────
  // REBUILD RULES
  // ─────────────────────────────

  static void checkRebuilds() {
    final rebuilds = RuntimeTelemetry.rebuilds;

    rebuilds.forEach((key, count) {
      if (count > 200) {
        _emit(
          "rebuild_storm",
          "Rebuild storm detected in $key: $count rebuilds",
          AlertLevel.critical,
        );
      } else if (count > 80) {
        _emit(
          "rebuild_spike",
          "High rebuild frequency in $key: $count",
          AlertLevel.warning,
        );
      }
    });
  }

  // ─────────────────────────────
  // SYSTEM HEALTH CHECK
  // ─────────────────────────────

  static void runHealthCheck() {
    checkListeners();
    checkRebuilds();
  }

  static void reset() {
    _alerts.clear();
  }
}
