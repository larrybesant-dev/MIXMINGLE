import 'startup_pipeline_models.dart';

class StartupPolicyEngine {
  const StartupPolicyEngine({required this.sla});

  final Map<StartupCheckpoint, int> sla;

  List<String> evaluateFailures({
    required List<String> parseFailures,
    required Map<StartupCheckpoint, CheckpointStats> stats,
    required Map<StartupCheckpoint, int> baseline,
    required TrendAnalysis trend,
  }) {
    final List<String> failures = <String>[...parseFailures];

    final CheckpointStats? firstFrame =
        stats[StartupCheckpoint.firstFrameRendered];
    final int? firstFrameLimit = sla[StartupCheckpoint.firstFrameRendered];
    if (firstFrame != null &&
        firstFrameLimit != null &&
        firstFrame.worst > firstFrameLimit) {
      failures.add(
        'firstFrameRendered: ${firstFrame.worst}ms (limit ${firstFrameLimit}ms)',
      );
    }

    for (final StartupCheckpoint checkpoint in gateCheckpoints) {
      final CheckpointStats? cpStats = stats[checkpoint];
      final int? limit = sla[checkpoint];
      if (cpStats == null || limit == null) continue;

      final int p95Ceiling = (limit * 1.2).ceil();
      if (cpStats.p95 > p95Ceiling) {
        failures.add(
          'p95 regression ${checkpoint.name}: ${cpStats.p95}ms (20% ceiling ${p95Ceiling}ms)',
        );
      }

      final int? baselineP95 = baseline[checkpoint];
      if (baselineP95 != null) {
        final int baselineCeiling = (baselineP95 * 1.2).ceil();
        if (cpStats.p95 > baselineCeiling) {
          failures.add(
            'baseline regression ${checkpoint.name}: ${cpStats.p95}ms (baseline p95 ${baselineP95}ms, +20% ceiling ${baselineCeiling}ms)',
          );
        }
      }
    }

    if (trend.status == TrendStatus.regressing) {
      failures.add(
        'trend regression detected: slope ${(trend.slopePct * 100).toStringAsFixed(2)}% over ${trend.sampleCount} runs',
      );
    }

    return failures;
  }
}
