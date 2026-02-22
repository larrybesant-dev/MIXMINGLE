import 'package:flutter/material.dart';
import '../services/block_service.dart';

class BlockedUsersScreen extends StatefulWidget {
  final String userId;

  const BlockedUsersScreen({
    super.key,
    required this.userId,
  });

  @override
  State<BlockedUsersScreen> createState() => _BlockedUsersScreenState();
}

class _BlockedUsersScreenState extends State<BlockedUsersScreen> {
  final BlockService _blockService = BlockService();

  Future<void> _unblockUser(String blockedUserId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Unblock User'),
        content: const Text('Are you sure you want to unblock this user?'),
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

    if (confirmed == true) {
      try {
        await _blockService.unblockUser(
          userId: widget.userId,
          blockedUserId: blockedUserId,
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('User unblocked')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to unblock user: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Blocked Users'),
      ),
      body: StreamBuilder<List<String>>(
        stream: _blockService.streamBlockedUsers(widget.userId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text('Error: ${snapshot.error}'),
            );
          }

          final blockedUserIds = snapshot.data ?? [];

          if (blockedUserIds.isEmpty) {
            return const Center(
              child: Text('No blocked users'),
            );
          }

          return ListView.builder(
            itemCount: blockedUserIds.length,
            itemBuilder: (context, index) {
              final blockedUserId = blockedUserIds[index];
              return ListTile(
                leading: const CircleAvatar(
                  child: Icon(Icons.person),
                ),
                title: Text(blockedUserId),
                trailing: TextButton(
                  onPressed: () => _unblockUser(blockedUserId),
                  child: const Text('Unblock'),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
