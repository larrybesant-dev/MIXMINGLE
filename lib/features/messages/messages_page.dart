import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/providers.dart';
import '../../models/user.dart';
import '../../models/direct_message.dart';
import '../../shared/club_background.dart';
import '../../shared/glow_text.dart';
import '../../shared/neon_button.dart';
import 'chat_screen.dart';

class MessagesPage extends ConsumerStatefulWidget {
  const MessagesPage({super.key});

  @override
  ConsumerState<MessagesPage> createState() => _MessagesPageState();
}

class _MessagesPageState extends ConsumerState<MessagesPage> {
  bool _isSearching = false;
  String _searchQuery = '';

  // Advanced search filters
  DateTime? _startDate;
  DateTime? _endDate;
  String? _selectedConversationId;
  DirectMessageType? _selectedMessageType;
  bool _searchInMessages = false;

  // Message search results
  List<Map<String, dynamic>> _messageSearchResults = [];
  bool _isSearchingMessages = false;

  @override
  Widget build(BuildContext context) {
    final conversationsAsync = ref.watch(userConversationsProvider);
    final unreadCountAsync = ref.watch(totalUnreadMessagesProvider);

    return ClubBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: _isSearching
              ? TextField(
                  autofocus: true,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: _searchInMessages ? 'Search message content...' : 'Search conversations...',
                    hintStyle: const TextStyle(color: Colors.white54),
                    border: InputBorder.none,
                  ),
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value;
                    });
                    if (_searchInMessages && value.isNotEmpty) {
                      _searchMessages();
                    }
                  },
                )
              : Row(
                  children: [
                    const GlowText(
                      text: 'Messages',
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFFFD700),
                      glowColor: Color(0xFFFF4C4C),
                    ),
                    const SizedBox(width: 8),
                    unreadCountAsync.when(
                      data: (count) => count > 0
                          ? Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFF4C4C),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                count.toString(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            )
                          : const SizedBox.shrink(),
                      loading: () => const SizedBox.shrink(),
                      error: (error, stack) => const SizedBox.shrink(),
                    ),
                  ],
                ),
          actions: [
            if (_isSearching) ...[
              IconButton(
                key: const Key('messages-filter-btn'),
                icon: const Icon(Icons.filter_list),
                onPressed: () => _showAdvancedSearchDialog(),
              ),
            ],
            IconButton(
              key: const Key('messages-search-toggle-btn'),
              icon: Icon(_isSearching ? Icons.close : Icons.search),
              onPressed: () {
                setState(() {
                  if (_isSearching) {
                    _isSearching = false;
                    _searchQuery = '';
                    _clearAdvancedFilters();
                  } else {
                    _isSearching = true;
                  }
                });
              },
            ),
          ],
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
        body: _searchInMessages && _searchQuery.isNotEmpty
            ? _buildMessageSearchResults()
            : conversationsAsync.when(
                data: (conversations) {
                  // Filter conversations based on search query and advanced filters
                  final filteredConversations = conversations.where((conversation) {
                    final user = conversation['otherUser'] as User;
                    final lastMessageTime = conversation['lastMessageTime'] as DateTime?;

                    // Basic text search
                    bool matchesText = true;
                    if (_searchQuery.isNotEmpty) {
                      final displayName = (user.displayName ?? "").toLowerCase();
                      final username = user.username.toLowerCase();
                      final query = _searchQuery.toLowerCase();
                      matchesText = displayName.contains(query) || username.contains(query);
                    }

                    // Date range filter
                    bool matchesDate = true;
                    if (_startDate != null || _endDate != null) {
                      if (lastMessageTime == null) {
                        matchesDate = false;
                      } else {
                        if (_startDate != null && lastMessageTime.isBefore(_startDate!)) {
                          matchesDate = false;
                        }
                        if (_endDate != null && lastMessageTime.isAfter(_endDate!.add(const Duration(days: 1)))) {
                          matchesDate = false;
                        }
                      }
                    }

                    // Conversation filter (if searching within specific conversation)
                    bool matchesConversation = true;
                    if (_selectedConversationId != null) {
                      final conversationId = conversation['conversationId'] as String?;
                      matchesConversation = conversationId == _selectedConversationId;
                    }

                    return matchesText && matchesDate && matchesConversation;
                  }).toList();

                  if (filteredConversations.isEmpty && (_searchQuery.isNotEmpty || _hasActiveFilters())) {
                    return _buildEmptyState(isSearchResult: true);
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: filteredConversations.length,
                    itemBuilder: (context, index) {
                      final conversation = filteredConversations[index];
                      return ConversationTile(
                        key: Key('conversation-${conversation['conversationId'] ?? conversation['otherUser'].id}'),
                        conversation: conversation,
                        onTap: () => _openChat(conversation),
                      );
                    },
                  );
                },
                loading: () => const Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFF4C4C)),
                  ),
                ),
                error: (error, stack) => Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.error_outline,
                        size: 64,
                        color: Color(0xFFFF4C4C),
                      ),
                      const SizedBox(height: 16),
                      GlowText(
                        text: 'Failed to load messages',
                        fontSize: 18,
                        color: const Color(0xFFFF4C4C),
                      ),
                      const SizedBox(height: 16),
                      NeonButton(
                        key: const Key('messages-retry-btn'),
                        onPressed: () => ref.invalidate(userConversationsProvider),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildEmptyState({bool isSearchResult = false}) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isSearchResult ? Icons.search_off : Icons.message_outlined,
            size: 64,
            color: Colors.white.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 16),
          GlowText(
            text: isSearchResult ? 'No conversations found' : 'No messages yet',
            fontSize: 20,
            color: Colors.white70,
            glowColor: const Color(0xFFFF4C4C),
          ),
          const SizedBox(height: 8),
          Text(
            isSearchResult
                ? 'Try searching with a different name or username'
                : 'Start a conversation by following users and sending messages!',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.6),
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
          if (!isSearchResult) ...[
            const SizedBox(height: 24),
            NeonButton(
              key: const Key('discover-users-btn'),
              onPressed: () {
                // Navigate to discover users
                Navigator.of(context).pushNamed('/discover-users');
              },
              child: const Text('Discover Users'),
            ),
          ],
        ],
      ),
    );
  }

  void _openChat(Map<String, dynamic> conversation) {
    final otherUser = conversation['otherUser'] as User;
    final currentUser = ref.read(currentUserProvider).value;

    if (currentUser != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ChatScreen(
            currentUser: currentUser,
            otherUser: otherUser,
          ),
        ),
      );
    }
  }

  void _clearAdvancedFilters() {
    setState(() {
      _startDate = null;
      _endDate = null;
      _selectedConversationId = null;
      _selectedMessageType = null;
      _searchInMessages = false;
    });
  }

  bool _hasActiveFilters() {
    return _startDate != null ||
        _endDate != null ||
        _selectedConversationId != null ||
        _selectedMessageType != null ||
        _searchInMessages;
  }

  Future<void> _searchMessages() async {
    if (!_searchInMessages || _searchQuery.isEmpty) return;

    setState(() {
      _isSearchingMessages = true;
    });

    try {
      final messagingService = ref.read(messagingServiceProvider);
      final currentUser = ref.read(currentUserProvider).value;
      if (currentUser == null) return;

      final results = await messagingService.searchMessagesByContent(
        currentUser.id,
        _searchQuery,
        startDate: _startDate,
        endDate: _endDate,
        messageType: _selectedMessageType,
        limit: 100,
      );

      setState(() {
        _messageSearchResults = results;
        _isSearchingMessages = false;
      });
    } catch (e) {
      debugPrint('Error searching messages: $e');
      setState(() {
        _isSearchingMessages = false;
      });
    }
  }

  Widget _buildMessageSearchResults() {
    if (_isSearchingMessages) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFF4C4C)),
        ),
      );
    }

    if (_messageSearchResults.isEmpty) {
      return _buildEmptyState(isSearchResult: true);
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _messageSearchResults.length,
      itemBuilder: (context, index) {
        final result = _messageSearchResults[index];
        final message = result['message'] as DirectMessage;
        final conversation = result['conversation'] as Map<String, dynamic>;

        return MessageSearchResultTile(
          key: Key('message-search-${message.id}'),
          message: message,
          conversation: conversation,
          onTap: () => _openChat(conversation),
        );
      },
    );
  }

  void _showAdvancedSearchDialog() {
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          backgroundColor: const Color(0xFF1A1A1A),
          title: const GlowText(
            text: 'Advanced Search',
            fontSize: 20,
            color: Color(0xFFFFD700),
            glowColor: Color(0xFFFF4C4C),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Search in messages toggle
                SwitchListTile(
                  title: const Text(
                    'Search in message content',
                    style: TextStyle(color: Colors.white),
                  ),
                  subtitle: const Text(
                    'Search across all message text',
                    style: TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                  value: _searchInMessages,
                  onChanged: (value) {
                    setState(() => _searchInMessages = value);
                    this.setState(() => _searchInMessages = value);
                  },
                  activeThumbColor: const Color(0xFFFF4C4C),
                ),
                const SizedBox(height: 16),

                // Date range
                const Text(
                  'Date Range',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        key: const Key('messages-start-date-btn'),
                        onPressed: () async {
                          final date = await showDatePicker(
                            context: context,
                            initialDate: _startDate ?? DateTime.now(),
                            firstDate: DateTime(2020),
                            lastDate: DateTime.now(),
                            builder: (context, child) => Theme(
                              data: Theme.of(context).copyWith(
                                colorScheme: const ColorScheme.dark(
                                  primary: Color(0xFFFF4C4C),
                                  surface: Color(0xFF1A1A1A),
                                ),
                              ),
                              child: child!,
                            ),
                          );
                          if (date != null) {
                            setState(() => _startDate = date);
                            this.setState(() => _startDate = date);
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2A2A2A),
                          foregroundColor: Colors.white,
                        ),
                        child: Text(
                          _startDate != null
                              ? '${_startDate!.month}/${_startDate!.day}/${_startDate!.year}'
                              : 'Start Date',
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton(
                        key: const Key('messages-end-date-btn'),
                        onPressed: () async {
                          final date = await showDatePicker(
                            context: context,
                            initialDate: _endDate ?? DateTime.now(),
                            firstDate: DateTime(2020),
                            lastDate: DateTime.now(),
                            builder: (context, child) => Theme(
                              data: Theme.of(context).copyWith(
                                colorScheme: const ColorScheme.dark(
                                  primary: Color(0xFFFF4C4C),
                                  surface: Color(0xFF1A1A1A),
                                ),
                              ),
                              child: child!,
                            ),
                          );
                          if (date != null) {
                            setState(() => _endDate = date);
                            this.setState(() => _endDate = date);
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2A2A2A),
                          foregroundColor: Colors.white,
                        ),
                        child: Text(
                          _endDate != null ? '${_endDate!.month}/${_endDate!.day}/${_endDate!.year}' : 'End Date',
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Message type filter
                const Text(
                  'Message Type',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<DirectMessageType>(
                  initialValue: _selectedMessageType,
                  onChanged: (value) {
                    setState(() => _selectedMessageType = value);
                    this.setState(() => _selectedMessageType = value);
                  },
                  items: DirectMessageType.values.map((type) {
                    return DropdownMenuItem(
                      value: type,
                      child: Text(
                        type.name.toUpperCase(),
                        style: const TextStyle(color: Colors.white),
                      ),
                    );
                  }).toList(),
                  decoration: const InputDecoration(
                    filled: true,
                    fillColor: Color(0xFF2A2A2A),
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  dropdownColor: const Color(0xFF2A2A2A),
                  style: const TextStyle(color: Colors.white),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              key: const Key('messages-clear-filters-btn'),
              onPressed: () {
                _clearAdvancedFilters();
                Navigator.of(context).pop();
              },
              child: const Text(
                'Clear All',
                style: TextStyle(color: Color(0xFFFF4C4C)),
              ),
            ),
            TextButton(
              key: const Key('messages-cancel-filters-btn'),
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                'Cancel',
                style: TextStyle(color: Colors.white70),
              ),
            ),
            NeonButton(
              key: const Key('messages-apply-filters-btn'),
              child: const Text('Apply Filters'),
              onPressed: () {
                Navigator.of(context).pop();
                // Trigger search with filters
                setState(() {});
              },
            ),
          ],
        ),
      ),
    );
  }
}

class ConversationTile extends StatelessWidget {
  final Map<String, dynamic> conversation;
  final VoidCallback onTap;

  const ConversationTile({
    super.key,
    required this.conversation,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final otherUser = conversation['otherUser'] as User;
    final lastMessage = conversation['lastMessage'] as String?;
    final lastMessageTime = conversation['lastMessageTime'] as DateTime;
    final unreadCount = conversation['unreadCount'] as int;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: unreadCount > 0 ? const Color(0xFFFF4C4C) : Colors.white.withValues(alpha: 0.2),
            width: unreadCount > 0 ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            // Avatar
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: [Color(0xFFFF4C4C), Color(0xFFFFD700)],
                ),
                border: Border.all(
                  color: const Color(0xFFFFD700),
                  width: 2,
                ),
              ),
              child: otherUser.avatarUrl.isNotEmpty
                  ? ClipOval(
                      child: Image.network(
                        '${otherUser.avatarUrl}?t=${DateTime.now().millisecondsSinceEpoch}',
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => const Icon(
                          Icons.person,
                          color: Colors.white,
                          size: 25,
                        ),
                      ),
                    )
                  : const Icon(
                      Icons.person,
                      color: Colors.white,
                      size: 25,
                    ),
            ),

            const SizedBox(width: 12),

            // Conversation info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        otherUser.displayName ?? 'Unknown User',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (unreadCount > 0) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: const BoxDecoration(
                            color: Color(0xFFFF4C4C),
                            shape: BoxShape.circle,
                          ),
                          child: Text(
                            unreadCount.toString(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    lastMessage ?? 'No messages yet',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.7),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),

            // Timestamp
            Text(
              _formatTime(lastMessageTime),
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.5),
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);

    if (difference.inDays == 0) {
      return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${time.month}/${time.day}';
    }
  }
}

class MessageSearchResultTile extends StatelessWidget {
  final DirectMessage message;
  final Map<String, dynamic> conversation;
  final VoidCallback onTap;

  const MessageSearchResultTile({
    super.key,
    required this.message,
    required this.conversation,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final otherUser = conversation['otherUser'] as User;

    return Card(
      color: const Color(0xFF2A2A2A),
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        onTap: onTap,
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              colors: [Color(0xFFFF4C4C), Color(0xFFFFD700)],
            ),
          ),
          child: otherUser.avatarUrl.isNotEmpty
              ? ClipOval(
                  child: Image.network(
                    '${otherUser.avatarUrl}?t=${DateTime.now().millisecondsSinceEpoch}',
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => const Icon(
                      Icons.person,
                      color: Colors.white,
                    ),
                  ),
                )
              : const Icon(
                  Icons.person,
                  color: Colors.white,
                ),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                otherUser.displayName ?? 'Unknown User',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Text(
              _formatTime(message.timestamp),
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.5),
                fontSize: 12,
              ),
            ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              message.content,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              'Type: ${message.type.name.toUpperCase()}',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.6),
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);

    if (difference.inDays == 0) {
      return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${time.month}/${time.day}/${time.year}';
    }
  }
}
