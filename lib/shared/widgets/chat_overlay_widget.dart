import 'package:flutter/material.dart';
import '../../../core/design_system/design_constants.dart';
import '../../../shared/models/chat_message.dart';

class ChatOverlayWidget extends StatefulWidget {
  final List<ChatMessage> messages;
  final bool isVisible;
  final Function(String)? onSendMessage;
  final VoidCallback? onToggleVisibility;
  final int unreadCount;
  final String currentUserId;

  const ChatOverlayWidget({
    super.key,
    required this.messages,
    this.isVisible = false,
    this.onSendMessage,
    this.onToggleVisibility,
    this.unreadCount = 0,
    this.currentUserId = '',
  });

  @override
  State<ChatOverlayWidget> createState() => _ChatOverlayWidgetState();
}

class _ChatOverlayWidgetState extends State<ChatOverlayWidget>
    with TickerProviderStateMixin {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  late AnimationController _slideController;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(1, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));

    if (widget.isVisible) {
      _slideController.value = 1.0;
    }
  }

  @override
  void didUpdateWidget(ChatOverlayWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isVisible != oldWidget.isVisible) {
      if (widget.isVisible) {
        _slideController.forward();
      } else {
        _slideController.reverse();
      }
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  void _sendMessage() {
    final message = _messageController.text.trim();
    if (message.isNotEmpty) {
      widget.onSendMessage?.call(message);
      _messageController.clear();
      _scrollToBottom();
    }
  }

  void _scrollToBottom() {
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
    return Stack(
      children: [
        // Chat toggle button
        Positioned(
          bottom: 120, // Above media controls
          right: DesignSpacing.lg,
          child: _buildChatToggleButton(),
        ),

        // Chat panel
        Positioned(
          bottom: 0,
          right: 0,
          top: 0,
          width: MediaQuery.of(context).size.width * 0.35,
          child: SlideTransition(
            position: _slideAnimation,
            child: Container(
              decoration: BoxDecoration(
                color: DesignColors.surface.withValues(alpha: 0.95),
                border: Border(
                  left: BorderSide(
                    color: DesignColors.accent.withValues(alpha: 0.2),
                  ),
                ),
              ),
              child: Column(
                children: [
                  // Chat header
                  _buildChatHeader(),

                  // Messages list
                  Expanded(
                    child: _buildMessagesList(),
                  ),

                  // Message input
                  _buildMessageInput(),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildChatToggleButton() {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        color: DesignColors.accent,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: DesignColors.accent.withValues(alpha: 0.3),
            blurRadius: 8,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Stack(
        children: [
          Center(
            child: IconButton(
              icon: Icon(
                widget.isVisible ? Icons.chat_bubble : Icons.chat,
                color: DesignColors.white,
                size: 24,
              ),
              onPressed: widget.onToggleVisibility,
            ),
          ),
          if (widget.unreadCount > 0)
            Positioned(
              top: 8,
              right: 8,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: DesignColors.error,
                  shape: BoxShape.circle,
                ),
                constraints: const BoxConstraints(
                  minWidth: 18,
                  minHeight: 18,
                ),
                child: Text(
                  widget.unreadCount > 99 ? '99+' : widget.unreadCount.toString(),
                  style: DesignTypography.caption.copyWith(
                    color: DesignColors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildChatHeader() {
    return Container(
      padding: const EdgeInsets.all(DesignSpacing.md),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: DesignColors.surface,
          ),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.chat,
            color: DesignColors.accent,
            size: 20,
          ),
          const SizedBox(width: DesignSpacing.sm),
          Text(
            'Room Chat',
            style: DesignTypography.body.copyWith(
              fontWeight: FontWeight.bold,
              color: DesignColors.textPrimary,
            ),
          ),
          Expanded(child: Container()),
          IconButton(
            icon: const Icon(
              Icons.close,
              color: DesignColors.textSecondary,
              size: 20,
            ),
            onPressed: widget.onToggleVisibility,
          ),
        ],
      ),
    );
  }

  Widget _buildMessagesList() {
    if (widget.messages.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.chat_bubble_outline,
              color: DesignColors.textSecondary.withValues(alpha: 0.5),
              size: 48,
            ),
            const SizedBox(height: DesignSpacing.md),
            Text(
              'No messages yet',
              style: DesignTypography.body.copyWith(
                color: DesignColors.textSecondary,
              ),
            ),
            Text(
              'Start the conversation!',
              style: DesignTypography.caption.copyWith(
                color: DesignColors.textSecondary.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(DesignSpacing.md),
      itemCount: widget.messages.length,
      itemBuilder: (context, index) {
        final message = widget.messages[index];
        return _buildMessageItem(message);
      },
    );
  }

  Widget _buildMessageItem(ChatMessage message) {
    final isCurrentUser = message.senderId == widget.currentUserId;

    return Container(
      margin: const EdgeInsets.only(bottom: DesignSpacing.sm),
      child: Row(
        mainAxisAlignment: isCurrentUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!isCurrentUser)
            Container(
              width: 32,
              height: 32,
              margin: const EdgeInsets.only(right: DesignSpacing.sm),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [DesignColors.accent, DesignColors.gold],
                ),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  message.senderName.isNotEmpty ? message.senderName[0].toUpperCase() : '?',
                  style: DesignTypography.caption.copyWith(
                    color: DesignColors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),

          Flexible(
            child: Container(
              padding: const EdgeInsets.all(DesignSpacing.sm),
              decoration: BoxDecoration(
                color: isCurrentUser
                    ? DesignColors.accent
                    : DesignColors.background,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: DesignColors.surface,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (!isCurrentUser)
                    Text(
                      message.senderName,
                      style: DesignTypography.caption.copyWith(
                        color: DesignColors.textSecondary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  Text(
                    message.content,
                    style: DesignTypography.body.copyWith(
                      color: isCurrentUser ? DesignColors.white : DesignColors.textPrimary,
                    ),
                  ),
                  Text(
                    _formatTimestamp(message.timestamp),
                    style: DesignTypography.caption.copyWith(
                      color: isCurrentUser
                          ? DesignColors.white.withValues(alpha: 0.7)
                          : DesignColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.all(DesignSpacing.md),
      decoration: const BoxDecoration(
        border: Border(
          top: BorderSide(
            color: DesignColors.surface,
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              decoration: InputDecoration(
                hintText: 'Type a message...',
                hintStyle: DesignTypography.body.copyWith(
                  color: DesignColors.textSecondary,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: DesignColors.background,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: DesignSpacing.md,
                  vertical: DesignSpacing.sm,
                ),
              ),
              style: DesignTypography.body,
              onSubmitted: (_) => _sendMessage(),
            ),
          ),
          const SizedBox(width: DesignSpacing.sm),
          Container(
            decoration: const BoxDecoration(
              color: DesignColors.accent,
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: const Icon(
                Icons.send,
                color: DesignColors.white,
                size: 20,
              ),
              onPressed: _sendMessage,
            ),
          ),
        ],
      ),
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'now';
    }
  }
}
