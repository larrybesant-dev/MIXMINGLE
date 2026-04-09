import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../models/conversation_model.dart';
import '../providers/messaging_provider.dart';
import '../../../core/theme.dart';
import '../../../widgets/mixvy_drawer.dart';

class MessagesScreen extends ConsumerWidget {
  final String userId;
  final String username;

  const MessagesScreen({
    super.key,
    required this.userId,
    required this.username,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final conversationsAsync = ref.watch(conversationsStreamProvider(userId));
    final requestsAsync = ref.watch(requestsStreamProvider(userId));
    final requestCount = requestsAsync.valueOrNull?.length ?? 0;

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Messages'),
          actions: [
            IconButton(
              icon: const Icon(Icons.add_circle_outline),
              tooltip: 'New message',
              onPressed: () => context.push('/messages/new'),
            ),
          ],
          bottom: TabBar(
            tabs: [
              const Tab(text: 'Chats'),
              Tab(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('Requests'),
                    if (requestCount > 0) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.error,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          '$requestCount',
                          style: TextStyle(
                            fontSize: 11,
                            color: Theme.of(context).colorScheme.onError,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
        drawer: const MixVyDrawer(),
        body: TabBarView(
          children: [
            _ConversationsList(
              conversationsAsync: conversationsAsync,
              userId: userId,
              emptyMessage: 'No conversations yet',
            ),
            _RequestsList(
              requestsAsync: requestsAsync,
              userId: userId,
            ),
          ],
        ),
      ),
    );
  }
}

class _ConversationsList extends StatelessWidget {
  const _ConversationsList({
    required this.conversationsAsync,
    required this.userId,
    required this.emptyMessage,
  });

  final AsyncValue<List<Conversation>> conversationsAsync;
  final String userId;
  final String emptyMessage;

  @override
  Widget build(BuildContext context) {
    return conversationsAsync.when(
      data: (conversations) {
        if (conversations.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.chat_bubble_outline,
                  size: 64,
                  color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.5),
                ),
                const SizedBox(height: 16),
                Text(emptyMessage),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: () => GoRouter.of(context).push('/messages/new'),
                  child: const Text('Start a conversation'),
                ),
              ],
            ),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.symmetric(vertical: 8),
          itemCount: conversations.length,
          itemBuilder: (context, index) {
            final conversation = conversations[index];
            return _ConversationTile(conversation: conversation, userId: userId);
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, _) => Center(child: Text('Error: $err')),
    );
  }
}

class _RequestsList extends ConsumerWidget {
  const _RequestsList({
    required this.requestsAsync,
    required this.userId,
  });

  final AsyncValue<List<Conversation>> requestsAsync;
  final String userId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return requestsAsync.when(
      data: (requests) {
        if (requests.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.mark_email_unread_outlined,
                  size: 64,
                  color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.5),
                ),
                const SizedBox(height: 16),
                const Text('No message requests'),
              ],
            ),
          );
        }
        return ListView.separated(
          itemCount: requests.length,
          separatorBuilder: (_, _) => const Divider(height: 1),
          itemBuilder: (context, index) {
            final conversation = requests[index];
            final displayName = conversation.getDisplayName(userId);
            return ListTile(
              onTap: () => GoRouter.of(context).push(
                '/messages/${conversation.id}',
              ),
              leading: CircleAvatar(
                child: Text(displayName.isNotEmpty ? displayName[0].toUpperCase() : '?'),
              ),
              title: Text(displayName),
              subtitle: Text(
                conversation.lastMessagePreview ?? 'New message request',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              trailing: TextButton(
                onPressed: () async {
                  await ref
                      .read(messagingControllerProvider)
                      .acceptMessageRequest(conversationId: conversation.id);
                },
                child: const Text('Accept'),
              ),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, _) => Center(child: Text('Error: $err')),
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

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => GoRouter.of(context).push('/messages/${conversation.id}'),
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

    if (difference.inMinutes < 1) {
      return 'now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${dateTime.month}/${dateTime.day}';
    }
  }
}
