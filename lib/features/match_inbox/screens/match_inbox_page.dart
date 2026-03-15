// lib/features/match_inbox/screens/match_inbox_page.dart
//
// Match Inbox — the place where all mutual matches live.
// Layout: responsive grid (≥600px) or single-column list (<600px).
// Actions: tap match → open chat, tap avatar → view profile.
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/design_system/design_constants.dart';
import '../../../shared/widgets/club_background.dart';
import '../providers/match_inbox_providers.dart';
import '../models/match_inbox_item.dart';
import '../services/match_inbox_service.dart';
import '../widgets/match_tile.dart';
import '../../../core/analytics/analytics_service.dart';

class MatchInboxPage extends ConsumerStatefulWidget {
  const MatchInboxPage({super.key});

  @override
  ConsumerState<MatchInboxPage> createState() => _MatchInboxPageState();
}

class _MatchInboxPageState extends ConsumerState<MatchInboxPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 3, vsync: this);
    AnalyticsService.instance.logScreenView(screenName: 'screen_match_inbox');
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  // ── Navigation helpers ────────────────────────────────────────────────────

  void _openChat(BuildContext context, MatchInboxItem match,
      [String? name]) {
    AnalyticsService.instance.logMatchTileOpened(matchId: match.id);
    AnalyticsService.instance.logMatchMessageButtonTapped(matchId: match.id);
    // Mark as seen
    MatchInboxService.instance.markMatchAsSeen(match.id);
    Navigator.pushNamed(
      context,
      '/chat',
      arguments: {
        'otherUserId': match.matchedUserId,
        'otherUserName':
            name ?? (match.metadata['matchedUserName'] as String?) ?? 'Match',
      },
    );
  }

  void _openProfile(BuildContext context, MatchInboxItem match) {
    AnalyticsService.instance.logMatchTileOpened(matchId: match.id);
    Navigator.pushNamed(
      context,
      '/profile/user',
      arguments: {'userId': match.matchedUserId},
    );
  }

  void _markAllSeen() {
    MatchInboxService.instance.markAllMatchesSeen();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('All matches marked as seen'),
        backgroundColor: DesignColors.surfaceLight,
      ),
    );
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final matchesAsync = ref.watch(matchInboxProvider);
    final newCount = ref.watch(newMatchCountProvider);

    return ClubBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: _buildAppBar(newCount),
        body: matchesAsync.when(
          loading: () => const Center(
            child: CircularProgressIndicator(color: DesignColors.accent),
          ),
          error: (e, _) => _buildError(e),
          data: (matches) => _buildContent(context, matches),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(int newCount) {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      title: Row(
        children: [
          const Text(
            'MATCHES',
            style: TextStyle(
              color: DesignColors.white,
              fontSize: 18,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.5,
            ),
          ),
          if (newCount > 0) ...[
            const SizedBox(width: 8),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFFF4D8B), DesignColors.tertiary],
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '$newCount new',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ],
      ),
      actions: [
        if (newCount > 0)
          TextButton(
            onPressed: _markAllSeen,
            child: const Text(
              'Mark all seen',
              style: TextStyle(color: DesignColors.accent, fontSize: 12),
            ),
          ),
      ],
      bottom: TabBar(
        controller: _tabs,
        indicatorColor: DesignColors.accent,
        indicatorWeight: 2,
        labelColor: DesignColors.accent,
        unselectedLabelColor: DesignColors.textGray,
        labelStyle:
            const TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
        tabs: const [
          Tab(text: 'ALL'),
          Tab(text: 'NEW'),
          Tab(text: 'SPEED DATE'),
        ],
      ),
    );
  }

  Widget _buildContent(BuildContext context, List<MatchInboxItem> all) {
    final newMatches = all.where((m) => m.isNew).toList();
    final speedMatches =
        all.where((m) => m.source == MatchSource.speedDating).toList();

    return TabBarView(
      controller: _tabs,
      children: [
        _MatchGrid(
          matches: all,
          onTap: (m) => _openChat(context, m),
          onProfileTap: (m) => _openProfile(context, m),
          emptyLabel: 'No matches yet.\nGet out there and mingle! 🎉',
        ),
        _MatchGrid(
          matches: newMatches,
          onTap: (m) => _openChat(context, m),
          onProfileTap: (m) => _openProfile(context, m),
          emptyLabel: 'No new matches right now.\nCheck back soon!',
        ),
        _MatchGrid(
          matches: speedMatches,
          onTap: (m) => _openChat(context, m),
          onProfileTap: (m) => _openProfile(context, m),
          emptyLabel: 'No speed dating matches yet.\nJoin a speed date session!',
        ),
      ],
    );
  }

  Widget _buildError(Object e) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline,
              color: DesignColors.error, size: 48),
          const SizedBox(height: 12),
          Text(
            'Failed to load matches\n$e',
            style: const TextStyle(color: DesignColors.textGray),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// ── Responsive grid ───────────────────────────────────────────────────────────

class _MatchGrid extends StatelessWidget {
  final List<MatchInboxItem> matches;
  final void Function(MatchInboxItem) onTap;
  final void Function(MatchInboxItem) onProfileTap;
  final String emptyLabel;

  const _MatchGrid({
    required this.matches,
    required this.onTap,
    required this.onProfileTap,
    required this.emptyLabel,
  });

  @override
  Widget build(BuildContext context) {
    if (matches.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: DesignColors.accent.withValues(alpha: 0.08),
                ),
                child: const Icon(Icons.favorite_border,
                    color: DesignColors.accent, size: 36),
              ),
              const SizedBox(height: 20),
              Text(
                emptyLabel,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: DesignColors.textGray,
                  fontSize: 15,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final screenWidth = MediaQuery.of(context).size.width;
    final crossAxisCount = screenWidth >= 600 ? 3 : 2;

    return GridView.builder(
      physics: const BouncingScrollPhysics(
          parent: AlwaysScrollableScrollPhysics()),
      padding: const EdgeInsets.all(16),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 0.78,
      ),
      itemCount: matches.length,
      itemBuilder: (context, i) {
        final match = matches[i];
        return MatchTile(
          match: match,
          onTap: () => onTap(match),
          onProfileTap: () => onProfileTap(match),
        );
      },
    );
  }
}
