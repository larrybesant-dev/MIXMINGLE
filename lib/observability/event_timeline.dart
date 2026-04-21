import 'simulation_phase.dart';

class EventTimeline {
  static final List<Map<String, dynamic>> _events = [];

  static void record(String type, String source) {
    _events.add({
      "type": type,
      "source": source,
      "phase": SimulationPhase.current,
      "time": DateTime.now().millisecondsSinceEpoch,
    });
  }

  static List<Map<String, dynamic>> get events => List.unmodifiable(_events);

  static void clear() => _events.clear();
}