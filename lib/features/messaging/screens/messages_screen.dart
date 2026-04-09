import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/conversation_model.dart';
import '../providers/messaging_provider.dart';
import '../../../core/theme.dart';
import '../../../widgets/mixvy_drawer.dart';

class MessagesScreen extends ConsumerStatefulWidget {
  final String userId;
  final String username;

  const MessagesScreen({
    super.key,
    required this.userId,
    required this.username,
  });

  @override
  ConsumerState<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends ConsumerState<MessagesScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _searchController.addListener(() {
      setState(() => _query = _searchController.text.toLowerCase());
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  List<Conversation> _filterAll(List<Conversation> convs) =>
      convs.where((c) => c.status == 'active').toList();

  List<Conversation> _filterUnread(List<Conversation> convs) => convs
      .where((c) => c.status == 'active' && c.hasUnreadMessages(widget.userId))
      .toList();

  List<Conversation> _filterGroups(List<Conversation> convs) =>
      convs.where((c) => c.type == 'group').toList();

  List<Conversation> _applySearch(List<Conversation> convs) {
    if (_query.isEmpty) return convs;
    return convs.where((c) {
      final name = c.getDisplayName(widget.userId).toLowerCase();
      final preview = (c.lastMessagePreview ?? '').toLowerCase();
      return name.contains(_query) || preview.contains(_query);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final conversationsAsync =
        ref.watch(conversationsStreamProvider(widget.userId));
    final requestsAsync = ref.watch(requestsStreamProvider(widget.userId));
    final requestCount = requestsAsync.valueOrNull?.length ?? 0;

    return Scaffold(
      backgroundColor: VelvetNoir.surface,
      drawer: const MixVyDrawer(),
      appBar: AppBar(
        backgroundColor: VelvetNoir.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Messages',
          style: GoogleFonts.playfairDisplay(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: VelvetNoir.onSurface,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline,
                color: VelvetNoir.onSurface),
            tooltip: 'New message',
            onPressed: () => GoRouter.of(context).push('/messages/new'),
          ),
          IconButton(
            icon: const Icon(Icons.more_horiz_rounded,
                color: VelvetNoir.onSurface),
            onPressed: () {},
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
              height: 1,
              color: VelvetNoir.primary.withValues(alpha: 0.12)),
        ),
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Container(
              height: 40,
              decoration: BoxDecoration(
                color: VelvetNoir.surfaceHigh,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(
                  color: VelvetNoir.outlineVariant.withValues(alpha: 0.4),
                ),
              ),
              child: TextField(
                controller: _searchController,
                style: const TextStyle(
                    color: VelvetNoir.onSurface, fontSize: 13),
                decoration: InputDecoration(
                  hintText: 'Search messages…',
                  hintStyle: const TextStyle(
                      color: VelvetNoir.onSurfaceVariant, fontSize: 13),
                  prefixIcon: const Icon(Icons.search,
                      color: VelvetNoir.onSurfaceVariant, size: 18),
                  suffixIcon: _query.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.close,
                              size: 16,
                              color: VelvetNoir.onSurfaceVariant),
                          onPressed: _searchController.clear,
                          padding: EdgeInsets.zero,
                        )
                      : null,
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding:
                      const EdgeInsets.symmetric(vertical: 10),
                ),
              ),
            ),
          ),

          // Incoming requests banner
          if (requestCount > 0)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: InkWell(
                onTap: () {},
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: VelvetNoir.secondary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: VelvetNoir.secondary.withValues(alpha: 0.35),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.mark_email_unread_outlined,
                          color: VelvetNoir.secondaryBright, size: 18),
                      const SizedBox(width: 8),
                      Text(
                        '$requestCount message request${requestCount > 1 ? 's' : ''}',
                        style: const TextStyle(
                          color: VelvetNoir.onSurface,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const Spacer(),
                      const Icon(Icons.chevron_right_rounded,
                          color: VelvetNoir.onSurfaceVariant, size: 18),
                    ],
                  ),
                ),
              ),
            ),

          // Tabs: All | Unread | Groups
          TabBar(
            controller: _tabController,
            indicatorColor: VelvetNoir.primary,
            indicatorWeight: 2,
            labelColor: VelvetNoir.primary,
            unselectedLabelColor: VelvetNoir.onSurfaceVariant,
            labelStyle:
                GoogleFonts.raleway(fontSize: 13, fontWeight: FontWeight.w600),
            unselectedLabelStyle:
                GoogleFonts.raleway(fontSize: 13, fontWeight: FontWeight.w500),
            dividerColor: VelvetNoir.outlineVariant.withValues(alpha: 0.3),
            tabs: const [
              Tab(text: 'All'),
              Tab(text: 'Unread'),
              Tab(text: 'Groups'),
            ],
          ),

          // Tab views
          Expanded(
            child: conversationsAsync.when(
              data: (conversations) => TabBarView(
                controller: _tabController,
                children: [
                  _ConversationsList(
                    conversations: _applySearch(_filterAll(conversations)),
                    userId: widget.userId,
                    emptyMessage: _query.isNotEmpty
                        ? 'No results for "$_query"'
                        : 'No conversations yet',
                  ),
                  _ConversationsList(
                    conversations:
                        _applySearch(_filterUnread(conversations)),
                    userId: widget.userId,
                    emptyMessage: 'No unread messages',
                  ),
                  _ConversationsList(
                    conversations:
                        _applySearch(_filterGroups(conversations)),
                    userId: widget.userId,
                    emptyMessage: 'No group chats yet',
                  ),
                ],
              ),
              loading: () => TabBarView(
                controller: _tabController,
                children: List.generate(
                  3,
                  (_) => const Center(
                    child:
                        CircularProgressIndicator(color: VelvetNoir.primary),
                  ),
                ),
              ),
              error: (err, _) => TabBarView(
                controller: _tabController,
                children: List.generate(
                  3,
                  (_) => Center(
                    child: Text('Error: $err',
                        style: const TextStyle(
                            color: VelvetNoir.onSurfaceVariant)),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Conversations list ─────────────────────────────────────────────────────

class _ConversationsList extends StatelessWidget {
  const _ConversationsList({
    required this.conversations,
    required this.userId,
    required this.emptyMessage,
  });

  final List<Conversation> conversations;
  final String userId;
  final String emptyMessage;

  @override
  Widget build(BuildContext context) {
    if (conversations.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.chat_bubble_outline,
                size: 56,
                color: VelvetNoir.primary.withValues(alpha: 0.35)),
            const SizedBox(height: 14),
            Text(emptyMessage,
                style: const TextStyle(
                    color: VelvetNoir.onSurfaceVariant, fontSize: 14)),
            const SizedBox(height: 10),
            TextButton(
              onPressed: () => GoRouter.of(context).push('/messages/new'),
              child: const Text('Start a conversation',
                  style: TextStyle(color: VelvetNoir.primary)),
            ),
          ],
        ),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.only(top: 8, bottom: 24),
      itemCount: conversations.length,
      separatorBuilder: (_, _) => Divider(
        height: 1,
        indent: 72,
        color: VelvetNoir.outlineVariant.withValues(alpha: 0.2),
      ),
      itemBuilder: (context, index) => _ConversationTile(
        conversation: conversations[index],
        userId: userId,
      ),
    );
  }
}

// ── Conversation tile ──────────────────────────────────────────────────────

class _ConversationTile extends StatelessWidget {
  const _ConversationTile({
    required this.conversation,
    required this.userId,
  });

  final Conversation conversation;
  final String userId;

  @override
  Widget build(BuildContext context) {
    final unread = conversation.hasUnreadMessages(userId);
    final displayName = conversation.getDisplayName(userId);
    final avatarUrl = conversation.groupAvatarUrl;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () =>
            GoRouter.of(context).push('/messages/${conversation.id}'),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  CircleAvatar(
                    radius: 26,
                    backgroundColor: VelvetNoir.primaryDim,
                    backgroundImage: avatarUrl != null
                        ? CachedNetworkImageProvider(avatarUrl)
                        : null,
                    child: avatarUrl == null
                        ? Text(
                            displayName.isNotEmpty
                                ? displayName[0].toUpperCase()
                                : '?',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          )
                        : null,
                  ),
                  if (unread)
                    Positioned(
                      right: -2,
                      top: -2,
                      child: Container(
                        width: 14,
                        height: 14,
                        decoration: const BoxDecoration(
                          color: VelvetNoir.secondary,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      displayName,
                      style: TextStyle(
                        fontWeight:
                            unread ? FontWeight.w700 : FontWeight.w500,
                        fontSize: 15,
                        color: VelvetNoir.onSurface,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      conversation.lastMessagePreview ?? 'No messages yet',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13,
                        color: unread
                            ? VelvetNoir.onSurface
                            : VelvetNoir.onSurfaceVariant,
                        fontWeight:
                            unread ? FontWeight.w500 : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                _formatTime(conversation.lastMessageAt),
                style: const TextStyle(
                  fontSize: 12,
                  color: VelvetNoir.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatTime(DateTime? dateTime) {
    if (dateTime == null) return '';
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    if (difference.inMinutes < 1) return 'now';
    if (difference.inHours < 1) return '${difference.inMinutes}m ago';
    if (difference.inDays < 1) return '${difference.inHours}h ago';
    if (difference.inDays < 7) return '${difference.inDays}d ago';
    return '${dateTime.month}/${dateTime.day}';
  }
}
