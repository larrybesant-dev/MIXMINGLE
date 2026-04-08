import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../models/room_model.dart';
import '../widgets/live_room_card.dart';
import '../../../widgets/mixvy_drawer.dart';

/// Live room category browser — a grid of category cards that lets users
/// browse rooms by topic, similar to Paltalk's main lobby.
///
/// Route: `/rooms` or `/rooms?category=music`
class RoomBrowserScreen extends ConsumerStatefulWidget {
  const RoomBrowserScreen({super.key, this.initialCategory});

  /// Optional initial category value (e.g. 'music').  When non-null the
  /// screen launches directly into that category's room list.
  final String? initialCategory;

  @override
  ConsumerState<RoomBrowserScreen> createState() => _RoomBrowserScreenState();
}

class _RoomBrowserScreenState extends ConsumerState<RoomBrowserScreen> {
  static const List<({String label, String emoji, String? value})> _categories =
      [
    (label: 'All', emoji: '🌐', value: null),
    (label: 'Music', emoji: '🎵', value: 'music'),
    (label: 'Talk', emoji: '💬', value: 'talk'),
    (label: 'Gaming', emoji: '🎮', value: 'gaming'),
    (label: 'Dance', emoji: '💃', value: 'dance'),
    (label: 'Dating', emoji: '❤️', value: 'dating'),
    (label: 'Study', emoji: '📚', value: 'study'),
    (label: 'Art', emoji: '🎨', value: 'art'),
  ];

  String? _selectedCategory;
  bool _showGrid = false; // false = category directory, true = room list
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() => _searchQuery = _searchController.text.trim().toLowerCase());
    });
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
      drawer: const MixVyDrawer(),
      appBar: AppBar(
        title: _showGrid
            ? Text(_categoryLabel(_selectedCategory))
            : const Text('Room Directory'),
        backgroundColor: Theme.of(context).colorScheme.surface,
        leading: _showGrid
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => setState(() {
                  _showGrid = false;
                  _selectedCategory = null;
                  _searchController.clear();
                }),
              )
            : null,
        bottom: _showGrid
            ? PreferredSize(
                preferredSize: const Size.fromHeight(56),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search rooms…',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () => _searchController.clear(),
                            )
                          : null,
                      isDense: true,
                      filled: true,
                      fillColor:
                          Theme.of(context).colorScheme.surfaceContainerHighest,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
              )
            : null,
      ),
      body: _showGrid
          ? _RoomListView(
              category: _selectedCategory,
              searchQuery: _searchQuery,
            )
          : _CategoryGrid(
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
    return cat != null ? '${cat.emoji} ${cat.label}' : 'Rooms';
  }
}

// ── Category grid ────────────────────────────────────────────────────────────

class _CategoryGrid extends StatelessWidget {
  const _CategoryGrid({
    required this.categories,
    required this.onCategorySelected,
  });

  final List<({String label, String emoji, String? value})> categories;
  final void Function(String? value) onCategorySelected;

  static const Map<String?, Color> _accentColors = {
    null:      Color(0xFFBA9EFF),
    'music':   Color(0xFF00E3FD),
    'talk':    Color(0xFFFFB74D),
    'gaming':  Color(0xFF66BB6A),
    'dance':   Color(0xFFFF6EB4),
    'dating':  Color(0xFFFF6E84),
    'study':   Color(0xFF64B5F6),
    'art':     Color(0xFFFFCA28),
  };

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final width = constraints.maxWidth;
      final crossAxisCount = width > 900 ? 4 : width > 600 ? 3 : 2;
      return CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
              child: _CreateRoomBanner(),
            ),
          ),
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(16, 20, 16, 8),
              child: Text(
                'BROWSE BY CATEGORY',
                style: TextStyle(
                  color: Color(0xFFA9ABB3),
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2,
                ),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            sliver: SliverGrid(
              delegate: SliverChildBuilderDelegate(
                (ctx, i) {
                  final cat = categories[i];
                  return _CategoryCard(
                    label: cat.label,
                    emoji: cat.emoji,
                    value: cat.value,
                    accent: _accentColors[cat.value] ?? const Color(0xFFBA9EFF),
                    onTap: () => onCategorySelected(cat.value),
                  );
                },
                childCount: categories.length,
              ),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
                childAspectRatio: 2.2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
            ),
          ),
        ],
      );
    });
  }
}

class _CreateRoomBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.go('/create-room'),
      child: Container(
        height: 76,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF8455EF), Color(0xFFBA9EFF)],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFBA9EFF).withValues(alpha: 0.28),
              blurRadius: 20,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.add_rounded, color: Colors.white, size: 26),
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Create a Room',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Go live with your community',
                      style: TextStyle(color: Color(0xCCFFFFFF), fontSize: 12),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: Colors.white, size: 24),
            ],
          ),
        ),
      ),
    );
  }
}

class _CategoryCard extends StatelessWidget {
  const _CategoryCard({
    required this.label,
    required this.emoji,
    required this.value,
    required this.accent,
    required this.onTap,
  });

  final String label;
  final String emoji;
  final String? value;
  final Color accent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Ink(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              accent.withValues(alpha: 0.10),
              const Color(0xFF1C2028),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: accent.withValues(alpha: 0.30), width: 1),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: Text(emoji, style: const TextStyle(fontSize: 20)),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                label,
                style: const TextStyle(
                  color: Color(0xFFECEDF6),
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Room list for a category ─────────────────────────────────────────────────

final _roomsByCategoryProvider = StreamProvider.autoDispose
    .family<List<RoomModel>, String?>((ref, category) {
  Query<Map<String, dynamic>> query = FirebaseFirestore.instance
      .collection('rooms')
      .where('isLive', isEqualTo: true)
      .orderBy('participantCount', descending: true)
      .limit(50);

  if (category != null) {
    query = query.where('category', isEqualTo: category);
  }

  return query.snapshots().map(
        (snap) => snap.docs
            .map((doc) => RoomModel.fromJson(doc.data(), doc.id))
            .toList(),
      );
});

class _RoomListView extends ConsumerWidget {
  const _RoomListView({required this.category, required this.searchQuery});

  final String? category;
  final String searchQuery;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final roomsAsync = ref.watch(_roomsByCategoryProvider(category));
    return roomsAsync.when(
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
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.meeting_room_outlined, size: 56, color: Color(0xFFA9ABB3)),
                const SizedBox(height: 12),
                const Text('No live rooms in this category right now.'),
                const SizedBox(height: 16),
                FilledButton.tonal(
                  onPressed: () => context.go('/'),
                  child: const Text('Back to home'),
                ),
              ],
            ),
          );
        }
        return GridView.builder(
          padding: const EdgeInsets.all(16),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 0.85,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
          ),
          itemCount: rooms.length,
          itemBuilder: (ctx, i) {
            final room = rooms[i];
            return LiveRoomCard(
              room: room,
              onTap: () => context.go('/room/${room.id}'),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error loading rooms: $e')),
    );
  }
}
