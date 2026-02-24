/// Rooms List Page
/// Browse and join live video rooms
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/design_system/design_constants.dart';
import '../../../shared/widgets/club_background.dart';
import '../../../shared/widgets/neon_components.dart';
import '../../../shared/models/room.dart';
import '../../../shared/models/room_categories.dart';
import '../providers/rooms_provider.dart';

/// Rooms List - Browse all live rooms
class RoomsListPage extends ConsumerStatefulWidget {
  const RoomsListPage({super.key});

  @override
  ConsumerState<RoomsListPage> createState() => _RoomsListPageState();
}

class _RoomsListPageState extends ConsumerState<RoomsListPage> {
  String? _selectedCategory;

  @override
  Widget build(BuildContext context) {
    final roomsState = ref.watch(roomsProvider);
    final rooms = roomsState.rooms;

    return ClubBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: const NeonText(
            'LIVE ROOMS',
            fontSize: 24,
            fontWeight: FontWeight.w900,
            textColor: DesignColors.white,
            glowColor: DesignColors.accent,
          ),
          backgroundColor: Colors.transparent,
          elevation: 0,
          actions: [
            IconButton(
              icon: const Icon(Icons.add_circle_outline),
              onPressed: () => _showCreateRoomDialog(),
              tooltip: 'Create Room',
            ),
          ],
        ),
        body: Column(
          children: [
            // Category filters
            _buildCategoryFilters(),

            // Rooms list
            Expanded(
              child: roomsState.isLoading && rooms.isEmpty
                  ? const Center(child: CircularProgressIndicator())
                  : rooms.isEmpty
                      ? _buildEmptyState()
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: rooms.length,
                          itemBuilder: (context, index) {
                            return _buildRoomCard(rooms[index]);
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryFilters() {
    return SizedBox(
      height: 50,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          _buildCategoryChip('All', null),
          ...RoomCategories.all.map(
            (category) => _buildCategoryChip(
              RoomCategories.getDisplayName(category),
              category,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryChip(String label, String? category) {
    final isSelected = _selectedCategory == category;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (selected) {
          setState(() {
            _selectedCategory = selected ? category : null;
          });
          ref.read(roomsProvider.notifier).setCategory(_selectedCategory);
        },
        backgroundColor: DesignColors.accent.withValues(alpha: 255, red: 255, green: 255, blue: 255),
        selectedColor: DesignColors.accent.withValues(alpha: 255, red: 255, green: 255, blue: 255),
        checkmarkColor: DesignColors.white,
        labelStyle: TextStyle(
          color: DesignColors.white,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
    );
  }

  Widget _buildRoomCard(Room room) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: NeonGlowCard(
        glowColor: DesignColors.accent,
        onTap: () {
          Navigator.pushNamed(context, '/room', arguments: room.id);
        },
        child: Row(
          children: [
            // Thumbnail
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: DesignColors.accent.withValues(alpha: 255, red: 255, green: 255, blue: 255),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: DesignColors.accent,
                  width: 2,
                ),
              ),
              child: Stack(
                children: [
                  const Center(
                  child: Icon(
                    Icons.video_call,
                    color: DesignColors.accent,
                    size: 40,
                  ),
                ),
                if (room.isLive)
                  Positioned(
                    top: 4,
                    right: 4,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        'LIVE',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),

            // Room info
            Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  room.title,
                  style: const TextStyle(
                    color: DesignColors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  room.description,
                  style: TextStyle(
                    color: DesignColors.white.withValues(alpha: 255, red: 255, green: 255, blue: 255),
                    fontSize: 12,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(
                      Icons.people,
                      size: 14,
                      color: DesignColors.gold,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${room.viewerCount} watching',
                      style: const TextStyle(
                        color: DesignColors.gold,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: DesignColors.accent.withValues(alpha: 255, red: 255, green: 255, blue: 255),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        RoomCategories.getDisplayName(room.category),
                        style: const TextStyle(
                          color: DesignColors.white,
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Join button
          const Icon(
            Icons.arrow_forward_ios,
            color: DesignColors.accent,
            size: 20,
          ),
        ],
      ),
    ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.video_call_outlined,
            size: 80,
            color: DesignColors.white.withValues(alpha: 255, red: 255, green: 255, blue: 255),
          ),
          const SizedBox(height: 16),
          Text(
            'No live rooms right now',
            style: TextStyle(
              color: DesignColors.white.withValues(alpha: 255, red: 255, green: 255, blue: 255),
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Be the first to create one!',
            style: TextStyle(
              color: DesignColors.white,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 24),
          NeonButton(
            label: 'CREATE ROOM',
            onPressed: () => _showCreateRoomDialog(),
            glowColor: DesignColors.accent,
          ),
        ],
      ),
    );
  }

  Future<void> _showCreateRoomDialog() async {
    final nameController = TextEditingController();
    final descriptionController = TextEditingController();
    String? selectedCategory;

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: DesignColors.background,
        title: const Text(
          'Create Room',
          style: TextStyle(color: DesignColors.white),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                style: const TextStyle(color: DesignColors.white),
                decoration: const InputDecoration(
                  labelText: 'Room Name',
                  labelStyle: TextStyle(color: DesignColors.white),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: DesignColors.accent),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: DesignColors.gold),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: descriptionController,
                style: const TextStyle(color: DesignColors.white),
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Description (optional)',
                  labelStyle: TextStyle(color: DesignColors.white),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: DesignColors.accent),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: DesignColors.gold),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                dropdownColor: DesignColors.background,
                style: const TextStyle(color: DesignColors.white),
                decoration: const InputDecoration(
                  labelText: 'Category',
                  labelStyle: TextStyle(color: DesignColors.white),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: DesignColors.accent),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: DesignColors.gold),
                  ),
                ),
                items: RoomCategories.all
                    .map((category) => DropdownMenuItem(
                          value: category,
                          child: Text(RoomCategories.getDisplayName(category)),
                        ))
                    .toList(),
                onChanged: (value) {
                  selectedCategory = value;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: DesignColors.accent,
            ),
            onPressed: () async {
              if (nameController.text.trim().isEmpty) {
                return;
              }

              final navigator = Navigator.of(context);
              final roomId = await ref.read(roomsProvider.notifier).createRoom(
                    name: nameController.text.trim(),
                    description: descriptionController.text.trim().isEmpty
                        ? null
                        : descriptionController.text.trim(),
                    category: selectedCategory,
                  );

              if (mounted && roomId != null) {
                navigator.pop();
                navigator.pushNamed('/room', arguments: roomId);
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }
}
