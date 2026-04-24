import 'startup_pipeline_models.dart';

class StartupBaselineEngine {
  const StartupBaselineEngine();

  Map<StartupCheckpoint, int> computeFromHistory({
    required List<Map<String, Object?>> entries,
    required int window,
  }) {
    final List<Map<String, Object?>> greenEntries = entries
        .where((Map<String, Object?> entry) => entry['decision'] == 'PASS')
        .toList();

    if (greenEntries.isEmpty) {
      return <StartupCheckpoint, int>{};
    }

    final int start = greenEntries.length > window
        ? greenEntries.length - window
        : 0;
    final List<Map<String, Object?>> recent = greenEntries.sublist(start);

    final Map<StartupCheckpoint, int> baseline = <StartupCheckpoint, int>{};

    for (final StartupCheckpoint checkpoint in gateCheckpoints) {
      final List<int> values = <int>[];
      for (final Map<String, Object?> entry in recent) {
        final Object? metricsRaw = entry['metrics'];
        if (metricsRaw is! Map<String, Object?>) continue;
        final Object? metric = metricsRaw[checkpoint.name];
        if (metric is num) {
          values.add(metric.round());
        }
      }

      if (values.isNotEmpty) {
        values.sort();
        final int mid = values.length ~/ 2;
        final int median = values.length.isOdd
            ? values[mid]
            : ((values[mid - 1] + values[mid]) / 2).round();
        baseline[checkpoint] = median;
      }
    }

    return baseline;
  }
}
