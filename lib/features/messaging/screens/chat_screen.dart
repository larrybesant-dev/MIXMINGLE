import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/messaging_provider.dart';
import '../../../services/web_popout_service.dart';
import '../../../core/theme.dart';

class ChatScreen extends ConsumerStatefulWidget {
  final String conversationId;
  final String userId;
  final String username;
  final String? avatarUrl;

  const ChatScreen({
    super.key,
    required this.conversationId,
    required this.userId,
    required this.username,
    this.avatarUrl,
  });

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  late TextEditingController _messageController;
  late ScrollController _scrollController;
  Timer? _typingTimer;
  bool _isTyping = false;

  @override
  void initState() {
    super.initState();
    _messageController = TextEditingController();
    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);
    _messageController.addListener(_onTextChanged);

    // Mark conversation as read
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(messagingControllerProvider).markAsRead(
            conversationId: widget.conversationId,
            userId: widget.userId,
          );
    });
  }

  void _onTextChanged() {
    if (_messageController.text.isEmpty) {
      _clearTyping();
      return;
    }
    if (!_isTyping) {
      _isTyping = true;
      ref.read(messagingControllerProvider).updateTypingStatus(
            conversationId: widget.conversationId,
            userId: widget.userId,
            isTyping: true,
          );
    }
    _typingTimer?.cancel();
    _typingTimer = Timer(const Duration(seconds: 4), _clearTyping);
  }

  void _clearTyping() {
    _typingTimer?.cancel();
    if (_isTyping) {
      _isTyping = false;
      ref.read(messagingControllerProvider).updateTypingStatus(
            conversationId: widget.conversationId,
            userId: widget.userId,
            isTyping: false,
          );
    }
  }

  void _onScroll() {
    // Load more when the user scrolls close to the top of the list.
    if (_scrollController.hasClients &&
        _scrollController.offset <=
            _scrollController.position.minScrollExtent + 120) {
      ref
          .read(paginatedMessagesProvider(widget.conversationId).notifier)
          .loadMore(null);
    }
  }

  @override
  void dispose() {
    _clearTyping();
    _typingTimer?.cancel();
    _messageController.removeListener(_onTextChanged);
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _sendMessage() async {
    final content = _messageController.text.trim();
    if (content.isEmpty) return;

    _clearTyping();
    _messageController.clear();

    await ref.read(messagingControllerProvider).sendMessage(
          conversationId: widget.conversationId,
          senderId: widget.userId,
          senderName: widget.username,
          senderAvatarUrl: widget.avatarUrl,
          content: content,
        );

    // Scroll to bottom
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final messagesAsync = ref.watch(messagesStreamProvider(widget.conversationId));
    final paginatedState = ref.watch(paginatedMessagesProvider(widget.conversationId));

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: VelvetNoir.primaryDim,
              backgroundImage: widget.avatarUrl != null
                  ? CachedNetworkImageProvider(widget.avatarUrl!)
                  : null,
              child: widget.avatarUrl == null
                  ? Text(
                      widget.username.isNotEmpty
                          ? widget.username[0].toUpperCase()
                          : '?',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  widget.username,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: VelvetNoir.onSurface,
                  ),
                ),
              ],
            ),
          ],
        ),
        elevation: 0,
        backgroundColor: VelvetNoir.surfaceLow,
        actions: [
          if (kIsWeb)
            IconButton(
              icon: const Icon(Icons.open_in_new),
              tooltip: 'Pop out',
              onPressed: () => WebPopoutService().openWhisperWindow(
                widget.userId,
                widget.username,
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: messagesAsync.when(
              data: (liveMessages) {
                // Merge: older pages on top, live stream at the bottom.
                final allMessages = [
                  ...paginatedState.olderMessages,
                  ...liveMessages,
                ];

                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (_scrollController.hasClients) {
                    _scrollController.jumpTo(
                      _scrollController.position.maxScrollExtent,
                    );
                  }
                });

                if (allMessages.isEmpty) {
                  return const Center(
                    child: Text('No messages yet. Start the conversation!'),
                  );
                }

                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16),
                  itemCount: allMessages.length +
                      (paginatedState.hasMore ? 1 : 0), // +1 for load-more row
                  itemBuilder: (context, index) {
                    // Load-more row at the very top.
                    if (index == 0 && paginatedState.hasMore) {
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: paginatedState.isLoading
                              ? const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : TextButton(
                                  onPressed: () => ref
                                      .read(paginatedMessagesProvider(
                                              widget.conversationId)
                                          .notifier)
                                      .loadMore(null),
                                  child: const Text('Load older messages'),
                                ),
                        ),
                      );
                    }

                    final message =
                        allMessages[index - (paginatedState.hasMore ? 1 : 0)];
                    final isOwn = message.senderId == widget.userId;
                    final convAsync = ref.watch(conversationDocProvider(widget.conversationId));
                    final conversation = convAsync.valueOrNull;
                    // Determine if the other participant has read past this message
                    bool isReadByOther = false;
                    if (isOwn && conversation != null) {
                      final otherIds = conversation.participantIds.where((id) => id != widget.userId);
                      isReadByOther = otherIds.any((id) {
                        final readAt = conversation.lastReadAt[id];
                        return readAt != null && !readAt.isBefore(message.createdAt);
                      });
                    }

                    if (message.isDeleted) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Center(
                          child: Text(
                            'Message deleted',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  fontStyle: FontStyle.italic,
                                  color: Colors.grey,
                                ),
                          ),
                        ),
                      );
                    }

                    return Align(
                      alignment: isOwn ? Alignment.centerRight : Alignment.centerLeft,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 3),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            if (!isOwn) ...[
                              CircleAvatar(
                                radius: 14,
                                backgroundColor: VelvetNoir.primaryDim,
                                backgroundImage: widget.avatarUrl != null
                                    ? CachedNetworkImageProvider(widget.avatarUrl!)
                                    : null,
                                child: widget.avatarUrl == null
                                    ? Text(
                                        widget.username.isNotEmpty
                                            ? widget.username[0].toUpperCase()
                                            : '?',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      )
                                    : null,
                              ),
                              const SizedBox(width: 6),
                            ],
                            Flexible(
                              child: Column(
                                crossAxisAlignment: isOwn
                                    ? CrossAxisAlignment.end
                                    : CrossAxisAlignment.start,
                                children: [
                                  GestureDetector(
                                    onLongPress: () => _showReactionPicker(
                                      context,
                                      ref,
                                      message.id,
                                    ),
                                    child: Container(
                                      constraints: BoxConstraints(
                                        maxWidth:
                                            MediaQuery.of(context).size.width * 0.72,
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 14,
                                        vertical: 10,
                                      ),
                                      decoration: BoxDecoration(
                                        gradient: isOwn
                                            ? const LinearGradient(
                                                begin: Alignment.topLeft,
                                                end: Alignment.bottomRight,
                                                colors: [
                                                  VelvetNoir.primary,
                                                  VelvetNoir.primaryDim,
                                                ],
                                              )
                                            : null,
                                        color: isOwn
                                            ? null
                                            : VelvetNoir.surfaceHigh,
                                        borderRadius: BorderRadius.only(
                                          topLeft: const Radius.circular(18),
                                          topRight: const Radius.circular(18),
                                          bottomLeft:
                                              Radius.circular(isOwn ? 18 : 4),
                                          bottomRight:
                                              Radius.circular(isOwn ? 4 : 18),
                                        ),
                                        border: isOwn
                                            ? null
                                            : Border.all(
                                                color: VelvetNoir.outlineVariant
                                                    .withValues(alpha: 0.4),
                                                width: 1,
                                              ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: isOwn
                                                ? VelvetNoir.primaryDim
                                                    .withValues(alpha: 0.25)
                                                : Colors.black
                                                    .withValues(alpha: 0.15),
                                            blurRadius: 8,
                                            offset: const Offset(0, 2),
                                          ),
                                        ],
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          if (!isOwn) ...[
                                            Text(
                                              message.senderName,
                                              style: const TextStyle(
                                                fontWeight: FontWeight.w600,
                                                fontSize: 12,
                                                color: VelvetNoir.secondary,
                                              ),
                                            ),
                                            const SizedBox(height: 3),
                                          ],
                                          Text(
                                            message.content,
                                            style: TextStyle(
                                              color: isOwn
                                                  ? Colors.white
                                                  : VelvetNoir.onSurface,
                                              fontSize: 14,
                                              height: 1.4,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  _ReactionRow(
                                    conversationId: widget.conversationId,
                                    messageId: message.id,
                                    currentUserId: widget.userId,
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.only(
                                        top: 3, left: 4, right: 4),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          _formatTime(message.createdAt),
                                          style: const TextStyle(
                                            fontSize: 11,
                                            color: VelvetNoir.onSurfaceVariant,
                                          ),
                                        ),
                                        if (isOwn) ...[
                                          const SizedBox(width: 4),
                                          Icon(
                                            isReadByOther
                                                ? Icons.done_all
                                                : Icons.done,
                                            size: 13,
                                            color: isReadByOther
                                                ? VelvetNoir.secondary
                                                : VelvetNoir.onSurfaceVariant,
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (isOwn) const SizedBox(width: 4),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stackTrace) => Center(
                child: Text('Error loading messages: $error'),
              ),
            ),
          ),
          _TypingIndicatorRow(
            conversationId: widget.conversationId,
            currentUserId: widget.userId,
            otherUsername: widget.username,
          ),
          Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
              left: 12,
              right: 12,
              top: 8,
            ),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
              decoration: BoxDecoration(
                color: VelvetNoir.surfaceHigh,
                borderRadius: BorderRadius.circular(32),
                border: Border.all(
                  color: VelvetNoir.outlineVariant.withValues(alpha: 0.5),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.emoji_emotions_outlined,
                        color: VelvetNoir.onSurfaceVariant),
                    iconSize: 22,
                    padding: EdgeInsets.zero,
                    onPressed: () => _showReactionPicker(
                      context,
                      ref,
                      '__input__',
                    ),
                  ),
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      decoration: const InputDecoration(
                        hintText: 'Message…',
                        hintStyle:
                            TextStyle(color: VelvetNoir.onSurfaceVariant),
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.symmetric(
                            horizontal: 8, vertical: 8),
                      ),
                      style: const TextStyle(
                          color: VelvetNoir.onSurface, fontSize: 14),
                      maxLines: null,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                  const SizedBox(width: 4),
                  GestureDetector(
                    onTap: _sendMessage,
                    child: Container(
                      width: 38,
                      height: 38,
                      decoration: const BoxDecoration(
                        gradient: VelvetNoir.primaryGradient,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.send_rounded,
                          color: Colors.white, size: 18),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final messageDate = DateTime(
      dateTime.year,
      dateTime.month,
      dateTime.day,
    );

    if (messageDate == today) {
      return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    } else if (messageDate == yesterday) {
      return 'Yesterday';
    } else {
      return '${dateTime.month}/${dateTime.day}';
    }
  }

  void _showReactionPicker(BuildContext context, WidgetRef ref, String messageId) {
    const emojis = ['❤️', '😂', '😮', '😢', '👍', '👎'];
    showModalBottomSheet<void>(
      context: context,
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: emojis.map((emoji) {
              return GestureDetector(
                onTap: () {
                  Navigator.of(context).pop();
                  ref.read(messagingControllerProvider).toggleReaction(
                        conversationId: widget.conversationId,
                        messageId: messageId,
                        currentUserId: widget.userId,
                        emoji: emoji,
                      );
                },
                child: Text(emoji, style: const TextStyle(fontSize: 32)),
              );
            }).toList(growable: false),
          ),
        ),
      ),
    );
  }
}

/// Shows "[Name] is typing…" for other participants when their typing heartbeat
/// is fresh (< 8 s). Uses [typingUsersProvider] which filters stale entries.
class _TypingIndicatorRow extends ConsumerWidget {
  const _TypingIndicatorRow({
    required this.conversationId,
    required this.currentUserId,
    required this.otherUsername,
  });

  final String conversationId;
  final String currentUserId;
  final String otherUsername;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final typingAsync = ref.watch(typingUsersProvider(conversationId));
    return typingAsync.when(
      data: (ids) {
        final othersTyping = ids.any((id) => id != currentUserId);
        if (!othersTyping) return const SizedBox.shrink();
        return Padding(
          padding: const EdgeInsets.only(left: 20, bottom: 2),
          child: Row(
            children: [
              _BouncingDots(),
              const SizedBox(width: 6),
              Text(
                '$otherUsername is typing…',
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: Colors.grey),
              ),
            ],
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
    );
  }
}

class _BouncingDots extends StatefulWidget {
  @override
  State<_BouncingDots> createState() => _BouncingDotsState();
}

class _BouncingDotsState extends State<_BouncingDots>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, _) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (i) {
            final offset = ((_ctrl.value * 3) - i).clamp(0.0, 1.0);
            final dy = -3.0 * (offset < 0.5 ? offset : 1.0 - offset) * 2;
            return Transform.translate(
              offset: Offset(0, dy),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 1.5),
                child: CircleAvatar(
                  radius: 3,
                  backgroundColor: Colors.grey,
                ),
              ),
            );
          }),
        );
      },
    );
  }
}

/// Displays emoji reactions for a single message. Tapping your own reaction
/// toggles it off; tapping another reaction adds yours.
class _ReactionRow extends ConsumerWidget {
  const _ReactionRow({
    required this.conversationId,
    required this.messageId,
    required this.currentUserId,
  });

  final String conversationId;
  final String messageId;
  final String currentUserId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reactionsAsync = ref.watch(
      messageReactionsProvider((
        conversationId: conversationId,
        messageId: messageId,
      )),
    );
    return reactionsAsync.when(
      data: (reactions) {
        if (reactions.isEmpty) return const SizedBox.shrink();
        // Aggregate: emoji → count
        final counts = <String, int>{};
        for (final emoji in reactions.values) {
          counts[emoji] = (counts[emoji] ?? 0) + 1;
        }
        return Padding(
          padding: const EdgeInsets.only(top: 2, left: 4, right: 4),
          child: Wrap(
            spacing: 4,
            children: counts.entries.map((e) {
              final myReaction = reactions[currentUserId] == e.key;
              return GestureDetector(
                onTap: () => ref.read(messagingControllerProvider).toggleReaction(
                      conversationId: conversationId,
                      messageId: messageId,
                      currentUserId: currentUserId,
                      emoji: e.key,
                    ),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: myReaction
                        ? Theme.of(context).colorScheme.primaryContainer
                        : Theme.of(context).colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(999),
                    border: myReaction
                        ? Border.all(
                            color: Theme.of(context).colorScheme.primary,
                            width: 1,
                          )
                        : null,
                  ),
                  child: Text('${e.key} ${e.value}', style: const TextStyle(fontSize: 12)),
                ),
              );
            }).toList(growable: false),
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
    );
  }
}
