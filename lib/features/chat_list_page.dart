import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../models/chat_room.dart';
import '../shared/models/user_profile.dart';
import '../providers/chat_controller.dart';
import '../providers/profile_controller.dart';
import 'chat_room_page.dart';

class ChatListPage extends ConsumerWidget {
  const ChatListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final chatRoomsAsync = ref.watch(chatRoomsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Messages'),
        actions: [
          Semantics(
            label: 'Search Chats',
            button: true,
            child: IconButton(
              key: const Key('searchChatsButton'),
              icon: const Icon(Icons.search),
              onPressed: () => ChatListPage._showSearchDialog(context, ref),
            ),
          ),
        ],
      ),
      body: chatRoomsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Error loading chats: $error'),
              ElevatedButton(
                onPressed: () => ref.invalidate(chatRoomsProvider),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
        data: (chatRooms) => chatRooms.isEmpty
            ? const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.chat_bubble_outline, size: 64, color: Colors.grey),
                    SizedBox(height: 16),
                    Text(
                      'No conversations yet',
                      style: TextStyle(fontSize: 18, color: Colors.grey),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Start chatting with someone!',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              )
            : RefreshIndicator(
                onRefresh: () async {
                  ref.invalidate(chatRoomsProvider);
                },
                child: ListView.builder(
                  itemCount: chatRooms.length,
                  itemBuilder: (context, index) {
                    final room = chatRooms[index];
                    return ChatRoomListItem(
                      chatRoom: room,
                      onTap: () => _navigateToChatRoom(context, ref, room),
                    );
                  },
                ),
              ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showNewChatDialog(context, ref),
        child: const Icon(Icons.message),
      ),
    );
  }

  void _navigateToChatRoom(BuildContext context, WidgetRef ref, ChatRoom room) {
    // Mark messages as read when entering chat
    ref.read(chatActionsProvider).markMessagesAsRead(room.id);

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatRoomPage(chatRoom: room),
      ),
    );
  }

  void _showNewChatDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => const NewChatDialog(),
    );
  }

  static void _showSearchDialog(BuildContext context, WidgetRef ref) {
    final searchController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Search Chats & Users'),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: searchController,
                autofocus: true,
                decoration: const InputDecoration(
                  hintText: 'Search by name or username...',
                  prefixIcon: Icon(Icons.search),
                  border: OutlineInputBorder(),
                ),
                onChanged: (value) {
                  // Trigger search - you can implement real-time search here
                },
              ),
              const SizedBox(height: 16),
              // TODO: Add search results list here
              // You can query Firestore for users/chats matching the search term
              const Text(
                'Enter a name to search',
                style: TextStyle(color: Colors.grey),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }
}

class ChatRoomListItem extends ConsumerWidget {
  final ChatRoom chatRoom;
  final VoidCallback onTap;

  const ChatRoomListItem({
    super.key,
    required this.chatRoom,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUserId = ref.watch(currentUserProfileProvider).value?.id ?? '';
    final otherUserId = chatRoom.participants.firstWhere((id) => id != currentUserId);
    final otherUserAsync = ref.watch(userProfileProvider(otherUserId));

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: Theme.of(context).primaryColor.withValues(alpha: 0.1),
        child: otherUserAsync.when(
          data: (user) => user?.photos.isNotEmpty == true
              ? ClipOval(
                  child: Image.network(
                    user?.photos.first ?? '',
                    width: 40,
                    height: 40,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => const Icon(Icons.person),
                  ),
                )
              : Text(user?.displayName?.isNotEmpty == true && user?.displayName != null
                  ? user!.displayName![0].toUpperCase()
                  : '?'),
          loading: () => const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          error: (error, stack) => const Icon(Icons.error),
        ),
      ),
      title: otherUserAsync.when(
        data: (user) => Text(user?.displayName ?? 'Unknown User'),
        loading: () => const Text('Loading...'),
        error: (error, stack) => const Text('Error loading user'),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            chatRoom.lastMessage.isEmpty ? 'No messages yet' : chatRoom.lastMessage,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            DateFormat('MMM dd, HH:mm').format(chatRoom.lastMessageTime.toLocal()),
            style: TextStyle(
              fontSize: 12,
              color: Theme.of(context).textTheme.bodySmall?.color,
            ),
          ),
        ],
      ),
      trailing: chatRoom.unreadCounts[currentUserId] != null && chatRoom.unreadCounts[currentUserId]! > 0
          ? Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor,
                shape: BoxShape.circle,
              ),
              child: Text(
                chatRoom.unreadCounts[currentUserId].toString(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            )
          : null,
      onTap: onTap,
    );
  }
}

class NewChatDialog extends ConsumerStatefulWidget {
  const NewChatDialog({super.key});

  @override
  ConsumerState<NewChatDialog> createState() => _NewChatDialogState();
}

class _NewChatDialogState extends ConsumerState<NewChatDialog> {
  final _searchController = TextEditingController();
  List<UserProfile> _searchResults = [];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _searchUsers(String query) async {
    if (query.trim().isEmpty) {
      setState(() => _searchResults = []);
      return;
    }

    // TODO: Implement user search functionality
    // For now, just show a placeholder
    setState(() => _searchResults = []);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Start New Chat'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _searchController,
            decoration: const InputDecoration(
              labelText: 'Search users',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.search),
            ),
            onChanged: _searchUsers,
          ),
          const SizedBox(height: 16),
          if (_searchResults.isNotEmpty)
            SizedBox(
              height: 200,
              child: ListView.builder(
                itemCount: _searchResults.length,
                itemBuilder: (context, index) {
                  final user = _searchResults[index];
                  return ListTile(
                    leading: CircleAvatar(
                      child: Text(user.displayName?.isNotEmpty == true ? user.displayName![0].toUpperCase() : '?'),
                    ),
                    title: Text(user.displayName ?? 'Unknown User'),
                    subtitle: Text(user.bio ?? ''),
                    onTap: () async {
                      final navigator = Navigator.of(context);
                      final messenger = ScaffoldMessenger.of(context);
                      try {
                        final chatActions = ref.read(chatActionsProvider);
                        final room = await chatActions.getOrCreateChatRoom(user.id);
                        if (mounted) {
                          navigator.pop(); // Close dialog
                          navigator.push(
                            MaterialPageRoute(
                              builder: (context) => ChatRoomPage(chatRoom: room),
                            ),
                          );
                        }
                      } catch (e) {
                        if (mounted) {
                          messenger.showSnackBar(
                            SnackBar(content: Text('Failed to start chat: $e')),
                          );
                        }
                      }
                    },
                  );
                },
              ),
            )
          else if (_searchController.text.isNotEmpty)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text('No users found'),
            ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
      ],
    );
  }
}
