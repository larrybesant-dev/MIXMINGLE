import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/messaging_provider.dart';

class NewMessageScreen extends ConsumerStatefulWidget {
  final String userId;
  final String username;
  final String? avatarUrl;

  const NewMessageScreen({
    super.key,
    required this.userId,
    required this.username,
    this.avatarUrl,
  });

  @override
  ConsumerState<NewMessageScreen> createState() => _NewMessageScreenState();
}

class _NewMessageScreenState extends ConsumerState<NewMessageScreen> {
  late TextEditingController _searchController;
  List<Map<String, String>> _searchResults = [];
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _startConversation(
    String otherUserId,
    String otherUsername,
    String? otherAvatarUrl,
  ) async {
    try {
      final conversationId = await ref.read(messagingControllerProvider).createDirectConversation(
            userId1: widget.userId,
            user1Name: widget.username,
            user1AvatarUrl: widget.avatarUrl,
            userId2: otherUserId,
            user2Name: otherUsername,
            user2AvatarUrl: otherAvatarUrl,
          );

      if (!mounted) return;
      context.go('/messages/$conversationId');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error starting conversation: $e')),
      );
    }
  }

  Future<void> _searchUsers(String query) async {
    if (query.isEmpty) {
      setState(() {
        _searchResults = [];
      });
      return;
    }

    setState(() {
      _isSearching = true;
    });

    try {
      final normalized = query.trim();
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('username', isGreaterThanOrEqualTo: normalized)
          .where('username', isLessThanOrEqualTo: '$normalized\uf8ff')
          .limit(20)
          .get();

      final matches = snapshot.docs
          .where((doc) => doc.id != widget.userId)
          .map((doc) {
            final data = doc.data();
            final username = (data['username'] as String?)?.trim();
            return {
              'id': doc.id,
              'name': username == null || username.isEmpty ? doc.id : username,
              'avatar': (data['avatarUrl'] as String?)?.trim() ?? '',
            };
          })
          .toList(growable: false);

      if (!mounted) return;
      setState(() {
        _searchResults = matches;
        _isSearching = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isSearching = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Search failed: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('New Message'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search people...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              onChanged: _searchUsers,
            ),
          ),
          if (_isSearching)
            const Padding(
              padding: EdgeInsets.all(16),
              child: CircularProgressIndicator(),
            )
          else if (_searchResults.isEmpty && _searchController.text.isNotEmpty)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text('No users found'),
            )
          else
            Expanded(
              child: ListView.separated(
                itemCount: _searchResults.length,
                separatorBuilder: (_, _) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final user = _searchResults[index];
                  return ListTile(
                    leading: CircleAvatar(
                      child: Text(user['name']![0]),
                    ),
                    title: Text(user['name']!),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () => _startConversation(
                      user['id']!,
                      user['name']!,
                      user['avatar'],
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}
