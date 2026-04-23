import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../consistency/consistency_template.dart';
import '../core/schema_engine/schema_governance_contract.dart';
import '../../messaging/providers/messaging_provider.dart';
import '../../../presentation/providers/user_provider.dart';

/// Module 2 blueprint: strict contract instantiation only.
/// No custom gating semantics allowed.
class messagesnapshot extends ConsistencySnapshot {
  messagesnapshot({
    required this.legacyConversationIds,
    required this.schemaConversationIds,
    required this.legacyUnreadByConversation,
    required this.schemaUnreadByConversation,
    required this.legacyReady,
    required this.schemaReady,
  });

  final List<String> legacyConversationIds;
  final List<String> schemaConversationIds;
  final Map<String, int> legacyUnreadByConversation;
  final Map<String, int> schemaUnreadByConversation;
  final bool legacyReady;
  final bool schemaReady;
}

class messageParityResult implements ConsistencyParityResult {
  const messageParityResult({
    required this.isComparable,
    required this.isMatch,
    required this.signature,
    required this.missingInSchema,
    required this.missingInLegacy,
    required this.unreadMismatches,
  });

  @override
  final bool isComparable;

  @override
  final bool isMatch;

  @override
  final String signature;

  final List<String> missingInSchema;
  final List<String> missingInLegacy;
  final List<String> unreadMismatches;
}

class messageConsistencyContract
    extends ConsistencyModuleContract<messagesnapshot, messageParityResult> {
  const messageConsistencyContract();

  @override
  String get moduleId => 'message';

  @override
    String get canonicalReference => SchemaGovernanceContract.canonicalModel;

  @override
  int get stableMismatchThreshold =>
      SchemaGovernanceContract.stableMismatchThreshold;

  @override
  int get reconcileEveryMinutes =>
      SchemaGovernanceContract.reconcileEveryMinutes;

  @override
  messagesnapshot buildSnapshot(WidgetRef ref, {required bool readOnly}) {
    final userId = ref.watch(userProvider)?.id;
    if (userId == null || userId.isEmpty) {
      return messagesnapshot(
        legacyConversationIds: <String>[],
        schemaConversationIds: <String>[],
        legacyUnreadByConversation: <String, int>{},
        schemaUnreadByConversation: <String, int>{},
        legacyReady: false,
        schemaReady: false,
      );
    }

    final legacyAsync = ref.watch(conversationsStreamProvider(userId));

    // Module 2 strict instantiation rule: schema snapshot starts from the same
    // canonical normalized stream and can evolve only by mapping, not by
    // introducing an alternate query pipeline.
    final schemaAsync = ref.watch(conversationsStreamProvider(userId));

    final legacy = legacyAsync.valueOrNull ?? const [];
    final schema = schemaAsync.valueOrNull ?? const [];

    return messagesnapshot(
      legacyConversationIds: legacy.map((c) => c.id).toList(growable: false),
      schemaConversationIds: schema.map((c) => c.id).toList(growable: false),
      legacyUnreadByConversation: {
        for (final c in legacy) c.id: c.hasUnreadmessage(userId) ? 1 : 0,
      },
      schemaUnreadByConversation: {
        for (final c in schema) c.id: c.hasUnreadmessage(userId) ? 1 : 0,
      },
      legacyReady: legacyAsync.hasValue,
      schemaReady: schemaAsync.hasValue,
    );
  }

  @override
  messageParityResult evaluate(messagesnapshot snapshot) {
    if (!snapshot.legacyReady || !snapshot.schemaReady) {
      return const messageParityResult(
        isComparable: false,
        isMatch: true,
        signature: 'loading',
        missingInSchema: <String>[],
        missingInLegacy: <String>[],
        unreadMismatches: <String>[],
      );
    }

    final legacyIds = snapshot.legacyConversationIds.toSet();
    final schemaIds = snapshot.schemaConversationIds.toSet();
    final missingInSchema = snapshot.legacyConversationIds
        .where((id) => !schemaIds.contains(id))
        .toList(growable: false);
    final missingInLegacy = snapshot.schemaConversationIds
        .where((id) => !legacyIds.contains(id))
        .toList(growable: false);

    final unreadMismatches = <String>[];
    for (final id in snapshot.legacyConversationIds) {
      if (!schemaIds.contains(id)) continue;
      final legacyUnread = snapshot.legacyUnreadByConversation[id] ?? 0;
      final schemaUnread = snapshot.schemaUnreadByConversation[id] ?? 0;
      if (legacyUnread != schemaUnread) {
        unreadMismatches.add(id);
      }
    }

    final signature = [
      'legacy:${snapshot.legacyConversationIds.join(',')}',
      'schema:${snapshot.schemaConversationIds.join(',')}',
      'misS:${missingInSchema.join(',')}',
      'misL:${missingInLegacy.join(',')}',
      'unread:${unreadMismatches.join(',')}',
    ].join('|');

    final isMatch =
        missingInSchema.isEmpty && missingInLegacy.isEmpty && unreadMismatches.isEmpty;

    return messageParityResult(
      isComparable: true,
      isMatch: isMatch,
      signature: signature,
      missingInSchema: missingInSchema,
      missingInLegacy: missingInLegacy,
      unreadMismatches: unreadMismatches,
    );
  }
}

final messageConsistencyContractProvider =
    Provider<messageConsistencyContract>((ref) {
  return const messageConsistencyContract();
});
