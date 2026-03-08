import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/design_system/design_constants.dart';
import '../../services/search/search_service.dart';
import '../../core/routing/app_routes.dart';

// ── Providers ────────────────────────────────────────────────────────────────

/// Main search results provider — fires after debounce
final searchResultsProvider =
    FutureProvider.autoDispose.family<List<SearchResult>, String>((ref, query) async {
  if (query.trim().isEmpty) return [];
  return SearchService.instance.search(query, limit: 15);
});

// ── Page ─────────────────────────────────────────────────────────────────────

class SearchPage extends ConsumerStatefulWidget {
  const SearchPage({super.key});

  @override
  ConsumerState<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends ConsumerState<SearchPage>
    with SingleTickerProviderStateMixin {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  late final TabController _tabController;
  Timer? _debounce;
  String _submittedQuery = '';

  static const _tabs = ['All', 'People', 'Rooms', 'Posts', 'Events'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() {});
      }
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    _focusNode.dispose();
    _tabController.dispose();
    super.dispose();
  }

  void _onQueryChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () {
      if (mounted) setState(() => _submittedQuery = value.trim());
    });
  }

  void _clearSearch() {
    _controller.clear();
    setState(() => _submittedQuery = '');
    _focusNode.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DesignColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildSearchBar(),
            if (_submittedQuery.isNotEmpty) _buildTabBar(),
            Expanded(
              child: _submittedQuery.isEmpty
                  ? _buildEmptyState()
                  : _buildResults(),
            ),
          ],
        ),
      ),
    );
  }

  // ── Search bar ─────────────────────────────────────────────────────────────

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, size: 18),
            color: DesignColors.textGray,
            onPressed: () => Navigator.of(context).pop(),
          ),
          Expanded(
            child: Container(
              height: 44,
              decoration: BoxDecoration(
                color: DesignColors.surfaceLight,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: DesignColors.accent.withValues(alpha: 0.2)),
              ),
              child: TextField(
                controller: _controller,
                focusNode: _focusNode,
                onChanged: _onQueryChanged,
                onSubmitted: (v) => setState(() => _submittedQuery = v.trim()),
                textInputAction: TextInputAction.search,
                style: const TextStyle(color: Colors.white, fontSize: 15),
                decoration: InputDecoration(
                  hintText: 'Search people, rooms, posts…',
                  hintStyle: TextStyle(
                    color: DesignColors.textGray.withValues(alpha: 0.6),
                    fontSize: 14,
                  ),
                  prefixIcon: Icon(Icons.search,
                      color: DesignColors.textGray.withValues(alpha: 0.6), size: 20),
                  suffixIcon: _controller.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.close, size: 18),
                          color: DesignColors.textGray,
                          onPressed: _clearSearch,
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Tab bar ────────────────────────────────────────────────────────────────

  Widget _buildTabBar() {
    return TabBar(
      controller: _tabController,
      isScrollable: true,
      tabAlignment: TabAlignment.start,
      indicatorColor: DesignColors.accent,
      indicatorWeight: 2,
      labelColor: DesignColors.accent,
      unselectedLabelColor: DesignColors.textGray,
      labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
      dividerColor: Colors.transparent,
      tabs: _tabs.map((t) => Tab(text: t)).toList(),
    );
  }

  // ── Empty / hint state ─────────────────────────────────────────────────────

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.search,
              size: 60, color: DesignColors.textGray.withValues(alpha: 0.3)),
          const SizedBox(height: 16),
          const Text('Search MixMingle',
              style: TextStyle(
                color: DesignColors.textGray,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              )),
          const SizedBox(height: 8),
          Text('Find people, rooms, posts & events',
              style: TextStyle(
                color: DesignColors.textGray.withValues(alpha: 0.6),
                fontSize: 14,
              )),
        ],
      ),
    );
  }

  // ── Results ────────────────────────────────────────────────────────────────

  Widget _buildResults() {
    final results = ref.watch(searchResultsProvider(_submittedQuery));
    final activeTab = _tabController.index;

    return results.when(
      loading: () => const Center(
        child: CircularProgressIndicator(
            strokeWidth: 2, color: DesignColors.accent),
      ),
      error: (e, _) => const Center(
        child: Text('Search unavailable',
            style: TextStyle(color: DesignColors.textGray)),
      ),
      data: (allResults) {
        final filtered = _filterByTab(allResults, activeTab);
        if (filtered.isEmpty) {
          return Center(
            child: Text(
              'No results for "$_submittedQuery"',
              style: const TextStyle(color: DesignColors.textGray, fontSize: 15),
            ),
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.symmetric(vertical: 8),
          itemCount: filtered.length,
          separatorBuilder: (_, __) => const Divider(
            height: 1,
            color: DesignColors.surfaceLight,
            indent: 72,
          ),
          itemBuilder: (context, i) => _SearchResultTile(
            result: filtered[i],
            onTap: () => _navigateTo(filtered[i]),
          ),
        );
      },
    );
  }

  List<SearchResult> _filterByTab(List<SearchResult> all, int tab) {
    if (tab == 0) return all;
    const typeMap = [
      null,
      SearchResultType.user,
      SearchResultType.room,
      SearchResultType.post,
      SearchResultType.event,
    ];
    final targetType = typeMap[tab];
    return all.where((r) => r.type == targetType).toList();
  }

  void _navigateTo(SearchResult result) {
    switch (result.type) {
      case SearchResultType.user:
        Navigator.pushNamed(context, AppRoutes.userProfile,
            arguments: result.id);
      case SearchResultType.room:
        Navigator.pushNamed(context, AppRoutes.liveRoom,
            arguments: result.id);
      case SearchResultType.post:
        // Navigate to home feed — individual post detail page TBD
        Navigator.pushNamed(context, AppRoutes.home);
      case SearchResultType.event:
        Navigator.pushNamed(context, AppRoutes.eventDetails,
            arguments: result.id);
    }
  }
}

// ── Result tile ───────────────────────────────────────────────────────────────

class _SearchResultTile extends StatelessWidget {
  final SearchResult result;
  final VoidCallback onTap;

  const _SearchResultTile({required this.result, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: _buildLeading(),
      title: Text(
        result.title,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: result.subtitle != null
          ? Text(
              result.subtitle!,
              style: const TextStyle(
                color: DesignColors.textGray,
                fontSize: 12,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            )
          : null,
      trailing: _buildTypeChip(),
    );
  }

  Widget _buildLeading() {
    return CircleAvatar(
      radius: 22,
      backgroundColor: DesignColors.surfaceLight,
      backgroundImage:
          result.imageUrl != null ? NetworkImage(result.imageUrl!) : null,
      child: result.imageUrl == null
          ? Text(
              result.title.isNotEmpty ? result.title[0].toUpperCase() : '?',
              style: const TextStyle(
                color: DesignColors.accent,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            )
          : null,
    );
  }

  Widget _buildTypeChip() {
    const labels = {
      SearchResultType.user: ('person', Colors.blue),
      SearchResultType.room: ('mic', Colors.purple),
      SearchResultType.post: ('article', Colors.green),
      SearchResultType.event: ('event', Colors.orange),
    };
    final (label, color) = labels[result.type]!;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w600),
      ),
    );
  }
}
