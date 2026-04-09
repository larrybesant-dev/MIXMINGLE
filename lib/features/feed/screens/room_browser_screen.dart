import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme.dart';
import '../../../models/room_model.dart';
import '../widgets/live_room_card.dart';
import '../../../widgets/mixvy_drawer.dart';
import '../../../widgets/brand_ui_kit.dart';

class RoomBrowserScreen extends ConsumerStatefulWidget {
  const RoomBrowserScreen({super.key, this.initialCategory});
  final String? initialCategory;

  @override
  ConsumerState<RoomBrowserScreen> createState() => _RoomBrowserScreenState();
}

class _RoomBrowserScreenState extends ConsumerState<RoomBrowserScreen> {
  static const List<({String label, String emoji, String? value})> _categories = [
    (label: 'All Rooms', emoji: '✨', value: null),
    (label: 'Music',     emoji: '🎵', value: 'music'),
    (label: 'Talk',      emoji: '💬', value: 'talk'),
    (label: 'Gaming',    emoji: '🎮', value: 'gaming'),
    (label: 'Dance',     emoji: '💃', value: 'dance'),
    (label: 'Dating',    emoji: '💕', value: 'dating'),
    (label: 'Study',     emoji: '📚', value: 'study'),
    (label: 'Art',       emoji: '🎨', value: 'art'),
  ];

  String? _selectedCategory;
  bool _showGrid = false;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(
        () => setState(() => _searchQuery = _searchController.text.trim().toLowerCase()));
    if (widget.initialCategory != null) {
      _selectedCategory = widget.initialCategory;
      _showGrid = true;
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: VelvetNoir.surface,
      drawer: const MixVyDrawer(),
      body: _showGrid
          ? _RoomListView(
              category: _selectedCategory,
              categoryLabel: _categoryLabel(_selectedCategory),
              searchQuery: _searchQuery,
              searchController: _searchController,
              onBack: () => setState(() {
                _showGrid = false;
                _selectedCategory = null;
                _searchController.clear();
              }),
            )
          : _CategoryDirectory(
              categories: _categories,
              onCategorySelected: (cat) => setState(() {
                _selectedCategory = cat;
                _showGrid = true;
              }),
            ),
    );
  }

  String _categoryLabel(String? value) {
    if (value == null) return 'All Rooms';
    final cat = _categories.where((c) => c.value == value).firstOrNull;
    return cat != null ? '${cat.emoji}  ${cat.label}' : 'Rooms';
  }
}

// ── Category directory ────────────────────────────────────────────────────────

class _CategoryDirectory extends StatelessWidget {
  const _CategoryDirectory({required this.categories, required this.onCategorySelected});

  final List<({String label, String emoji, String? value})> categories;
  final void Function(String? value) onCategorySelected;

  // Per-category gradient pairs (dark → accent)
  static const Map<String?, List<Color>> _gradients = {
    null:      [Color(0xFF1A1210), Color(0xFF3D2B10), Color(0xFFD4A853)],
    'music':   [Color(0xFF140D14), Color(0xFF3A0F28), Color(0xFFC45E7A)],
    'talk':    [Color(0xFF110E0A), Color(0xFF332208), Color(0xFFFFB74D)],
    'gaming':  [Color(0xFF0B1410), Color(0xFF0D3020), Color(0xFF4CAF50)],
    'dance':   [Color(0xFF140A14), Color(0xFF350A30), Color(0xFFFF6EB4)],
    'dating':  [Color(0xFF140A0D), Color(0xFF3D0A1A), Color(0xFFFF6E84)],
    'study':   [Color(0xFF0A0F18), Color(0xFF0D2040), Color(0xFF64B5F6)],
    'art':     [Color(0xFF14100A), Color(0xFF3A2808), Color(0xFFFFCA28)],
  };

  static const Map<String?, Color> _accents = {
    null:      Color(0xFFD4A853),
    'music':   Color(0xFFC45E7A),
    'talk':    Color(0xFFFFB74D),
    'gaming':  Color(0xFF4CAF50),
    'dance':   Color(0xFFFF6EB4),
    'dating':  Color(0xFFFF6E84),
    'study':   Color(0xFF64B5F6),
    'art':     Color(0xFFFFCA28),
  };

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        // ── Header ──
        SliverToBoxAdapter(
          child: Container(
            padding: const EdgeInsets.fromLTRB(20, 60, 20, 24),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF1B1216), VelvetNoir.surface],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const MixvyAppBarLogo(fontSize: 18),
                const SizedBox(height: 10),
                Text(
                  'Find Your Vibe',
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 30,
                    fontWeight: FontWeight.w700,
                    color: VelvetNoir.onSurface,
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Pick a room, join the moment.',
                  style: GoogleFonts.raleway(
                    fontSize: 13,
                    color: VelvetNoir.onSurfaceVariant,
                    letterSpacing: 0.2,
                  ),
                ),
              ],
            ),
          ),
        ),

        // ── Go Live CTA ──
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: _GoLiveBanner(),
          ),
        ),

        // ── Section label ──
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
            child: Text(
              'BROWSE BY VIBE',
              style: GoogleFonts.raleway(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: VelvetNoir.primary.withValues(alpha: 0.7),
                letterSpacing: 2.0,
              ),
            ),
          ),
        ),

        // ── Category grid ──
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
          sliver: SliverLayoutBuilder(builder: (ctx, constraints) {
            final w = constraints.crossAxisExtent;
            final cols = w > 900 ? 4 : w > 600 ? 3 : 2;
            return SliverGrid(
              delegate: SliverChildBuilderDelegate(
                (_, i) {
                  final cat = categories[i];
                  final grads = _gradients[cat.value] ?? _gradients[null]!;
                  final accent = _accents[cat.value] ?? VelvetNoir.primary;
                  return _CategoryCard(
                    label: cat.label,
                    emoji: cat.emoji,
                    gradientColors: grads,
                    accent: accent,
                    onTap: () => onCategorySelected(cat.value),
                  );
                },
                childCount: categories.length,
              ),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: cols,
                childAspectRatio: 0.9,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
            );
          }),
        ),
      ],
    );
  }
}

// ── Go Live banner ────────────────────────────────────────────────────────────

class _GoLiveBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.go('/create-room'),
      child: Container(
        height: 88,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF2A1800), Color(0xFF6B3D00), Color(0xFFD4A853)],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFD4A853).withValues(alpha: 0.22),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Decorative circles
            Positioned(
              right: -10,
              top: -18,
              child: Container(
                width: 110,
                height: 110,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.04),
                ),
              ),
            ),
            Positioned(
              right: 40,
              bottom: -24,
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.03),
                ),
              ),
            ),
            // Content
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 22),
              child: Row(
                children: [
                  // Mic icon with glow
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: VelvetNoir.primary.withValues(alpha: 0.4),
                          blurRadius: 12,
                        ),
                      ],
                    ),
                    child: const Icon(Icons.mic_rounded, color: Colors.white, size: 24),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Start a Room',
                          style: GoogleFonts.playfairDisplay(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Host your own live conversation',
                          style: GoogleFonts.raleway(
                            fontSize: 11,
                            color: Colors.white.withValues(alpha: 0.75),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
                    ),
                    child: Text(
                      'GO LIVE',
                      style: GoogleFonts.raleway(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: 1.0,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Category card ─────────────────────────────────────────────────────────────

class _CategoryCard extends StatelessWidget {
  const _CategoryCard({
    required this.label,
    required this.emoji,
    required this.gradientColors,
    required this.accent,
    required this.onTap,
  });

  final String label;
  final String emoji;
  final List<Color> gradientColors;
  final Color accent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: gradientColors,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: accent.withValues(alpha: 0.22), width: 1),
          boxShadow: [
            BoxShadow(
              color: accent.withValues(alpha: 0.10),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            // Soft glow circle behind emoji
            Positioned(
              top: -20,
              right: -20,
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: accent.withValues(alpha: 0.06),
                ),
              ),
            ),
            // Main content
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 18, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Emoji in bubble
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: accent.withValues(alpha: 0.25)),
                    ),
                    child: Center(
                      child: Text(emoji, style: const TextStyle(fontSize: 24)),
                    ),
                  ),
                  const Spacer(),
                  // Label
                  Text(
                    label,
                    style: GoogleFonts.raleway(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: VelvetNoir.onSurface,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  // Accent underline dot
                  Container(
                    width: 20,
                    height: 2,
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: 0.7),
                      borderRadius: BorderRadius.circular(1),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Room list for a category ─────────────────────────────────────────────────

final _roomsByCategoryProvider = StreamProvider.autoDispose
    .family<List<RoomModel>, String?>((ref, category) {
  // ORDER BY createdAt — stable; never changes after room creation.
  // Using participantCount/memberCount as the Firestore sort key would cause
  // rooms to re-shuffle on every join/leave event. Instead we do a
  // member-count sort on the client side with createdAt as a stable tiebreaker
  // so rooms only move when their member counts actually differ.
  Query<Map<String, dynamic>> query = FirebaseFirestore.instance
      .collection('rooms')
      .where('isLive', isEqualTo: true)
      .orderBy('createdAt', descending: true)
      .limit(50);

  if (category != null) {
    query = query.where('category', isEqualTo: category);
  }

  return query.snapshots().map((snap) {
    final rooms = snap.docs
        .map((doc) => RoomModel.fromJson(doc.data(), doc.id))
        .toList();
    // Stable sort: most members first; within the same count keep the
    // Firestore createdAt order (newer rooms first) so no position changes
    // unless a room's memberCount actually passes another room's.
    rooms.sort((a, b) {
      final byCount = b.memberCount.compareTo(a.memberCount);
      if (byCount != 0) return byCount;
      // Tiebreaker: newer room first (matches server orderBy)
      final aTs = a.createdAt?.seconds ?? 0;
      final bTs = b.createdAt?.seconds ?? 0;
      return bTs.compareTo(aTs);
    });
    return rooms;
  });
});

class _RoomListView extends ConsumerWidget {
  const _RoomListView({
    required this.category,
    required this.categoryLabel,
    required this.searchQuery,
    required this.searchController,
    required this.onBack,
  });

  final String? category;
  final String categoryLabel;
  final String searchQuery;
  final TextEditingController searchController;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final roomsAsync = ref.watch(_roomsByCategoryProvider(category));
    return CustomScrollView(
      slivers: [
        // ── Back header ──
        SliverToBoxAdapter(
          child: Container(
            padding: const EdgeInsets.fromLTRB(8, 52, 16, 16),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF1B1216), VelvetNoir.surface],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new_rounded,
                      color: VelvetNoir.onSurface, size: 20),
                  onPressed: onBack,
                ),
                const SizedBox(width: 4),
                Text(
                  categoryLabel,
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: VelvetNoir.onSurface,
                  ),
                ),
              ],
            ),
          ),
        ),
        // ── Search bar ──
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: TextField(
              controller: searchController,
              style: GoogleFonts.raleway(
                fontSize: 14,
                color: VelvetNoir.onSurface,
              ),
              decoration: InputDecoration(
                hintText: 'Search rooms...',
                hintStyle: GoogleFonts.raleway(
                    fontSize: 14, color: VelvetNoir.onSurfaceVariant),
                prefixIcon: const Icon(Icons.search_rounded,
                    color: VelvetNoir.onSurfaceVariant, size: 20),
                suffixIcon: searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.close_rounded,
                            color: VelvetNoir.onSurfaceVariant, size: 18),
                        onPressed: () => searchController.clear(),
                      )
                    : null,
                filled: true,
                fillColor: VelvetNoir.surfaceContainer,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide:
                      BorderSide(color: VelvetNoir.outlineVariant.withValues(alpha: 0.4)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide:
                      BorderSide(color: VelvetNoir.outlineVariant.withValues(alpha: 0.4)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: VelvetNoir.primary),
                ),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
          ),
        ),
        // ── Room grid ──
        roomsAsync.when(
          data: (allRooms) {
            final rooms = searchQuery.isEmpty
                ? allRooms
                : allRooms
                    .where((r) =>
                        r.name.toLowerCase().contains(searchQuery) ||
                        (r.description?.toLowerCase().contains(searchQuery) ??
                            false))
                    .toList();
            if (rooms.isEmpty) {
              return SliverFillRemaining(
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('🎙️',
                          style: TextStyle(fontSize: 48)),
                      const SizedBox(height: 12),
                      Text(
                        'No live rooms right now',
                        style: GoogleFonts.playfairDisplay(
                          fontSize: 18,
                          color: VelvetNoir.onSurface,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Be the first to start one!',
                        style: GoogleFonts.raleway(
                          fontSize: 13,
                          color: VelvetNoir.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 20),
                      TextButton.icon(
                        onPressed: () => context.go('/create-room'),
                        icon: const Icon(Icons.mic_rounded,
                            color: VelvetNoir.primary),
                        label: Text(
                          'Start a Room',
                          style: GoogleFonts.raleway(
                              color: VelvetNoir.primary,
                              fontWeight: FontWeight.w700),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }
            return SliverLayoutBuilder(builder: (ctx, constraints) {
              final cols = constraints.crossAxisExtent > 900
                  ? 4
                  : constraints.crossAxisExtent > 600
                      ? 3
                      : 2;
              return SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                sliver: SliverGrid(
                  delegate: SliverChildBuilderDelegate(
                    (ctx, i) => LiveRoomCard(
                      room: rooms[i],
                      onTap: () => context.go('/room/${rooms[i].id}'),
                    ),
                    childCount: rooms.length,
                  ),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: cols,
                    childAspectRatio: 1.15,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                ),
              );
            });
          },
          loading: () => const SliverFillRemaining(
            child: Center(child: CircularProgressIndicator(color: VelvetNoir.primary)),
          ),
          error: (e, _) => SliverFillRemaining(
            child: Center(child: Text('Error loading rooms: $e')),
          ),
        ),
      ],
    );
  }
}
