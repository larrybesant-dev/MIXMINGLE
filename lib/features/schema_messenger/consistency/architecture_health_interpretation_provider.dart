import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'architecture_health_interpretation_contract.dart';
import '../core/schema_engine/schema_module_health_provider.dart';
import 'cross_module_equivalence_provider.dart';

enum DriftClassification {
  acceptableNoise,
  structuralWarning,
  behavioralDrift,
}

class ArchitectureHealthInterpretationReport {
  const ArchitectureHealthInterpretationReport({
    required this.policyVersion,
    required this.advisoryOnly,
    required this.classification,
    required this.summary,
    required this.reasons,
    required this.friendCompositeScore,
    required this.MessageModelCompositeScore,
    required this.crossModuleEquivalent,
    required this.friendComparable,
    required this.MessageModelComparable,
    required this.friendParityMatch,
    required this.MessageModelParityMatch,
    required this.friendTrend,
    required this.MessageModelTrend,
  });

  final String policyVersion;
  final bool advisoryOnly;
  final DriftClassification classification;
  final String summary;
  final List<String> reasons;

  final int friendCompositeScore;
  final int MessageModelCompositeScore;
  final bool crossModuleEquivalent;
  final bool friendComparable;
  final bool MessageModelComparable;
  final bool friendParityMatch;
  final bool MessageModelParityMatch;
  final String friendTrend;
  final String MessageModelTrend;
}

/// Advisory-only interpretation layer.
///
/// This provider must not be used to drive writes, enforcement, or mutation.
/// It translates existing signal providers into a stable semantic category.
final architectureHealthInterpretationProvider =
    Provider.autoDispose<ArchitectureHealthInterpretationReport>((ref) {
  final friendHealth = ref.watch(schemaModuleHealthProvider('friends'));
  final MessageModelHealth = ref.watch(schemaModuleHealthProvider('MessageModel'));
  final equivalence = ref.watch(crossModuleEquivalenceProvider);

  final reasons = <String>[];

  final isLoadingNoise = !friendHealth.comparable || !MessageModelHealth.comparable;
  if (isLoadingNoise) {
    reasons.add(ArchitectureHealthInterpretationContract.reasonLoadingNoise);
    return ArchitectureHealthInterpretationReport(
      policyVersion: ArchitectureHealthInterpretationContract.version,
      advisoryOnly: true,
      classification: DriftClassification.acceptableNoise,
      summary: ArchitectureHealthInterpretationContract.summaryLoadingNoise,
      reasons: reasons,
      friendCompositeScore: friendHealth.compositeScore,
      MessageModelCompositeScore: MessageModelHealth.compositeScore,
      crossModuleEquivalent: equivalence.isEquivalent,
      friendComparable: friendHealth.comparable,
      MessageModelComparable: MessageModelHealth.comparable,
      friendParityMatch: friendHealth.parityMatch,
      MessageModelParityMatch: MessageModelHealth.parityMatch,
      friendTrend: friendHealth.trend.name,
      MessageModelTrend: MessageModelHealth.trend.name,
    );
  }

  if (!equivalence.isEquivalent) {
    reasons.addAll(
      equivalence.violations
          .map((violation) => 'structural:$violation'),
    );
    return ArchitectureHealthInterpretationReport(
      policyVersion: ArchitectureHealthInterpretationContract.version,
      advisoryOnly: true,
      classification: DriftClassification.structuralWarning,
      summary: ArchitectureHealthInterpretationContract.summaryStructuralWarning,
      reasons: reasons,
      friendCompositeScore: friendHealth.compositeScore,
      MessageModelCompositeScore: MessageModelHealth.compositeScore,
      crossModuleEquivalent: equivalence.isEquivalent,
      friendComparable: friendHealth.comparable,
      MessageModelComparable: MessageModelHealth.comparable,
      friendParityMatch: friendHealth.parityMatch,
      MessageModelParityMatch: MessageModelHealth.parityMatch,
      friendTrend: friendHealth.trend.name,
      MessageModelTrend: MessageModelHealth.trend.name,
    );
  }

  final hasBehaviorDrift = !friendHealth.parityMatch || !MessageModelHealth.parityMatch;
  if (hasBehaviorDrift) {
    reasons.add(
      'behavior:friendParity=${friendHealth.parityMatch};MessageModelParity=${MessageModelHealth.parityMatch}',
    );
    if (friendHealth.trend.name == 'degrading' ||
        MessageModelHealth.trend.name == 'degrading') {
      reasons.add(
        'behavior:degrading_trend '
        'friend=${friendHealth.trend.name} MessageModel=${MessageModelHealth.trend.name}',
      );
    }
    return ArchitectureHealthInterpretationReport(
      policyVersion: ArchitectureHealthInterpretationContract.version,
      advisoryOnly: true,
      classification: DriftClassification.behavioralDrift,
      summary: ArchitectureHealthInterpretationContract.summaryBehavioralDrift,
      reasons: reasons,
      friendCompositeScore: friendHealth.compositeScore,
      MessageModelCompositeScore: MessageModelHealth.compositeScore,
      crossModuleEquivalent: equivalence.isEquivalent,
      friendComparable: friendHealth.comparable,
      MessageModelComparable: MessageModelHealth.comparable,
      friendParityMatch: friendHealth.parityMatch,
      MessageModelParityMatch: MessageModelHealth.parityMatch,
      friendTrend: friendHealth.trend.name,
      MessageModelTrend: MessageModelHealth.trend.name,
    );
  }

  reasons.add(ArchitectureHealthInterpretationContract.reasonAligned);
  return ArchitectureHealthInterpretationReport(
    policyVersion: ArchitectureHealthInterpretationContract.version,
    advisoryOnly: true,
    classification: DriftClassification.acceptableNoise,
    summary: ArchitectureHealthInterpretationContract.summaryAligned,
    reasons: reasons,
    friendCompositeScore: friendHealth.compositeScore,
    MessageModelCompositeScore: MessageModelHealth.compositeScore,
    crossModuleEquivalent: equivalence.isEquivalent,
    friendComparable: friendHealth.comparable,
    MessageModelComparable: MessageModelHealth.comparable,
    friendParityMatch: friendHealth.parityMatch,
    MessageModelParityMatch: MessageModelHealth.parityMatch,
    friendTrend: friendHealth.trend.name,
    MessageModelTrend: MessageModelHealth.trend.name,
  );
});
