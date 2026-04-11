import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/layout/app_layout.dart';
import '../../../core/theme.dart';
import '../../../shared/widgets/async_state_view.dart';
import '../models/conversation_model.dart';
import '../providers/messaging_provider.dart';

class MessagesPaneView extends ConsumerStatefulWidget {
  const MessagesPaneView({
    super.key,
    required this.userId,
    required this.username,
    this.showHeader = true,
  });

  final String userId;
  final String username;
  final bool showHeader;

  @override
  ConsumerState<MessagesPaneView> createState() => _MessagesPaneViewState();
}

class _MessagesPaneViewState extends ConsumerState<MessagesPaneView>
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
      builder: (_) => MessageRequestsSheet(
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

    return Column(
      children: [
        if (widget.showHeader)
          Padding(
            padding: EdgeInsets.fromLTRB(
              context.pageHorizontalPadding,
              24,
              context.pageHorizontalPadding,
              16,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Inbox',
                        style: GoogleFonts.playfairDisplay(
                          fontSize: 32,
                          fontWeight: FontWeight.w700,
                          color: VelvetNoir.onSurface,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Desktop keeps messages inside the center pane.',
                        style: GoogleFonts.raleway(
                          color: VelvetNoir.onSurfaceVariant,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                FilledButton.icon(
                  onPressed: () => GoRouter.of(context).push('/messages/new'),
                  icon: const Icon(Icons.add_comment_outlined),
                  label: const Text('New message'),
                ),
              ],
            ),
          ),
        Padding(
          padding: EdgeInsets.fromLTRB(
            context.pageHorizontalPadding,
            8,
            context.pageHorizontalPadding,
            8,
          ),
          child: Container(
            height: 46,
            decoration: BoxDecoration(
              color: VelvetNoir.surfaceHigh.withValues(alpha: 0.92),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: VelvetNoir.outlineVariant.withValues(alpha: 0.28),
              ),
            ),
            child: TextField(
              controller: _searchController,
              style: GoogleFonts.raleway(
                color: VelvetNoir.onSurface,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
              decoration: InputDecoration(
                hintText: 'Search conversations',
                hintStyle: GoogleFonts.raleway(
                  color: VelvetNoir.onSurfaceVariant,
                  fontSize: 14,
                ),
                prefixIcon: const Icon(
                  Icons.search_rounded,
                  color: VelvetNoir.onSurfaceVariant,
                  size: 20,
                ),
                suffixIcon: _query.isNotEmpty
                    ? IconButton(
                        icon: const Icon(
                          Icons.close_rounded,
                          size: 18,
                          color: VelvetNoir.onSurfaceVariant,
                        ),
                        onPressed: _searchController.clear,
                        padding: EdgeInsets.zero,
                      )
                    : null,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ),
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
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: VelvetNoir.secondary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: VelvetNoir.secondary.withValues(alpha: 0.22),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.mark_email_unread_outlined,
                        color: VelvetNoir.secondaryBright, size: 18),
                    const SizedBox(width: 8),
                    Text(
                      '$requestCount request${requestCount > 1 ? 's' : ''}',
                      style: GoogleFonts.raleway(
                        color: VelvetNoir.onSurface,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Review pending conversations',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.raleway(
                          color: VelvetNoir.onSurfaceVariant,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
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
        Padding(
          padding: EdgeInsets.fromLTRB(
            context.pageHorizontalPadding,
            0,
            context.pageHorizontalPadding,
            8,
          ),
          child: Container(
            height: 42,
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: VelvetNoir.surfaceHigh.withValues(alpha: 0.78),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: VelvetNoir.outlineVariant.withValues(alpha: 0.24),
              ),
            ),
            child: TabBar(
              controller: _tabController,
              indicator: BoxDecoration(
                color: VelvetNoir.surfaceContainer,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: VelvetNoir.primary.withValues(alpha: 0.22),
                ),
              ),
              indicatorSize: TabBarIndicatorSize.tab,
              dividerColor: Colors.transparent,
              labelColor: VelvetNoir.onSurface,
              unselectedLabelColor: VelvetNoir.onSurfaceVariant,
              labelStyle: GoogleFonts.raleway(
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
              unselectedLabelStyle: GoogleFonts.raleway(
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
              splashBorderRadius: BorderRadius.circular(12),
              tabs: const [
                Tab(text: 'All'),
                Tab(text: 'Unread'),
                Tab(text: 'Groups'),
              ],
            ),
          ),
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
    );
  }
}

class MessageRequestsSheet extends ConsumerWidget {
  const MessageRequestsSheet({
    super.key,
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
                          GoRouter.of(context).push('/messages/${conversation.id}');
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
                          conversation.lastMessagePreview ?? 'New message request',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: VelvetNoir.onSurfaceVariant,
                          ),
                        ),
                        trailing: TextButton(
                          onPressed: () async {
                            await ref.read(messagingControllerProvider).acceptMessageRequest(
                                  conversationId: conversation.id,
                                );
                            if (context.mounted) {
                              Navigator.of(context).pop();
                              GoRouter.of(context).push('/messages/${conversation.id}');
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
            color: VelvetNoir.surfaceHigh.withValues(alpha: 0.82),
            borderRadius: BorderRadius.circular(20),
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
              Text(
                emptyMessage,
                textAlign: TextAlign.center,
                style: GoogleFonts.raleway(
                  color: VelvetNoir.onSurfaceVariant,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 10),
              TextButton(
                onPressed: () => GoRouter.of(context).push('/messages/new'),
                child: Text(
                  'Start a conversation',
                  style: GoogleFonts.raleway(
                    color: VelvetNoir.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 24),
      itemCount: conversations.length,
      separatorBuilder: (_, _) => Divider(
        height: 1,
        indent: 84,
        endIndent: 16,
        color: VelvetNoir.outlineVariant.withValues(alpha: 0.22),
      ),
      itemBuilder: (context, index) => _ConversationTile(
        conversation: conversations[index],
        userId: userId,
      ),
    );
  }
}

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
    final previewText = conversation.lastMessagePreview ?? 'No messages yet';
    final isGroup = conversation.type == 'group';

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => GoRouter.of(context).push('/messages/${conversation.id}'),
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            color: unread
                ? VelvetNoir.surfaceHigh.withValues(alpha: 0.94)
                : Colors.transparent,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: isGroup
                        ? VelvetNoir.secondary.withValues(alpha: 0.18)
                        : VelvetNoir.primaryDim,
                    backgroundImage: avatarUrl != null
                        ? CachedNetworkImageProvider(avatarUrl)
                        : null,
                    child: avatarUrl == null
                        ? Text(
                            displayName.isNotEmpty
                                ? displayName[0].toUpperCase()
                                : '?',
                            style: GoogleFonts.raleway(
                              color: VelvetNoir.onSurface,
                              fontWeight: FontWeight.w800,
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
                        width: 14,
                        height: 14,
                        decoration: BoxDecoration(
                          color: VelvetNoir.primary,
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
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.raleway(
                              fontWeight:
                                  unread ? FontWeight.w800 : FontWeight.w700,
                              fontSize: 15,
                              color: VelvetNoir.onSurface,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          _formatTime(conversation.lastMessageAt),
                          style: GoogleFonts.raleway(
                            fontSize: 11,
                            fontWeight:
                                unread ? FontWeight.w700 : FontWeight.w500,
                            color: unread
                                ? VelvetNoir.primary
                                : VelvetNoir.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        if (isGroup)
                          Container(
                            margin: const EdgeInsets.only(right: 8),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 7,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color:
                                  VelvetNoir.secondary.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              'Group',
                              style: GoogleFonts.raleway(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: VelvetNoir.secondaryBright,
                              ),
                            ),
                          ),
                        Expanded(
                          child: Text(
                            previewText,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.raleway(
                              fontSize: 13,
                              height: 1.25,
                              color: unread
                                  ? VelvetNoir.onSurface
                                  : VelvetNoir.onSurfaceVariant,
                              fontWeight:
                                  unread ? FontWeight.w700 : FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
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