import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import 'package:mixmingle/services/room/room_discovery_service.dart';
import 'package:mixmingle/shared/models/moderation.dart';
import 'package:mixmingle/shared/widgets/club_background.dart';
import 'package:mixmingle/shared/widgets/glow_text.dart';
import 'package:mixmingle/shared/providers/all_providers.dart';
import 'package:mixmingle/shared/models/room.dart';
import '../room/room_access_wrapper.dart';

class RoomDiscoveryPage extends ConsumerStatefulWidget {
  const RoomDiscoveryPage({super.key});

  @override
  ConsumerState<RoomDiscoveryPage> createState() => _RoomDiscoveryPageState();
}

class _RoomDiscoveryPageState extends ConsumerState<RoomDiscoveryPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final discoveryService = ref.watch(roomDiscoveryServiceProvider);

    return ClubBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: const GlowText(
            text: 'Discover Rooms',
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            glowColor: Color(0xFFFF4C4C),
          ),
          backgroundColor: Colors.transparent,
          elevation: 0,
          bottom: TabBar(
            controller: _tabController,
            indicatorColor: const Color(0xFFFF4C4C),
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white60,
            tabs: const [
              Tab(text: 'Trending'),
              Tab(text: 'Categories'),
              Tab(text: 'Search'),
            ],
          ),
        ),
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildTrendingTab(discoveryService),
            _buildCategoriesTab(discoveryService),
            _buildSearchTab(discoveryService),
          ],
        ),
      ),
    );
  }

  Widget _buildTrendingTab(RoomDiscoveryService discoveryService) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Trending Rooms
          const GlowText(
            text: 'ðŸ”¥ Trending Now',
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
          const SizedBox(height: 12),
          FutureBuilder(
            future: discoveryService.getTrendingRooms(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return Text('Error: ${snapshot.error}');
              }
              final rooms = snapshot.data ?? [];
              if (rooms.isEmpty) {
                return const Text('No trending rooms');
              }
              return Column(
                children: rooms.map((doc) {
                  final room = Room.fromDocument(doc);
                  return _buildRoomCard(room);
                }).toList(),
              );
            },
          ),
          const SizedBox(height: 24),

          // New Rooms
          const GlowText(
            text: 'âœ¨ New Rooms',
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
          const SizedBox(height: 12),
          FutureBuilder(
            future: discoveryService.getNewRooms(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              final rooms = snapshot.data ?? [];
              if (rooms.isEmpty) {
                return const Text('No new rooms');
              }
              return Column(
                children: rooms.map((doc) {
                  final room = Room.fromDocument(doc);
                  return _buildRoomCard(room);
                }).toList(),
              );
            },
          ),
          const SizedBox(height: 24),

          // Popular Tags
          const GlowText(
            text: 'ðŸ·ï¸ Popular Tags',
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
          const SizedBox(height: 12),
          FutureBuilder(
            future: discoveryService.getPopularTags(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              final tags = snapshot.data ?? [];
              if (tags.isEmpty) {
                return const Text('No popular tags');
              }
              return Wrap(
                spacing: 8,
                runSpacing: 8,
                children: tags.map((tag) => _buildTagChip(tag)).toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildCategoriesTab(RoomDiscoveryService discoveryService) {
    return FutureBuilder<List<RoomCategory>>(
      future: discoveryService.getCategories(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        final categories = snapshot.data ?? [];
        if (categories.isEmpty) {
          return const Center(child: Text('No categories available'));
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: categories.length,
          itemBuilder: (context, index) {
            final category = categories[index];
            return _buildCategoryCard(category, discoveryService);
          },
        );
      },
    );
  }

  Widget _buildSearchTab(RoomDiscoveryService discoveryService) {
    return Column(
      children: [
        // Search Bar
        Padding(
          padding: const EdgeInsets.all(16),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search rooms...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        setState(() {
                          _searchController.clear();
                          _searchQuery = '';
                        });
                      },
                    )
                  : null,
              filled: true,
              fillColor: Colors.white.withValues(alpha: 0.1),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
            style: const TextStyle(color: Colors.white),
            onChanged: (value) {
              setState(() {
                _searchQuery = value;
              });
            },
          ),
        ),

        // Search Results
        Expanded(
          child: _searchQuery.isEmpty
              ? const Center(
                  child: Text(
                    'Enter a search term to find rooms',
                    style: TextStyle(color: Colors.white70),
                  ),
                )
              : FutureBuilder(
                  future: discoveryService.searchRooms(_searchQuery),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (snapshot.hasError) {
                      return Center(child: Text('Error: ${snapshot.error}'));
                    }

                    final rooms = snapshot.data ?? [];
                    if (rooms.isEmpty) {
                      return const Center(
                        child: Text(
                          'No rooms found',
                          style: TextStyle(color: Colors.white70),
                        ),
                      );
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: rooms.length,
                      itemBuilder: (context, index) {
                        final room = Room.fromDocument(rooms[index]);
                        return _buildRoomCard(room);
                      },
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildCategoryCard(RoomCategory category, RoomDiscoveryService discoveryService) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: Colors.white.withValues(alpha: 0.1),
      child: InkWell(
        onTap: () => _showCategoryRooms(category, discoveryService),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Icon
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFF4C4C), Color(0xFFFFD700)],
                  ),
                ),
                child: const Icon(
                  Icons.category,
                  color: Colors.white,
                  size: 30,
                ),
              ),
              const SizedBox(width: 16),

              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      category.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      category.description,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.7),
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${category.roomCount} rooms',
                      style: const TextStyle(
                        color: Color(0xFFFFD700),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),

              const Icon(
                Icons.chevron_right,
                color: Colors.white60,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRoomCard(Room room) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: Colors.white.withValues(alpha: 0.1),
      child: InkWell(
        onTap: () => _joinRoom(room),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Thumbnail/Icon
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFF4C4C), Color(0xFFFFD700)],
                  ),
                ),
                child: const Icon(
                  Icons.groups,
                  color: Colors.white,
                  size: 30,
                ),
              ),
              const SizedBox(width: 12),

              // Room Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      (room.name ?? room.title),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (room.description.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        room.description,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.7),
                          fontSize: 12,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.people,
                          size: 14,
                          color: Colors.white.withValues(alpha: 0.7),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${room.participantIds.length} online',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.7),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Type Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _getRoomTypeColor(room.roomType),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  room.roomType.name.toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTagChip(String tag) {
    return ActionChip(
      label: Text(tag),
      labelStyle: const TextStyle(color: Colors.white),
      backgroundColor: const Color(0xFFFF4C4C).withValues(alpha: 0.3),
      side: const BorderSide(color: Color(0xFFFF4C4C)),
      onPressed: () {
        setState(() {
          _searchController.text = tag;
          _searchQuery = tag;
          _tabController.index = 2; // Switch to search tab
        });
      },
    );
  }

  Color _getRoomTypeColor(RoomType type) {
    switch (type) {
      case RoomType.text:
        return Colors.blue.withValues(alpha: 0.6);
      case RoomType.voice:
        return Colors.green.withValues(alpha: 0.6);
      case RoomType.video:
        return Colors.purple.withValues(alpha: 0.6);
    }
  }

  Future<void> _showCategoryRooms(RoomCategory category, RoomDiscoveryService discoveryService) async {
    final rooms = await discoveryService.getRoomsByCategory(category.id);

    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.95),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          border: Border.all(
            color: const Color(0xFFFF4C4C).withValues(alpha: 0.5),
            width: 2,
          ),
        ),
        child: Column(
          children: [
            // Handle
            Container(
              margin: const EdgeInsets.symmetric(vertical: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // Title
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: GlowText(
                text: category.name,
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                category.description,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.7),
                  fontSize: 14,
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Rooms List
            Expanded(
              child: rooms.isEmpty
                  ? const Center(
                      child: Text(
                        'No rooms in this category yet',
                        style: TextStyle(color: Colors.white70),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: rooms.length,
                      itemBuilder: (context, index) {
                        final room = Room.fromDocument(rooms[index]);
                        return _buildRoomCard(room);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  void _joinRoom(Room room) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RoomAccessWrapper(
          room:   room,
          userId: fb_auth.FirebaseAuth.instance.currentUser?.uid ?? '',
        ),
      ),
    );
  }
}
