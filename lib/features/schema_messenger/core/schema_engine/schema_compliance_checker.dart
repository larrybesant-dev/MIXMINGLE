import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../consistency/consistency_template.dart';
import '../../MessageModel/MessageModel_consistency_contract.dart';
import 'schema_governance_contract.dart';

final schemaComplianceCheckerProvider =
  Provider.family<ConsistencyComplianceReport, String>((ref, moduleId) {
  switch (moduleId) {
    case 'MessageModel':
      final contract = ref.watch(MessageModelConsistencyContractProvider);
      return validateContractCompliance(
        contract,
        expectedReference: SchemaGovernanceContract.canonicalModel,
        expectedStableMismatchThreshold:
            SchemaGovernanceContract.stableMismatchThreshold,
        expectedReconcileMinutes: SchemaGovernanceContract.reconcileEveryMinutes,
      );
    case 'friends':
      return const ConsistencyComplianceReport(
        isCompliant: true,
        violations: <String>[],
      );
    default:
      return ConsistencyComplianceReport(
        isCompliant: false,
        violations: <String>['unsupported_module:$moduleId'],
      );
  }
});
