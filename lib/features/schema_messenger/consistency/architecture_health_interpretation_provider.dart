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
    required this.messagesCompositeScore,
    required this.crossModuleEquivalent,
    required this.friendComparable,
    required this.messagesComparable,
    required this.friendParityMatch,
    required this.messagesParityMatch,
    required this.friendTrend,
    required this.messagesTrend,
  });

  final String policyVersion;
  final bool advisoryOnly;
  final DriftClassification classification;
  final String summary;
  final List<String> reasons;

  final int friendCompositeScore;
  final int messagesCompositeScore;
  final bool crossModuleEquivalent;
  final bool friendComparable;
  final bool messagesComparable;
  final bool friendParityMatch;
  final bool messagesParityMatch;
  final String friendTrend;
  final String messagesTrend;
}

/// Advisory-only interpretation layer.
///
/// This provider must not be used to drive writes, enforcement, or mutation.
/// It translates existing signal providers into a stable semantic category.
final architectureHealthInterpretationProvider =
    Provider.autoDispose<ArchitectureHealthInterpretationReport>((ref) {
  final friendHealth = ref.watch(schemaModuleHealthProvider('friends'));
  final messagesHealth = ref.watch(schemaModuleHealthProvider('messages'));
  final equivalence = ref.watch(crossModuleEquivalenceProvider);

  final reasons = <String>[];

  final isLoadingNoise = !friendHealth.comparable || !messagesHealth.comparable;
  if (isLoadingNoise) {
    reasons.add(ArchitectureHealthInterpretationContract.reasonLoadingNoise);
    return ArchitectureHealthInterpretationReport(
      policyVersion: ArchitectureHealthInterpretationContract.version,
      advisoryOnly: true,
      classification: DriftClassification.acceptableNoise,
      summary: ArchitectureHealthInterpretationContract.summaryLoadingNoise,
      reasons: reasons,
      friendCompositeScore: friendHealth.compositeScore,
      messagesCompositeScore: messagesHealth.compositeScore,
      crossModuleEquivalent: equivalence.isEquivalent,
      friendComparable: friendHealth.comparable,
      messagesComparable: messagesHealth.comparable,
      friendParityMatch: friendHealth.parityMatch,
      messagesParityMatch: messagesHealth.parityMatch,
      friendTrend: friendHealth.trend.name,
      messagesTrend: messagesHealth.trend.name,
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
      messagesCompositeScore: messagesHealth.compositeScore,
      crossModuleEquivalent: equivalence.isEquivalent,
      friendComparable: friendHealth.comparable,
      messagesComparable: messagesHealth.comparable,
      friendParityMatch: friendHealth.parityMatch,
      messagesParityMatch: messagesHealth.parityMatch,
      friendTrend: friendHealth.trend.name,
      messagesTrend: messagesHealth.trend.name,
    );
  }

  final hasBehaviorDrift = !friendHealth.parityMatch || !messagesHealth.parityMatch;
  if (hasBehaviorDrift) {
    reasons.add(
      'behavior:friendParity=${friendHealth.parityMatch};messagesParity=${messagesHealth.parityMatch}',
    );
    if (friendHealth.trend.name == 'degrading' ||
        messagesHealth.trend.name == 'degrading') {
      reasons.add(
        'behavior:degrading_trend '
        'friend=${friendHealth.trend.name} messages=${messagesHealth.trend.name}',
      );
    }
    return ArchitectureHealthInterpretationReport(
      policyVersion: ArchitectureHealthInterpretationContract.version,
      advisoryOnly: true,
      classification: DriftClassification.behavioralDrift,
      summary: ArchitectureHealthInterpretationContract.summaryBehavioralDrift,
      reasons: reasons,
      friendCompositeScore: friendHealth.compositeScore,
      messagesCompositeScore: messagesHealth.compositeScore,
      crossModuleEquivalent: equivalence.isEquivalent,
      friendComparable: friendHealth.comparable,
      messagesComparable: messagesHealth.comparable,
      friendParityMatch: friendHealth.parityMatch,
      messagesParityMatch: messagesHealth.parityMatch,
      friendTrend: friendHealth.trend.name,
      messagesTrend: messagesHealth.trend.name,
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
    messagesCompositeScore: messagesHealth.compositeScore,
    crossModuleEquivalent: equivalence.isEquivalent,
    friendComparable: friendHealth.comparable,
    messagesComparable: messagesHealth.comparable,
    friendParityMatch: friendHealth.parityMatch,
    messagesParityMatch: messagesHealth.parityMatch,
    friendTrend: friendHealth.trend.name,
    messagesTrend: messagesHealth.trend.name,
  );
});
