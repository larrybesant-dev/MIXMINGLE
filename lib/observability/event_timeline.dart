import 'simulation_phase.dart';

class EventTimeline {
  static final List<Map<String, dynamic>> _events = [];

  static void record(String type, String source) {
    final currentPhase = SimulationPhase.current;
    _events.add({
      "type": type,
      "source": source,
      "phase": currentPhase,
      "time": DateTime.now().millisecondsSinceEpoch,
    });
    print("Event recorded: type=$type, source=$source, phase=$currentPhase");
  }

  static List<Map<String, dynamic>> get events => List.unmodifiable(_events);

  static void clear() => _events.clear();
}