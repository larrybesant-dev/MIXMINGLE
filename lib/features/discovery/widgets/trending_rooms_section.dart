import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../../../core/design_system/design_constants.dart';
import 'package:mixvy/router/app_routes.dart';

/// Shows trending/live rooms filtered by optional category and search query.
class TrendingRoomsSection extends StatelessWidget {
  final String? category;
  final String searchQuery;

  const TrendingRoomsSection({
    super.key,
    this.category,
    this.searchQuery = '',
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              const Icon(Icons.local_fire_department,
                  color: Color(0xFFFF4D8B), size: 20),
              const SizedBox(width: 8),
              const Text(
                'Trending Rooms',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              TextButton(
                onPressed: () =>
                    Navigator.pushNamed(context, AppRoutes.discoverRoomsLive),
                child: const Text(
                  'See all',
                  style: TextStyle(color: DesignColors.accent, fontSize: 13),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        StreamBuilder<QuerySnapshot>(
          stream: _buildQuery().limit(10).snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const SizedBox(
                height: 160,
                child:
                    Center(child: CircularProgressIndicator(color: DesignColors.accent)),
              );
            }

            var docs = snapshot.data?.docs ?? [];

            // Client-side search filter
            if (searchQuery.isNotEmpty) {
              final q = searchQuery.toLowerCase();
              docs = docs.where((d) {
                final data = d.data() as Map<String, dynamic>;
                final name = (data['name'] as String? ?? '').toLowerCase();
                return name.contains(q);
              }).toList();
            }

            if (docs.isEmpty) {
              return SizedBox(
                height: 120,
                child: Center(
                  child: Text(
                    'No rooms found',
                    style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.4),
                        fontSize: 14),
                  ),
                ),
              );
            }

            return SizedBox(
              height: 170,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                scrollDirection: Axis.horizontal,
                itemCount: docs.length,
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemBuilder: (context, i) {
                  final data = docs[i].data() as Map<String, dynamic>;
                  return _RoomCard(
                    roomId: docs[i].id,
                    data: data,
                  );
                },
              ),
            );
          },
        ),
      ],
    );
  }

  Query<Map<String, dynamic>> _buildQuery() {
    Query<Map<String, dynamic>> q = FirebaseFirestore.instance
        .collection('rooms')
        .where('isPublic', isEqualTo: true)
        .orderBy('participantCount', descending: true);

    if (category != null) {
      q = q.where('category', isEqualTo: category);
    }

    return q;
  }
}

class _RoomCard extends StatelessWidget {
  final String roomId;
  final Map<String, dynamic> data;

  const _RoomCard({required this.roomId, required this.data});

  @override
  Widget build(BuildContext context) {
    final name = data['name'] as String? ?? 'Untitled Room';
    final count = data['participantCount'] as int? ?? 0;
    final category = data['category'] as String? ?? '';
    final coverUrl = data['coverImageUrl'] as String?;

    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, AppRoutes.room,
          arguments: roomId),
      child: Container(
        width: 150,
        decoration: BoxDecoration(
          color: DesignColors.surfaceLight,
          borderRadius: BorderRadius.circular(14),
          image: coverUrl != null && coverUrl.isNotEmpty
              ? DecorationImage(
                  image: NetworkImage(coverUrl),
                  fit: BoxFit.cover,
                  colorFilter: ColorFilter.mode(
                    Colors.black.withValues(alpha: 0.45),
                    BlendMode.darken,
                  ),
                )
              : null,
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Live badge
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFFF4D8B).withValues(alpha: 0.85),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  '● LIVE',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const Spacer(),
              Text(
                name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.group, size: 12, color: Colors.white60),
                  const SizedBox(width: 4),
                  Text(
                    '$count',
                    style: const TextStyle(
                        color: Colors.white60, fontSize: 11),
                  ),
                  if (category.isNotEmpty) ...[
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        category,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: DesignColors.accent,
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
