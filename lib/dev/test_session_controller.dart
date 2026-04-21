import '../observability/runtime_telemetry.dart';
import '../observability/production_alerts.dart';
import '../observability/event_timeline.dart';

class TestSessionController {
  static String? _activeSession;

  static void startSession(String name) {
    _activeSession = name;

    RuntimeTelemetry.reset();
    ProductionAlertSystem.reset();
    EventTimeline.clear();

    print("🧪 TEST SESSION STARTED: $name");
  }

  static void endSession() {
    print("🧪 TEST SESSION COMPLETE");

    print("📊 FINAL METRICS:");
    print("Listeners: \\${RuntimeTelemetry.listeners}");
    print("Rebuilds: \\${RuntimeTelemetry.rebuilds}");
    print("Alerts: \\${ProductionAlertSystem.alerts.length}");

    print("📊 EVENT TIMELINE:");
    for (final e in EventTimeline.events) {
      print("\\${e['time']} | \\${e['type']} | \\${e['source']} | Phase: \\${e['phase']}");
    }

    _activeSession = null;
  }

  static String? get session => _activeSession;
}