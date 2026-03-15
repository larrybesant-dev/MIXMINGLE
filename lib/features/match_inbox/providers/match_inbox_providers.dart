// lib/features/match_inbox/providers/match_inbox_providers.dart
//
// Riverpod providers for the Match Inbox feature.
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/match_inbox_item.dart';
import '../services/match_inbox_service.dart';
import '../../../shared/providers/auth_providers.dart';

// ── Service provider ──────────────────────────────────────────────────────────

final matchInboxServiceProvider = Provider<MatchInboxService>((ref) {
  return MatchInboxService.instance;
});

// ── Match list provider ───────────────────────────────────────────────────────

/// Real-time stream of the current user's match inbox, newest first.
final matchInboxProvider =
    StreamProvider.autoDispose<List<MatchInboxItem>>((ref) {
  final authState = ref.watch(authStateProvider);
  final user = authState.value;

  if (user == null) return const Stream.empty();

  final service = ref.watch(matchInboxServiceProvider);
  return service.streamMatchesForUser(user.uid);
});

// ── New match count provider ──────────────────────────────────────────────────

/// Number of unseen (isNew == true) matches.
final newMatchCountProvider = Provider.autoDispose<int>((ref) {
  final matchesAsync = ref.watch(matchInboxProvider);
  return matchesAsync.when(
    data: (matches) => matches.where((m) => m.isNew).length,
    loading: () => 0,
    error: (_, __) => 0,
  );
});

// ── Badge state provider ──────────────────────────────────────────────────────

/// True if there is at least one new (unseen) match.
final hasNewMatchesProvider = Provider.autoDispose<bool>((ref) {
  return ref.watch(newMatchCountProvider) > 0;
});

// ── Single match provider ─────────────────────────────────────────────────────

/// Fetch a single match by ID from the current user's inbox.
final singleMatchProvider =
    StreamProvider.autoDispose.family<MatchInboxItem?, String>((ref, matchId) {
  final authState = ref.watch(authStateProvider);
  final user = authState.value;
  if (user == null) return const Stream.empty();

  return MatchInboxService.instance
      .streamMatchesForUser(user.uid)
      .map((list) => list.cast<MatchInboxItem?>().firstWhere(
            (m) => m?.id == matchId,
            orElse: () => null,
          ));
});

// ── Speed-dating source filter ────────────────────────────────────────────────

/// Only speed-dating matches.
final speedDatingMatchInboxProvider =
    Provider.autoDispose<List<MatchInboxItem>>((ref) {
  final matchesAsync = ref.watch(matchInboxProvider);
  return matchesAsync.when(
    data: (matches) =>
        matches.where((m) => m.source == MatchSource.speedDating).toList(),
    loading: () => [],
    error: (_, __) => [],
  );
});

// ── Discovery source filter ───────────────────────────────────────────────────

/// Only discovery-based matches.
final discoveryMatchInboxProvider =
    Provider.autoDispose<List<MatchInboxItem>>((ref) {
  final matchesAsync = ref.watch(matchInboxProvider);
  return matchesAsync.when(
    data: (matches) =>
        matches.where((m) => m.source == MatchSource.discovery).toList(),
    loading: () => [],
    error: (_, __) => [],
  );
});
