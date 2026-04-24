import 'dart:convert';
import 'dart:io';

class HistoryTrend {
  const HistoryTrend({
    required this.classification,
    required this.slopePct,
    required this.variance,
    required this.sampleCount,
  });

  final String classification;
  final double slopePct;
  final double variance;
  final int sampleCount;
}

class RunHistoryStore {
  RunHistoryStore(this.path);

  final String path;

  Future<List<Map<String, Object?>>> loadEntries() async {
    final File file = File(path);
    if (!file.existsSync()) {
      return <Map<String, Object?>>[];
    }

    final List<String> lines = await file.readAsLines();
    final List<Map<String, Object?>> entries = <Map<String, Object?>>[];

    for (final String line in lines) {
      final String trimmed = line.trim();
      if (trimmed.isEmpty) continue;

      try {
        final Object? decoded = jsonDecode(trimmed);
        if (decoded is Map<String, Object?>) {
          entries.add(decoded);
        }
      } catch (_) {
        // Ignore malformed history rows instead of breaking the gate.
      }
    }

    return entries;
  }

  Future<void> appendEntry(Map<String, Object?> entry) async {
    final File file = File(path);
    file.parent.createSync(recursive: true);
    await file.writeAsString('${jsonEncode(entry)}\n', mode: FileMode.append);
  }

  Map<String, int> computeRollingMedianBaseline({
    required List<Map<String, Object?>> entries,
    required int window,
    required List<String> checkpoints,
  }) {
    final List<Map<String, Object?>> greens = entries
        .where((Map<String, Object?> entry) => entry['decision'] == 'PASS')
        .toList();

    if (greens.isEmpty) {
      return <String, int>{};
    }

    final int start = greens.length > window ? greens.length - window : 0;
    final List<Map<String, Object?>> recent = greens.sublist(start);

    final Map<String, int> baseline = <String, int>{};

    for (final String checkpoint in checkpoints) {
      final List<int> values = <int>[];
      for (final Map<String, Object?> entry in recent) {
        final Object? checkpointsRaw = entry['checkpoints'];
        if (checkpointsRaw is! Map<String, Object?>) continue;

        final Object? cpRaw = checkpointsRaw[checkpoint];
        if (cpRaw is! Map<String, Object?>) continue;

        final Object? p95Raw = cpRaw['p95Ms'];
        if (p95Raw is num) {
          values.add(p95Raw.round());
        }
      }

      if (values.isNotEmpty) {
        values.sort();
        final int middle = values.length ~/ 2;
        final int median = values.length.isOdd
            ? values[middle]
            : ((values[middle - 1] + values[middle]) / 2).round();
        baseline[checkpoint] = median;
      }
    }

    return baseline;
  }

  HistoryTrend computeTrend({
    required List<Map<String, Object?>> entries,
    required int window,
  }) {
    if (entries.length < 2) {
      return const HistoryTrend(
        classification: 'stable',
        slopePct: 0,
        variance: 0,
        sampleCount: 0,
      );
    }

    final int start = entries.length > window ? entries.length - window : 0;
    final List<Map<String, Object?>> recent = entries.sublist(start);

    final List<double> values = <double>[];
    for (final Map<String, Object?> entry in recent) {
      final Object? score = entry['score'];
      if (score is num) {
        values.add(score.toDouble());
      }
    }

    if (values.length < 2) {
      return const HistoryTrend(
        classification: 'stable',
        slopePct: 0,
        variance: 0,
        sampleCount: 0,
      );
    }

    final int n = values.length;
    double sumX = 0;
    double sumY = 0;
    double sumXX = 0;
    double sumXY = 0;

    for (int i = 0; i < n; i++) {
      final double x = i.toDouble();
      final double y = values[i];
      sumX += x;
      sumY += y;
      sumXX += x * x;
      sumXY += x * y;
    }

    final double denominator = (n * sumXX) - (sumX * sumX);
    final double slope = denominator == 0 ? 0 : ((n * sumXY) - (sumX * sumY)) / denominator;
    final double mean = sumY / n;
    final double slopePct = mean == 0 ? 0 : (slope / mean);

    double variance = 0;
    for (final double value in values) {
      final double diff = value - mean;
      variance += diff * diff;
    }
    variance = variance / n;

    final double absSlopePct = slopePct.abs();
    final String classification;
    if (absSlopePct <= 0.02) {
      classification = 'stable';
    } else if (slopePct > 0.05) {
      classification = 'regressing';
    } else if (slopePct > 0.02) {
      classification = 'degrading';
    } else {
      classification = 'stable';
    }

    return HistoryTrend(
      classification: classification,
      slopePct: slopePct,
      variance: variance,
      sampleCount: n,
    );
  }
}
