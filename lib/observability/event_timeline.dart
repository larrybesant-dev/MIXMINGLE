import 'package:flutter/foundation.dart';
import 'runtime_telemetry.dart';

class EventTimeline {
  final List<Map<String, dynamic>> _events = [];

  void record(String type, String source, SimulationContext ctx) {
    _events.add({
      "type": type,
      "source": source,
      "phase": ctx.phase,
      "time": DateTime.now().millisecondsSinceEpoch,
    });
    debugPrint("[${ctx.phase}] Event recorded: type=$type, source=$source");
  }

  List<Map<String, dynamic>> get events => List.unmodifiable(_events);

  void clear() => _events.clear();
}