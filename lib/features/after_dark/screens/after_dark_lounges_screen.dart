import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../models/room_model.dart';
import '../../../features/feed/widgets/live_room_card.dart';
import '../theme/after_dark_theme.dart';

const List<({String label, String emoji, String? value})> _loungeCategories = [
  (label: 'All',       emoji: '🔥', value: null),
  (label: 'Romance',   emoji: '💋', value: 'romance'),
  (label: 'Roleplay',  emoji: '🎭', value: 'roleplay'),
  (label: 'Chat',      emoji: '💬', value: 'chat'),
  (label: 'Couples',   emoji: '💑', value: 'couples'),
  (label: 'Dating',    emoji: '❤️', value: 'dating'),
  (label: 'Party',     emoji: '🥂', value: 'party'),
];

final _adultRoomsProvider = StreamProvider.autoDispose
    .family<List<RoomModel>, String?>((ref, category) {
  Query<Map<String, dynamic>> q = FirebaseFirestore.instance
      .collection('rooms')
      .where('isLive', isEqualTo: true)
      .where('isAdult', isEqualTo: true)
      .orderBy('memberCount', descending: true)
      .limit(50);

  if (category != null) {
    q = q.where('category', isEqualTo: category);
  }

  return q.snapshots().map(
        (s) => s.docs.map((d) => RoomModel.fromJson(d.data(), d.id)).toList(),
      );
});

/// After Dark lounges browser — lists all 18+ live rooms with category filter.
class AfterDarkLoungesScreen extends ConsumerStatefulWidget {
  const AfterDarkLoungesScreen({super.key});

  @override
  ConsumerState<AfterDarkLoungesScreen> createState() =>
      _AfterDarkLoungesScreenState();
}

class _AfterDarkLoungesScreenState
    extends ConsumerState<AfterDarkLoungesScreen> {
  String? _selectedCategory;
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() =>
          _searchQuery = _searchController.text.trim().toLowerCase());
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final roomsAsync = ref.watch(_adultRoomsProvider(_selectedCategory));

    return Scaffold(
      backgroundColor: EmberDark.surface,
      body: CustomScrollView(
        slivers: [
          // Sticky search + category bar
          SliverAppBar(
            backgroundColor: EmberDark.surface,
            automaticallyImplyLeading: false,
            pinned: true,
            toolbarHeight: 0,
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(112),
              child: Column(
                children: [
                  // Search bar
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                    child: TextField(
                      controller: _searchController,
                      style: const TextStyle(color: EmberDark.onSurface),
                      decoration: InputDecoration(
                        hintText: 'Search lounges…',
                        hintStyle: const TextStyle(
                            color: EmberDark.onSurfaceVariant),
                        prefixIcon: const Icon(Icons.search_rounded,
                            color: EmberDark.onSurfaceVariant),
                        suffixIcon: _searchQuery.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear_rounded,
                                    color: EmberDark.onSurfaceVariant),
                                onPressed: () =>
                                    _searchController.clear(),
                              )
                            : null,
                        filled: true,
                        fillColor: EmberDark.surfaceHigh,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 10),
                        isDense: true,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  // Category chips
                  SizedBox(
                    height: 40,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      padding:
                          const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: _loungeCategories.length,
                      separatorBuilder: (_, _) =>
                          const SizedBox(width: 8),
                      itemBuilder: (ctx, i) {
                        final cat = _loungeCategories[i];
                        final isSelected =
                            _selectedCategory == cat.value;
                        return GestureDetector(
                          onTap: () => setState(
                              () => _selectedCategory = cat.value),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 8),
                            decoration: BoxDecoration(
                              gradient: isSelected
                                  ? EmberDark.primaryGradient
                                  : null,
                              color: isSelected
                                  ? null
                                  : EmberDark.surfaceHigh,
                              borderRadius:
                                  BorderRadius.circular(999),
                              border: Border.all(
                                color: isSelected
                                    ? Colors.transparent
                                    : EmberDark.outlineVariant
                                        .withValues(alpha: 0.5),
                              ),
                            ),
                            child: Text(
                              '${cat.emoji} ${cat.label}',
                              style: TextStyle(
                                color: isSelected
                                    ? Colors.white
                                    : EmberDark.onSurfaceVariant,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),

          // Create lounge banner
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: _CreateLoungeBanner(),
            ),
          ),

          // Rooms grid
          roomsAsync.when(
            loading: () => const SliverToBoxAdapter(
              child: Center(
                child: Padding(
                  padding: EdgeInsets.all(40),
                  child: CircularProgressIndicator(
                      color: EmberDark.primary),
                ),
              ),
            ),
            error: (e, _) => SliverToBoxAdapter(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text('Error loading lounges.',
                      style: TextStyle(
                          color: EmberDark.onSurfaceVariant)),
                ),
              ),
            ),
            data: (allRooms) {
              final rooms = _searchQuery.isEmpty
                  ? allRooms
                  : allRooms
                      .where((r) =>
                          r.name
                              .toLowerCase()
                              .contains(_searchQuery) ||
                          (r.description
                                  ?.toLowerCase()
                                  .contains(_searchQuery) ??
                              false))
                      .toList();

              if (rooms.isEmpty) {
                return SliverToBoxAdapter(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(40),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.nightlife_outlined,
                              color: EmberDark.onSurfaceVariant,
                              size: 52),
                          const SizedBox(height: 12),
                          const Text(
                            'No live lounges right now',
                            style: TextStyle(
                                color: EmberDark.onSurface,
                                fontWeight: FontWeight.w700,
                                fontSize: 16),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Be the first to go live.',
                            style: TextStyle(
                                color: EmberDark.onSurfaceVariant),
                          ),
                          const SizedBox(height: 20),
                          FilledButton.icon(
                            onPressed: () => context
                                .go('/after-dark/create-lounge'),
                            icon: const Icon(Icons.add_rounded,
                                size: 18),
                            label: const Text('Start a Lounge'),
                            style: FilledButton.styleFrom(
                              backgroundColor: EmberDark.primary,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                  borderRadius:
                                      BorderRadius.circular(999)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }

              return SliverPadding(
                padding:
                    const EdgeInsets.fromLTRB(16, 12, 16, 32),
                sliver: SliverGrid(
                  delegate: SliverChildBuilderDelegate(
                    (ctx, i) => LiveRoomCard(
                      room: rooms[i],
                      onTap: () =>
                          context.go('/room/${rooms[i].id}'),
                    ),
                    childCount: rooms.length,
                  ),
                  gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.85,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _CreateLoungeBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.go('/after-dark/create-lounge'),
      child: Container(
        height: 70,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [EmberDark.primaryDim, EmberDark.primary],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: EmberDark.primary.withValues(alpha: 0.3),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.add_rounded,
                  color: Colors.white, size: 24),
            ),
            const SizedBox(width: 14),
            const Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Create an After Dark Lounge',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    'Go live with an 18+ community',
                    style: TextStyle(
                        color: Color(0xCCFFFFFF), fontSize: 11),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded,
                color: Colors.white, size: 22),
          ],
        ),
      ),
    );
  }
}
