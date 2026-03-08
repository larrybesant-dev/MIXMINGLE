import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/design_system/design_constants.dart';
import 'widgets/trending_rooms_section.dart';
import 'widgets/recommended_users_section.dart';
import 'discovery_filter_panel.dart';

/// Main discovery feed: trending rooms + recommended users.
/// Accessed via AppRoutes.discovery = '/discovery'.
class DiscoveryPage extends ConsumerStatefulWidget {
  const DiscoveryPage({super.key});

  @override
  ConsumerState<DiscoveryPage> createState() => _DiscoveryPageState();
}

class _DiscoveryPageState extends ConsumerState<DiscoveryPage> {
  String _selectedCategory = 'All';
  final _searchCtrl = TextEditingController();
  String _searchQuery = '';

  static const _categories = [
    'All', 'Music', 'Dating', 'Talk', 'Gaming', 'Study', 'News',
  ];

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DesignColors.background,
      appBar: AppBar(
        backgroundColor: DesignColors.surfaceDefault,
        elevation: 0,
        title: const Text(
          'Discover',
          style: TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.tune_rounded, color: Colors.white70),
            tooltip: 'Filters',
            onPressed: () => DiscoveryFilterPanel.show(
              context,
              currentCategory: _selectedCategory,
              onCategorySelected: (cat) =>
                  setState(() => _selectedCategory = cat),
            ),
          ),
        ],
      ),
      body: CustomScrollView(
        slivers: [
          // Search bar
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: TextField(
                controller: _searchCtrl,
                style: const TextStyle(color: Colors.white),
                onChanged: (v) => setState(() => _searchQuery = v.trim()),
                decoration: InputDecoration(
                  hintText: 'Search rooms & people...',
                  hintStyle:
                      TextStyle(color: Colors.white.withValues(alpha: 0.35)),
                  filled: true,
                  fillColor: DesignColors.surfaceLight,
                  prefixIcon:
                      const Icon(Icons.search, color: Colors.white38),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, color: Colors.white38),
                          onPressed: () {
                            _searchCtrl.clear();
                            setState(() => _searchQuery = '');
                          },
                        )
                      : null,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 20, vertical: 14),
                ),
              ),
            ),
          ),

          // Category chips
          SliverToBoxAdapter(
            child: SizedBox(
              height: 44,
              child: ListView.separated(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16),
                scrollDirection: Axis.horizontal,
                itemCount: _categories.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, i) {
                  final cat = _categories[i];
                  final selected = _selectedCategory == cat;
                  return GestureDetector(
                    onTap: () =>
                        setState(() => _selectedCategory = cat),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: selected
                            ? DesignColors.accent
                            : DesignColors.surfaceLight,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        cat,
                        style: TextStyle(
                          color: selected ? Colors.white : Colors.white60,
                          fontSize: 13,
                          fontWeight: selected
                              ? FontWeight.w600
                              : FontWeight.normal,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 20)),

          // Trending rooms
          SliverToBoxAdapter(
            child: TrendingRoomsSection(
              category:
                  _selectedCategory == 'All' ? null : _selectedCategory,
              searchQuery: _searchQuery,
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 24)),

          // Recommended users (only shown if no active search)
          if (_searchQuery.isEmpty)
            SliverToBoxAdapter(
              child: RecommendedUsersSection(
                category: _selectedCategory == 'All'
                    ? null
                    : _selectedCategory,
              ),
            ),

          const SliverToBoxAdapter(child: SizedBox(height: 80)),
        ],
      ),
    );
  }
}
