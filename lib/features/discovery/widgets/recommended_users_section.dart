import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/design_system/design_constants.dart';
import '../../../../core/routing/app_routes.dart';
import '../../../../shared/providers/auth_providers.dart';

/// Shows user suggestions based on matching interests/categories.
class RecommendedUsersSection extends ConsumerWidget {
  final String? category;

  const RecommendedUsersSection({super.key, this.category});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final myId = ref.watch(currentUserProvider).value?.id;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Icon(Icons.people_outline, color: Color(0xFF00E5CC), size: 20),
              SizedBox(width: 8),
              Text(
                'People You May Like',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        StreamBuilder<QuerySnapshot>(
          stream: _buildQuery(myId).limit(12).snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const SizedBox(
                height: 120,
                child: Center(
                  child: CircularProgressIndicator(color: DesignColors.accent),
                ),
              );
            }

            final docs = snapshot.data?.docs
                    .where((d) => d.id != myId)
                    .toList() ??
                [];

            if (docs.isEmpty) {
              return Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 20),
                child: Text(
                  'No suggestions at the moment',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.4),
                    fontSize: 14,
                  ),
                ),
              );
            }

            return ListView.separated(
              physics: const NeverScrollableScrollPhysics(),
              shrinkWrap: true,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: docs.length,
              separatorBuilder: (_, __) =>
                  const Divider(color: Colors.white10, height: 1),
              itemBuilder: (context, i) {
                final data = docs[i].data() as Map<String, dynamic>;
                return _UserTile(userId: docs[i].id, data: data);
              },
            );
          },
        ),
      ],
    );
  }

  Query<Map<String, dynamic>> _buildQuery(String? myId) {
    Query<Map<String, dynamic>> q = FirebaseFirestore.instance
        .collection('users')
        .orderBy('createdAt', descending: true);

    if (category != null) {
      q = q.where('interests', arrayContains: category);
    }

    return q;
  }
}

class _UserTile extends StatelessWidget {
  final String userId;
  final Map<String, dynamic> data;

  const _UserTile({required this.userId, required this.data});

  @override
  Widget build(BuildContext context) {
    final displayName = data['displayName'] as String? ??
        data['nickname'] as String? ??
        'User';
    final avatarUrl = data['photoURL'] as String? ??
        data['avatarUrl'] as String?;
    final bio = data['bio'] as String?;
    final interests = List<String>.from(data['interests'] ?? []);

    return ListTile(
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 0, vertical: 6),
      leading: CircleAvatar(
        radius: 24,
        backgroundImage:
            avatarUrl != null ? NetworkImage(avatarUrl) : null,
        backgroundColor: DesignColors.accent.withValues(alpha: 0.2),
        child: avatarUrl == null
            ? Text(
                displayName.isNotEmpty ? displayName[0].toUpperCase() : '?',
                style: const TextStyle(
                    color: DesignColors.accent,
                    fontWeight: FontWeight.bold),
              )
            : null,
      ),
      title: Text(
        displayName,
        style: const TextStyle(
            color: Colors.white, fontWeight: FontWeight.w600),
      ),
      subtitle: bio != null && bio.isNotEmpty
          ? Text(
              bio,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.5),
                  fontSize: 12),
            )
          : interests.isNotEmpty
              ? Text(
                  interests.take(3).join(' · '),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: DesignColors.accent,
                    fontSize: 11,
                  ),
                )
              : null,
      trailing: OutlinedButton(
        style: OutlinedButton.styleFrom(
          foregroundColor: const Color(0xFF00E5CC),
          side: const BorderSide(color: Color(0xFF00E5CC)),
          padding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          minimumSize: Size.zero,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        ),
        onPressed: () => Navigator.pushNamed(
          context,
          AppRoutes.userProfile,
          arguments: userId,
        ),
        child: const Text('View', style: TextStyle(fontSize: 12)),
      ),
      onTap: () => Navigator.pushNamed(
        context,
        AppRoutes.userProfile,
        arguments: userId,
      ),
    );
  }
}
