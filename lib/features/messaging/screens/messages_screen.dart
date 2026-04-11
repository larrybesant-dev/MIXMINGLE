import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/conversation_model.dart';
import '../providers/messaging_provider.dart';
import '../../../core/layout/app_layout.dart';
import '../../../core/theme.dart';
import '../../../shared/widgets/app_page_scaffold.dart';
import '../../../shared/widgets/async_state_view.dart';

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

  void _showRequestsSheet(AsyncValue<List<Conversation>> requestsAsync) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: VelvetNoir.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _MessageRequestsSheet(
        requestsAsync: requestsAsync,
        userId: widget.userId,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final conversationsAsync =
        ref.watch(conversationsStreamProvider(widget.userId));
    final requestsAsync = ref.watch(requestsStreamProvider(widget.userId));
    final requestCount = requestsAsync.valueOrNull?.length ?? 0;
    final conversations = conversationsAsync.valueOrNull ?? const <Conversation>[];
    final unreadCount = _filterUnread(conversations).length;
    final groupCount = _filterGroups(conversations).length;

    return AppPageScaffold(
      appBar: AppBar(
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Messages',
              style: GoogleFonts.playfairDisplay(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: VelvetNoir.onSurface,
              ),
            ),
            Text(
              'Private chats, group energy, and request triage.',
              style: GoogleFonts.raleway(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: VelvetNoir.onSurfaceVariant,
              ),
            ),
          ],
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
            onPressed: () => _showRequestsSheet(requestsAsync),
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
          Padding(
            padding: EdgeInsets.fromLTRB(
              context.pageHorizontalPadding,
              12,
              context.pageHorizontalPadding,
              8,
            ),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    VelvetNoir.surfaceHigh.withValues(alpha: 0.92),
                    VelvetNoir.surfaceContainer.withValues(alpha: 0.88),
                  ],
                ),
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                  color: VelvetNoir.primary.withValues(alpha: 0.16),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: _MailboxStat(
                      label: 'Unread',
                      value: '$unreadCount',
                      accent: VelvetNoir.primary,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _MailboxStat(
                      label: 'Groups',
                      value: '$groupCount',
                      accent: VelvetNoir.secondaryBright,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _MailboxStat(
                      label: 'Requests',
                      value: '$requestCount',
                      accent: VelvetNoir.liveGlow,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(
              context.pageHorizontalPadding,
              12,
              context.pageHorizontalPadding,
              8,
            ),
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
              padding: EdgeInsets.fromLTRB(
                context.pageHorizontalPadding,
                0,
                context.pageHorizontalPadding,
                8,
              ),
              child: InkWell(
                onTap: () => _showRequestsSheet(requestsAsync),
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

          Expanded(
            child: AppAsyncValueView<List<Conversation>>(
              value: conversationsAsync,
              fallbackContext: 'conversations',
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
                    conversations: _applySearch(_filterUnread(conversations)),
                    userId: widget.userId,
                    emptyMessage: 'No unread messages',
                  ),
                  _ConversationsList(
                    conversations: _applySearch(_filterGroups(conversations)),
                    userId: widget.userId,
                    emptyMessage: 'No group chats yet',
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MessageRequestsSheet extends ConsumerWidget {
  const _MessageRequestsSheet({
    required this.requestsAsync,
    required this.userId,
  });

  final AsyncValue<List<Conversation>> requestsAsync;
  final String userId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SafeArea(
      top: false,
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.62,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
              child: Row(
                children: [
                  Text(
                    'Message Requests',
                    style: GoogleFonts.playfairDisplay(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: VelvetNoir.onSurface,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close,
                        color: VelvetNoir.onSurfaceVariant),
                  ),
                ],
              ),
            ),
            Divider(
              height: 1,
              color: VelvetNoir.outlineVariant.withValues(alpha: 0.3),
            ),
            Expanded(
              child: AppAsyncValueView<List<Conversation>>(
                value: requestsAsync,
                fallbackContext: 'message requests',
                isEmpty: (requests) => requests.isEmpty,
                empty: const AppEmptyView(
                  icon: Icons.mark_email_read_outlined,
                  title: 'No pending message requests.',
                ),
                data: (requests) {
                  return ListView.separated(
                    itemCount: requests.length,
                    separatorBuilder: (_, _) => Divider(
                      height: 1,
                      indent: 72,
                      color: VelvetNoir.outlineVariant.withValues(alpha: 0.2),
                    ),
                    itemBuilder: (context, index) {
                      final conversation = requests[index];
                      final displayName = conversation.getDisplayName(userId);
                      return ListTile(
                        onTap: () {
                          Navigator.of(context).pop();
                          GoRouter.of(context)
                              .push('/messages/${conversation.id}');
                        },
                        leading: CircleAvatar(
                          backgroundColor: VelvetNoir.surfaceHigh,
                          child: Text(
                            displayName.isNotEmpty
                                ? displayName[0].toUpperCase()
                                : '?',
                            style: const TextStyle(color: VelvetNoir.primary),
                          ),
                        ),
                        title: Text(
                          displayName,
                          style: const TextStyle(color: VelvetNoir.onSurface),
                        ),
                        subtitle: Text(
                          conversation.lastMessagePreview ??
                              'New message request',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: VelvetNoir.onSurfaceVariant,
                          ),
                        ),
                        trailing: TextButton(
                          onPressed: () async {
                            await ref
                                .read(messagingControllerProvider)
                                .acceptMessageRequest(
                                  conversationId: conversation.id,
                                );
                            if (context.mounted) {
                              Navigator.of(context).pop();
                              GoRouter.of(context)
                                  .push('/messages/${conversation.id}');
                            }
                          },
                          style: TextButton.styleFrom(
                            foregroundColor: VelvetNoir.primary,
                          ),
                          child: const Text('Accept'),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
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
        child: Container(
          width: 320,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: VelvetNoir.surfaceHigh.withValues(alpha: 0.74),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: VelvetNoir.primary.withValues(alpha: 0.12),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
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
        ),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      itemCount: conversations.length,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
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
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(1),
          child: Ink(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: unread
                  ? LinearGradient(
                      colors: [
                        VelvetNoir.primary.withValues(alpha: 0.18),
                        VelvetNoir.secondary.withValues(alpha: 0.10),
                      ],
                    )
                  : null,
              color: unread
                  ? null
                  : VelvetNoir.surfaceHigh.withValues(alpha: 0.78),
            ),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(19),
                color: unread
                    ? VelvetNoir.surfaceHigh.withValues(alpha: 0.92)
                    : VelvetNoir.surfaceHigh.withValues(alpha: 0.82),
                border: Border.all(
                  color: unread
                      ? VelvetNoir.primary.withValues(alpha: 0.20)
                      : VelvetNoir.outlineVariant.withValues(alpha: 0.28),
                ),
              ),
              child: Row(
                children: [
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      CircleAvatar(
                        radius: 28,
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
                          right: -1,
                          top: -1,
                          child: Container(
                            width: 16,
                            height: 16,
                            decoration: BoxDecoration(
                              color: VelvetNoir.secondary,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: VelvetNoir.surface,
                                width: 2,
                              ),
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
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                displayName,
                                style: TextStyle(
                                  fontWeight:
                                      unread ? FontWeight.w700 : FontWeight.w600,
                                  fontSize: 15,
                                  color: VelvetNoir.onSurface,
                                ),
                              ),
                            ),
                            if (unread)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: VelvetNoir.primary.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: const Text(
                                  'NEW',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    color: VelvetNoir.primary,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 4),
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

class _MailboxStat extends StatelessWidget {
  const _MailboxStat({
    required this.label,
    required this.value,
    required this.accent,
  });

  final String label;
  final String value;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      decoration: BoxDecoration(
        color: VelvetNoir.surface.withValues(alpha: 0.42),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: accent.withValues(alpha: 0.22)),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: GoogleFonts.playfairDisplay(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: VelvetNoir.onSurface,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: GoogleFonts.raleway(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: VelvetNoir.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
