import 'package:mixvy/core/telemetry/app_telemetry.dart';
import 'package:mixvy/core/telemetry/feed_experiment_contract.dart';

class FeedExperimentSnapshot {
  const FeedExperimentSnapshot({
    required this.impressions,
    required this.baselineCtr,
    required this.observedCtr,
    required this.averageDwellMs,
    required this.baselineScrollDepth,
    required this.observedScrollDepth,
    required this.baselineParticipationRate,
    required this.observedParticipationRate,
  });

  final int impressions;
  final double baselineCtr;
  final double observedCtr;
  final int averageDwellMs;
  final double baselineScrollDepth;
  final double observedScrollDepth;
  final double baselineParticipationRate;
  final double observedParticipationRate;

  FeedExperimentEvaluation evaluate() {
    return FeedAttentionExperiment.evaluate(
      impressions: impressions,
      baselineCtr: baselineCtr,
      observedCtr: observedCtr,
      averageDwellMs: averageDwellMs,
      baselineScrollDepth: baselineScrollDepth,
      observedScrollDepth: observedScrollDepth,
      baselineParticipationRate: baselineParticipationRate,
      observedParticipationRate: observedParticipationRate,
    );
  }

  Map<String, Object> toMetadata() => <String, Object>{
    'impressions': impressions,
    'baseline_ctr_pct': (baselineCtr * 100).toStringAsFixed(2),
    'observed_ctr_pct': (observedCtr * 100).toStringAsFixed(2),
    'avg_dwell_ms': averageDwellMs,
    'baseline_scroll_pct': (baselineScrollDepth * 100).toStringAsFixed(2),
    'observed_scroll_pct': (observedScrollDepth * 100).toStringAsFixed(2),
    'baseline_participation_pct': (baselineParticipationRate * 100)
        .toStringAsFixed(2),
    'observed_participation_pct': (observedParticipationRate * 100)
        .toStringAsFixed(2),
  };
}

class FeedExperimentEvaluator {
  FeedExperimentEvaluator._();

  static FeedExperimentEvaluation evaluateAndPublish(
    FeedExperimentSnapshot snapshot, {
    String source = 'runtime',
  }) {
    final evaluation = snapshot.evaluate();

    AppTelemetry.logAction(
      domain: 'room',
      action: 'feed_experiment_decision',
      message: evaluation.summary,
      result: evaluation.decision.name,
      metadata: <String, Object?>{
        ...FeedAttentionExperiment.telemetryMetadata(),
        ...snapshot.toMetadata(),
        ...evaluation.toMetadata(),
        'source': source,
        'should_promote': evaluation.shouldPromote,
        'should_rollback': evaluation.shouldRollback,
      },
    );

    return evaluation;
  }
}
