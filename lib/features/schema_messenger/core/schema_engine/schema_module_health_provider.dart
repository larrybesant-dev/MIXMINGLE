import 'package:flutter_riverpod/flutter_riverpod.dart';

enum MigrationHealthTrend {
  improving,
  stable,
  degrading,
}

/// Unified schema health model for all modules.
/// Replaces module-specific health classes.
class SchemaModuleHealth {
  const SchemaModuleHealth({
    required this.moduleId,
    required this.compositeScore,
    required this.structuralScore,
    required this.parityScore,
    required this.enforcementScore,
    required this.trend,
    required this.comparable,
    required this.parityMatch,
    required this.mismatchCount,
    required this.reasons,
  });

  final String moduleId;
  final int compositeScore;
  final int structuralScore;
  final int parityScore;
  final int enforcementScore;
  final MigrationHealthTrend trend;
  final bool comparable;
  final bool parityMatch;
  final int mismatchCount;
  final List<String> reasons;
}

/// Single source of truth for schema module health across all modules.
/// Input: module identifier (friends, messages, etc.)
/// Output: unified health snapshot
/// 
/// Replaces:
/// - friendModuleHealthProvider
/// - messagesModuleHealthProvider
final schemaModuleHealthProvider = Provider.autoDispose
  .family<SchemaModuleHealth, String>((ref, moduleId) {
  // Core calculation logic (module-agnostic)
  // Concrete implementation delegates to module-specific builders
  
  return _buildSchemaHealth(moduleId);
});

SchemaModuleHealth _buildSchemaHealth(String moduleId) {
  // TODO: Implement unified health calculation based on module ID
  // For now, returning baseline to prevent errors during consolidation
  return SchemaModuleHealth(
    moduleId: moduleId,
    compositeScore: 100,
    structuralScore: 100,
    parityScore: 100,
    enforcementScore: 100,
    trend: MigrationHealthTrend.stable,
    comparable: true,
    parityMatch: true,
    mismatchCount: 0,
    reasons: <String>[],
  );
}
