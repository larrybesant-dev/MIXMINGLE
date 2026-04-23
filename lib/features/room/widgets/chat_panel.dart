import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/messagipackage:mixvy/features/messaging/models/message_model.dart';
import 'MessageModel_bubble.dart';

/// Self-contained chat panel widget for the Paltalk-style room layout.
/// Accepts streams/data as props and exposes a send callback so the
/// parent (LiveRoomScreen) retains all RTC/Firestore logic.
class ChatPanel extends ConsumerStatefulWidget {
  const ChatPanel({
    super.key,
    required this.MessageModel,
    required this.isLoadingMessageModel,
    required this.currentUserId,
    required this.currentUsername,
    required this.isSending,
    required this.cooldownMessageModel,
    required this.isMuted,
    required this.isBanned,
    required this.allowChat,
    required this.hasBlockedRelationship,
    required this.showEmojiTray,
    required this.onToggleEmojiTray,
    required this.onSendMessageModel,
    required this.onTyping,
    required this.MessageModelController,
    required this.scrollController,
    required this.senderLabelResolver,
    required this.senderVipLevelResolver,
    required this.senderAvatarResolver,
    this.onTapSender,
    this.typingNames = const [],
    this.extraHeader,
  });

  final List<MessageModel> MessageModel;
  final bool isLoadingMessageModel;
  final String currentUserId;
  final String currentUsername;
  final bool isSending;
  final String cooldownMessageModel;
  final bool isMuted;
  final bool isBanned;
  final bool allowChat;
  final bool hasBlockedRelationship;
  final bool showEmojiTray;
  final VoidCallback onToggleEmojiTray;
  final Future<void> Function(String text) onSendMessageModel;
  final VoidCallback onTyping;
  final TextEditingController MessageModelController;
  final ScrollController scrollController;
  final String Function(String senderId) senderLabelResolver;
  final int Function(String senderId) senderVipLevelResolver;
  final String? Function(String senderId) senderAvatarResolver;

  /// Called when the user taps the avatar or name of a MessageModel sender.
  final void Function(String senderId)? onTapSender;

  /// Names of users currently typing.
  final List<String> typingNames;

  /// Optional widget rendered above the MessageModel list (e.g. gift row,
  /// blocked warning, slow-mode notice).
  final Widget? extraHeader;

  static const List<String> _quickEmojis = [
    '😀',
    '😂',
    '😍',
    '🔥',
    '👏',
    '🙏',
    '💯',
    '🎉',
    '❤️',
    '👍',
    '👀',
    '😎',
  ];

  @override
  ConsumerState<ChatPanel> createState() => _ChatPanelState();
}

class _ChatPanelState extends ConsumerState<ChatPanel> {
  int _lastCount = 0;

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (widget.scrollController.hasClients &&
            widget.scrollController.position.hasContentDimensions) {
          widget.scrollController.jumpTo(
            widget.scrollController.position.maxScrollExtent,
          );
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    const npSurfaceLow = Color(0xFF10131A);
    const npOnVariant = Color(0xFFB09080);

    if (widget.MessageModel.length != _lastCount) {
      _lastCount = widget.MessageModel.length;
      _scrollToBottom();
    }

    final hintText = widget.isMuted
        ? 'You are muted'
        : widget.isBanned
        ? 'You are banned'
        : widget.hasBlockedRelationship
        ? 'Blocked relationship in room'
        : !widget.allowChat
        ? 'Chat disabled by host'
        : 'Type a MessageModel…';
    final keyboardInset = MediaQuery.viewInsetsOf(context).bottom;

    final canSend =
        !widget.isSending &&
        !widget.isMuted &&
        !widget.isBanned &&
        widget.allowChat &&
        !widget.hasBlockedRelationship;

    return ColoredBox(
      color: npSurfaceLow,
      child: Column(
        children: [
          // Extra header (gift row, blocked warning, etc.)
          if (widget.extraHeader != null) widget.extraHeader!,

          // MessageModel list
          Expanded(
            child: widget.isLoadingMessageModel
                ? const Center(child: CircularProgressIndicator())
                : widget.MessageModel.isEmpty
                ? const Center(
                    child: Text(
                      'No MessageModel yet.',
                      style: TextStyle(color: npOnVariant),
                    ),
                  )
                : ListView.builder(
                    controller: widget.scrollController,
                    padding: const EdgeInsets.all(6),
                    itemCount: widget.MessageModel.length,
                    itemBuilder: (context, i) {
                      final msg = widget.MessageModel[i];
                      return MessageModelBubble(
                        MessageModel: msg,
                        isMe: msg.senderId == widget.currentUserId,
                        senderLabel: widget.senderLabelResolver(msg.senderId),
                        senderVipLevel: widget.senderVipLevelResolver(
                          msg.senderId,
                        ),
                        senderAvatarUrl: widget.senderAvatarResolver(
                          msg.senderId,
                        ),
                        onTapSender: widget.onTapSender,
                      );
                    },
                  ),
          ),

          // Cooldown notice
          if (widget.cooldownMessageModel.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 4, left: 8, right: 8),
              child: Text(
                widget.cooldownMessageModel,
                style: const TextStyle(
                  color: Color(0xFFFF6E84),
                  fontWeight: FontWeight.bold,
                  fontSize: 11,
                ),
              ),
            ),

          // Typing indicator
          if (widget.typingNames.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  widget.typingNames.length == 1
                      ? '${widget.typingNames[0]} is typing…'
                      : '${widget.typingNames.join(', ')} are typing…',
                  style: const TextStyle(
                    color: npOnVariant,
                    fontSize: 11,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            ),

          // Emoji tray
          if (widget.showEmojiTray)
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 0, 8, 4),
              child: Wrap(
                spacing: 4,
                runSpacing: 4,
                children: ChatPanel._quickEmojis.map((e) {
                  return InkWell(
                    borderRadius: BorderRadius.circular(6),
                    onTap: () {
                      widget.MessageModelController.text += e;
                      widget.MessageModelController.selection =
                          TextSelection.fromPosition(
                            TextPosition(
                              offset: widget.MessageModelController.text.length,
                            ),
                          );
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(4),
                      child: Text(e, style: const TextStyle(fontSize: 20)),
                    ),
                  );
                }).toList(),
              ),
            ),

          // Input row
          SafeArea(
            top: false,
            left: false,
            right: false,
            minimum: const EdgeInsets.only(bottom: 4),
            child: AnimatedPadding(
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOut,
              padding: EdgeInsets.only(bottom: keyboardInset > 0 ? 4 : 0),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(6, 2, 6, 6),
                child: Row(
                  children: [
                    IconButton(
                      tooltip: 'Emojis',
                      iconSize: 20,
                      visualDensity: VisualDensity.compact,
                      icon: Icon(
                        widget.showEmojiTray
                            ? Icons.emoji_emotions
                            : Icons.emoji_emotions_outlined,
                        color: npOnVariant,
                      ),
                      onPressed: () {
                        FocusScope.of(context).unfocus();
                        widget.onToggleEmojiTray();
                      },
                    ),
                    Expanded(
                      child: TextField(
                        controller: widget.MessageModelController,
                        onChanged: (_) => widget.onTyping(),
                        enabled: canSend,
                        textInputAction: TextInputAction.send,
                        scrollPadding: EdgeInsets.only(
                          top: 24,
                          bottom: keyboardInset + 120,
                        ),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                        ),
                        decoration: InputDecoration(
                          hintText: hintText,
                          hintStyle: const TextStyle(
                            color: npOnVariant,
                            fontSize: 12,
                          ),
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 8,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(20),
                            borderSide: const BorderSide(
                              color: Color(0x30D4A853),
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(20),
                            borderSide: const BorderSide(
                              color: Color(0x30D4A853),
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(20),
                            borderSide: const BorderSide(
                              color: Color(0xFFD4A853),
                            ),
                          ),
                          filled: true,
                          fillColor: const Color(0xFF241820),
                        ),
                        onSubmitted: canSend
                            ? (text) async {
                                final trimmed = text.trim();
                                if (trimmed.isNotEmpty) {
                                  await widget.onSendMessageModel(trimmed);
                                }
                              }
                            : null,
                      ),
                    ),
                    const SizedBox(width: 6),
                    SizedBox(
                      height: 36,
                      child: FilledButton(
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFFD4A853),
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          minimumSize: Size.zero,
                        ),
                        onPressed: canSend
                            ? () async {
                                final text = widget.MessageModelController.text
                                    .trim();
                                if (text.isNotEmpty) {
                                  await widget.onSendMessageModel(text);
                                }
                              }
                            : null,
                        child: widget.isSending
                            ? const SizedBox(
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text(
                                'Send',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
