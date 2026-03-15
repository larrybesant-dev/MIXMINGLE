import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mixmingle/core/pagination/pagination_controller.dart';
import 'package:mixmingle/shared/models/room.dart';
import 'package:mixmingle/shared/widgets/paginated_list_view.dart';

/// Example implementation of paginated rooms browse page
/// This shows how to use PaginationController with the reusable PaginatedListView widget
class BrowseRoomsPaginatedPage extends ConsumerStatefulWidget {
  const BrowseRoomsPaginatedPage({super.key});

  @override
  ConsumerState<BrowseRoomsPaginatedPage> createState() =>
      _BrowseRoomsPaginatedPageState();
}

class _BrowseRoomsPaginatedPageState
    extends ConsumerState<BrowseRoomsPaginatedPage> {
  late PaginationController<Room> _controller;
  String? _selectedCategory;

  static const _categories = [
    'Music',
    'Gaming',
    'Talk',
    'Events',
    'Chill',
    'Business',
  ];

  @override
  void initState() {
    super.initState();
    _buildController();
    _controller.loadInitial();
  }

  void _buildController([String? category]) {
    _controller = PaginationController<Room>(
      pageSize: 20,
      queryBuilder: () {
<<<<<<< HEAD
        var query = FirebaseFirestore.instance
            .collection('rooms')
            .orderBy('createdAt', descending: true);
        if (category != null) {
          query = query.where('category', isEqualTo: category);
        }
        return query;
=======
        return FirebaseFirestore.instance
            .collection('rooms')
            .orderBy('createdAt', descending: true);
>>>>>>> origin/develop
      },
      fromDocument: (doc) => Room.fromMap(doc.data() as Map<String, dynamic>),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _showFilterSheet() {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const ListTile(
              title: Text('Filter by Category',
                  style: TextStyle(fontWeight: FontWeight.bold)),
            ),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.clear_all),
              title: const Text('All Categories'),
              selected: _selectedCategory == null,
              onTap: () {
                Navigator.of(ctx).pop();
                _applyCategory(null);
              },
            ),
            ..._categories.map((cat) => ListTile(
                  title: Text(cat),
                  selected: _selectedCategory == cat,
                  onTap: () {
                    Navigator.of(ctx).pop();
                    _applyCategory(cat);
                  },
                )),
          ],
        ),
      ),
    );
  }

  void _applyCategory(String? category) {
    setState(() {
      _selectedCategory = category;
      _controller.dispose();
      _buildController(category);
    });
    _controller.loadInitial();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Browse Rooms'),
        actions: [
          if (_selectedCategory != null)
            Chip(
              label: Text(_selectedCategory!),
              onDeleted: () => _applyCategory(null),
            ),
          IconButton(
            icon: Icon(
              Icons.filter_list,
              color: _selectedCategory != null ? Colors.amber : null,
            ),
            onPressed: _showFilterSheet,
          ),
        ],
      ),
      body: PaginatedListView<Room>(
        controller: _controller,
        padding: const EdgeInsets.all(16),
        itemBuilder: (context, room, index) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Card(
              child: ListTile(
                title: Text(room.name ?? room.title),
                subtitle: Text(
                    '${room.participantIds.length} members â€¢ ${room.viewerCount} viewers'),
                trailing: const Icon(Icons.arrow_forward),
                onTap: () {
                  // Navigate to room details
                  // Navigator.pushNamed(context, '/room/${room.id}');
                },
              ),
            ),
          );
        },
        emptyWidget: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.meeting_room, size: 64, color: Colors.grey[400]),
              const SizedBox(height: 16),
              Text(
                'No rooms available',
                style: TextStyle(
                  color: Colors.grey[400],
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Be the first to create a room!',
                style: TextStyle(
                  color: Colors.grey[500],
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
        errorBuilder: (error) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text(
                'Failed to load rooms',
                style: TextStyle(
                  color: Colors.grey[300],
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                error,
                style: TextStyle(
                  color: Colors.grey[500],
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () => _controller.refresh(),
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'browse_create_room_fab',
        onPressed: () {
          // Navigate to create room
          // Navigator.pushNamed(context, '/create-room');
        },
        icon: const Icon(Icons.add),
        label: const Text('Create Room'),
      ),
    );
  }
}
