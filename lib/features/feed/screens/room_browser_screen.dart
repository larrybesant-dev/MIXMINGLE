import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../models/room_model.dart';
import '../widgets/live_room_card.dart';

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

  @override
  void initState() {
    super.initState();
    if (widget.initialCategory != null) {
      _selectedCategory = widget.initialCategory;
      _showGrid = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
                }),
              )
            : null,
      ),
      body: _showGrid ? _RoomListView(category: _selectedCategory) : _CategoryGrid(
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

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 1.5,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: categories.length,
      itemBuilder: (ctx, i) {
        final cat = categories[i];
        return _CategoryCard(
          label: cat.label,
          emoji: cat.emoji,
          onTap: () => onCategorySelected(cat.value),
        );
      },
    );
  }
}

class _CategoryCard extends StatelessWidget {
  const _CategoryCard({
    required this.label,
    required this.emoji,
    required this.onTap,
  });

  final String label;
  final String emoji;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Ink(
        decoration: BoxDecoration(
          color: theme.colorScheme.primaryContainer,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 36)),
            const SizedBox(height: 8),
            Text(
              label,
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.onPrimaryContainer,
                fontWeight: FontWeight.w700,
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
            .map((doc) => RoomModel.fromJson({'id': doc.id, ...doc.data()}))
            .toList(),
      );
});

class _RoomListView extends ConsumerWidget {
  const _RoomListView({required this.category});

  final String? category;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final roomsAsync = ref.watch(_roomsByCategoryProvider(category));
    return roomsAsync.when(
      data: (rooms) {
        if (rooms.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.meeting_room_outlined, size: 56, color: Colors.grey),
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
