import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../shared/providers/all_providers.dart';
import '../../shared/providers/friend_request_provider.dart';
import '../../shared/widgets/async_value_view_enhanced.dart';
import 'package:mixmingle/core/routing/app_routes.dart';

/// Blocked users provider — reads from users/{uid}/blocked sub-collection
final blockedUsersProvider = StreamProvider<List<Map<String, dynamic>>>((ref) {
  final currentUser = ref.watch(currentUserProvider).value;
  if (currentUser == null) return Stream.value([]);

  return FirebaseFirestore.instance
      .collection('users')
      .doc(currentUser.id)
      .collection('blocked')
      .orderBy('blockedAt', descending: true)
      .snapshots()
      .asyncMap((snapshot) async {
    final List<Map<String, dynamic>> blockedUsers = [];

    for (final doc in snapshot.docs) {
      final blockedUserId = doc.id; // doc ID is the blocked user's UID
      final data = doc.data();

      try {
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(blockedUserId)
            .get();

        if (userDoc.exists) {
          blockedUsers.add({
            'id': blockedUserId,
            'displayName': userDoc.data()?['displayName'] ?? 'Unknown',
            'photoUrl': userDoc.data()?['photoUrl'] ?? userDoc.data()?['avatarUrl'],
            'blockedAt': (data['blockedAt'] as Timestamp?)?.toDate(),
          });
        }
      } catch (e) {
        // Skip if user fetch fails
      }
    }

    return blockedUsers;
  });
});

class BlockedUsersPage extends ConsumerStatefulWidget {
  const BlockedUsersPage({super.key});

  @override
  ConsumerState<BlockedUsersPage> createState() => _BlockedUsersPageState();
}

class _BlockedUsersPageState extends ConsumerState<BlockedUsersPage> {
  bool _isUnblocking = false;

  Future<void> _unblockUser(String blockedUserId, String displayName) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Unblock User'),
        content: Text('Are you sure you want to unblock $displayName?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Unblock'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _isUnblocking = true);

    try {
      await ref.read(friendServiceProvider).unblockUser(blockedUserId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$displayName unblocked successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to unblock user: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isUnblocking = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final blockedUsersAsync = ref.watch(blockedUsersProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Blocked Users'),
      ),
      body: AsyncValueViewEnhanced(
        value: blockedUsersAsync,
        data: (blockedUsers) {
          if (blockedUsers.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.block,
                    size: 80,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No Blocked Users',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: Colors.grey.shade600,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Users you block will appear here',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey.shade500,
                        ),
                  ),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: blockedUsers.length,
            separatorBuilder: (context, index) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final user = blockedUsers[index];
              final displayName = user['displayName'] as String;
              final photoUrl = user['photoUrl'] as String?;
              final blockedAt = user['blockedAt'] as DateTime?;
              return Card(
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundImage: photoUrl != null ? NetworkImage(photoUrl) : null,
                    child: photoUrl == null ? Text(displayName.substring(0, 1).toUpperCase()) : null,
                  ),
                  title: Text(displayName),
                  subtitle: blockedAt != null
                      ? Text(
                          'Blocked ${_formatDate(blockedAt)}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        )
                      : null,
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.person),
                        onPressed: () {
                          Navigator.of(context).pushNamed(
                            AppRoutes.userProfile,
                            arguments: {'userId': user['id']},
                          );
                        },
                        tooltip: 'View Profile',
                      ),
                      TextButton(
                        onPressed: _isUnblocking ? null : () => _unblockUser(user['id'], displayName),
                        child: const Text('Unblock'),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 365) {
      return '${(difference.inDays / 365).floor()} year${(difference.inDays / 365).floor() > 1 ? 's' : ''} ago';
    } else if (difference.inDays > 30) {
      return '${(difference.inDays / 30).floor()} month${(difference.inDays / 30).floor() > 1 ? 's' : ''} ago';
    } else if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays > 1 ? 's' : ''} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour${difference.inHours > 1 ? 's' : ''} ago';
    } else {
      return 'Recently';
    }
  }
}
