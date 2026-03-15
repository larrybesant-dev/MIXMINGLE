import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:file_picker/file_picker.dart' as file_picker;
import 'package:mixmingle/shared/widgets/club_background.dart';
import 'package:mixmingle/core/design_system/design_constants.dart';
import 'package:mixmingle/services/chat/chat_service.dart';
import 'package:mixmingle/shared/models/chat_message.dart';
import 'package:mixmingle/shared/widgets/typing_indicator_widget.dart';
import 'package:mixmingle/shared/providers/all_providers.dart';
import 'package:mixmingle/services/notifications/app_notification_service.dart';
import 'package:mixmingle/core/analytics/analytics_service.dart';

class ChatPage extends ConsumerStatefulWidget {
  final String? chatId;
  final String? userId;

  const ChatPage({
    super.key,
    this.chatId,
    this.userId,
  });

  @override
  ConsumerState<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends ConsumerState<ChatPage> {
  final _cs = ChatService();
  final controller = TextEditingController();
  final _scrollController = ScrollController();
  Timer? _typingTimer;
  bool _isUploading = false;
<<<<<<< HEAD
  List<ChatMessage> _olderMessages = [];
  DocumentSnapshot? _oldestDoc;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  String? _resolvedChatId;
  bool _resolvingChat = false;
=======
  ChatMessage? _replyToMsg;
  bool _hasText = false;
>>>>>>> origin/develop

  @override
  void initState() {
    super.initState();
    controller.addListener(_onTextChanged);
<<<<<<< HEAD
    _scrollController.addListener(_onScroll);
    if (widget.chatId == null && widget.userId != null) {
      _resolveChat();
    }
  }

  Future<void> _resolveChat() async {
    setState(() => _resolvingChat = true);
    try {
      final room = await _cs.getOrCreateChatRoom(widget.userId!);
      if (mounted) setState(() => _resolvedChatId = room.id);
    } catch (_) {
      // Fall back to temp id silently
    } finally {
      if (mounted) setState(() => _resolvingChat = false);
    }
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 200 &&
        !_isLoadingMore &&
        _hasMore) {
      _loadOlderMessages();
    }
  }

  Future<void> _loadOlderMessages() async {
    if (widget.chatId == null) return;
    setState(() => _isLoadingMore = true);
    try {
      final (msgs, cursor) =
          await _cs.getMessagesPage(widget.chatId!, lastDoc: _oldestDoc);
      if (mounted) {
        setState(() {
          _olderMessages = [...msgs, ..._olderMessages];
          _oldestDoc = cursor;
          _hasMore = msgs.length == 25;
          _isLoadingMore = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoadingMore = false);
    }
=======
    controller.addListener(() {
      final has = controller.text.trim().isNotEmpty;
      if (has != _hasText) setState(() => _hasText = has);
    });
    AnalyticsService.instance.logScreenView(screenName: 'screen_chat');
>>>>>>> origin/develop
  }

  void _onTextChanged() {
    if (controller.text.isNotEmpty && widget.chatId != null) {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null) {
        _cs.setTyping(widget.chatId!, currentUser.uid,
            currentUser.displayName ?? 'User', true);
        _typingTimer?.cancel();
        _typingTimer = Timer(const Duration(seconds: 4), () {
          _cs.setTyping(widget.chatId!, currentUser.uid, '', false).ignore();
        });
      }
    }
  }

  @override
  void dispose() {
    _typingTimer?.cancel();
    _scrollController.dispose();
    controller.dispose();
    final currentUser = FirebaseAuth.instance.currentUser;
    if (widget.chatId != null && currentUser != null) {
      _cs.setTyping(widget.chatId!, currentUser.uid, '', false).ignore();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // If no chatId provided, show error
    if (widget.chatId == null && widget.userId == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Chat')),
        body: const Center(
          child: Text('No chat information provided'),
        ),
      );
    }

    if (_resolvingChat) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final effectiveChatId = _resolvedChatId ?? widget.chatId ?? 'temp_${widget.userId}';

    return ClubBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Column(
          children: [
            Expanded(
              child: StreamBuilder<List<ChatMessage>?>(
                stream: _cs.messagesStream(effectiveChatId),
                builder: (BuildContext context,
                    AsyncSnapshot<List<ChatMessage>?> snap) {
                  if (!snap.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final messages = snap.data!;
                  final allMsgs = _mergeMessages(_olderMessages, messages);
                  return ListView.builder(
                    controller: _scrollController,
                    reverse: true,
<<<<<<< HEAD
                    itemCount: allMsgs.length + (_hasMore ? 1 : 0),
=======
                    physics: const BouncingScrollPhysics(),
                    itemCount: messages.length,
>>>>>>> origin/develop
                    itemBuilder: (ctx, i) {
                      if (i == allMsgs.length) {
                        return _isLoadingMore
                            ? const Center(
                                child: Padding(
                                  padding: EdgeInsets.all(8),
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2),
                                ))
                            : const SizedBox.shrink();
                      }
                      final msg = allMsgs[allMsgs.length - 1 - i];
                      final senderId = msg.senderId;
                      final currentUser = FirebaseAuth.instance.currentUser;
                      final isCurrentUser = senderId == currentUser?.uid;
                      final effectiveRoom = widget.chatId ?? '';

                      return GestureDetector(
<<<<<<< HEAD
                        onLongPress: () => _showReactionPicker(context, msg,
                            effectiveRoom, currentUser?.uid ?? ''),
=======
                        onLongPress: () {
                          HapticFeedback.mediumImpact();
                          setState(() => _replyToMsg = msg);
                          AnalyticsService.instance.logEvent(
                            name: 'chat_reply_used',
                            parameters: {'chat_id': effectiveChatId},
                          );
                        },
>>>>>>> origin/develop
                        child: Align(
                          alignment: isCurrentUser
                              ? Alignment.centerRight
                              : Alignment.centerLeft,
                          child: Container(
                            margin: const EdgeInsets.symmetric(
<<<<<<< HEAD
                                horizontal: 8, vertical: 4),
                            padding: const EdgeInsets.all(12),
                            constraints: BoxConstraints(
                              maxWidth:
                                  MediaQuery.of(context).size.width * 0.7,
                            ),
                            decoration: BoxDecoration(
                              color: isCurrentUser
                                  ? Theme.of(context)
                                      .primaryColor
                                      .withValues(alpha: 0.8)
                                  : Colors.grey[800],
                              borderRadius: BorderRadius.circular(12),
=======
                                horizontal: 12, vertical: 3),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 10),
                            constraints: BoxConstraints(
                              maxWidth:
                                  MediaQuery.of(context).size.width * 0.72,
                            ),
                            decoration: BoxDecoration(
                              gradient: isCurrentUser
                                  ? LinearGradient(
                                      colors: [
                                        DesignColors.accent
                                            .withValues(alpha: 0.85),
                                        const Color(0xFF6B3FA0)
                                            .withValues(alpha: 0.85),
                                      ],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    )
                                  : null,
                              color: isCurrentUser
                                  ? null
                                  : DesignColors.surfaceLight,
                              borderRadius: BorderRadius.only(
                                topLeft: const Radius.circular(16),
                                topRight: const Radius.circular(16),
                                bottomLeft: Radius.circular(
                                    isCurrentUser ? 16 : 4),
                                bottomRight: Radius.circular(
                                    isCurrentUser ? 4 : 16),
                              ),
                              boxShadow: isCurrentUser
                                  ? [
                                      BoxShadow(
                                        color: DesignColors.accent
                                            .withValues(alpha: 0.25),
                                        blurRadius: 8,
                                        offset: const Offset(0, 2),
                                      )
                                    ]
                                  : null,
>>>>>>> origin/develop
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
<<<<<<< HEAD
                                if (!isCurrentUser) ...[
                                  _SenderNameWidget(
                                      senderId: senderId, ref: ref),
                                  const SizedBox(height: 4),
                                ],
                                if (msg.imageUrl != null)
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Image.network(
                                      msg.imageUrl!,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) =>
                                          const Icon(Icons.broken_image,
                                              color: Colors.white54),
                                    ),
                                  )
                                else
                                  Text(msg.content,
                                      style: const TextStyle(
                                          color: Colors.white)),
                                if (isCurrentUser && msg.isRead) ...[
                                  const SizedBox(height: 4),
                                  const Icon(Icons.done_all,
                                      size: 14,
                                      color: Colors.lightBlueAccent),
                                ],
                                if ((msg.reactionsMap?.isNotEmpty) == true) ...[
                                  const SizedBox(height: 6),
                                  _ReactionStrip(
                                    reactionsMap: msg.reactionsMap!,
                                    currentUserId: currentUser?.uid ?? '',
                                    onTap: (emoji) {
                                      final uid = currentUser?.uid ?? '';
                                      if (msg.reactionsMap?[uid] == emoji) {
                                        _cs.removeReaction(
                                            effectiveRoom, msg.id, uid);
                                      } else {
                                        _cs.addReaction(
                                            effectiveRoom, msg.id, uid, emoji);
                                      }
                                    },
                                  ),
                                ],
=======
                                if (_replyToMsg != null &&
                                    msg.id == _replyToMsg!.id)
                                  Container(
                                    margin: const EdgeInsets.only(bottom: 6),
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.white
                                          .withValues(alpha: 0.08),
                                      borderRadius: BorderRadius.circular(6),
                                      border: const Border(
                                          left: BorderSide(
                                              color: DesignColors.accent,
                                              width: 3)),
                                    ),
                                    child: Text(
                                      _replyToMsg!.content,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.white
                                              .withValues(alpha: 0.6)),
                                    ),
                                  ),
                                if (!isCurrentUser)
                                  _SenderNameWidget(
                                    senderId: senderId,
                                    ref: ref,
                                  ),
                                if (!isCurrentUser) const SizedBox(height: 4),
                                Text(
                                  msg.content,
                                  style: const TextStyle(
                                      color: Colors.white, height: 1.35),
                                ),
>>>>>>> origin/develop
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
            // Typing indicator
            TypingIndicatorWidget(roomId: effectiveChatId),
            // Reply preview bar
            if (_replyToMsg != null)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                color: DesignColors.surfaceLight,
                child: Row(
                  children: [
                    Container(
                      width: 3,
                      height: 32,
                      decoration: BoxDecoration(
                        color: DesignColors.accent,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _replyToMsg!.content,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            color:
                                DesignColors.textGray.withValues(alpha: 0.8),
                            fontSize: 13),
                      ),
                    ),
                    IconButton(
                      onPressed: () =>
                          setState(() => _replyToMsg = null),
                      icon: const Icon(Icons.close,
                          size: 18, color: DesignColors.textGray),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 6, 8, 8),
              child: Row(
                children: [
                  // File upload button
                  IconButton(
                    icon: Icon(Icons.attach_file,
                        color: DesignColors.textGray.withValues(alpha: 0.7)),
                    onPressed: _isUploading ? null : _pickAndUploadFile,
                  ),
                  Expanded(
                    child: TextField(
                      controller: controller,
                      maxLength: 1000,
                      maxLines: null,
                      style: const TextStyle(color: DesignColors.white),
                      buildCounter: (_, {required currentLength, required isFocused, maxLength}) => null,
                      decoration: InputDecoration(
                        hintText: 'Message…',
                        hintStyle: TextStyle(
                            color: DesignColors.textGray.withValues(alpha: 0.55)),
                        filled: true,
                        fillColor: DesignColors.surfaceLight,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 10),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  // Animated send button
                  AnimatedScale(
                    scale: _hasText ? 1.0 : 0.82,
                    duration: const Duration(milliseconds: 180),
                    curve: Curves.easeOut,
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: _hasText
                            ? const LinearGradient(
                                colors: [
                                  Color(0xFF4A90FF),
                                  Color(0xFF8B5CF6),
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              )
                            : null,
                        color: _hasText
                            ? null
                            : DesignColors.surfaceLight,
                        boxShadow: _hasText
                            ? [
                                BoxShadow(
                                  color: DesignColors.accent
                                      .withValues(alpha: 0.4),
                                  blurRadius: 12,
                                ),
                              ]
                            : null,
                      ),
                      child: IconButton(
                        icon: Icon(
                          Icons.send_rounded,
                          color:
                              _hasText ? Colors.white : DesignColors.textGray,
                          size: 20,
                        ),
                    onPressed: () async {
                      final text = controller.text.trim();
                      if (text.isNotEmpty) {
                        HapticFeedback.lightImpact();
                        final currentUser = FirebaseAuth.instance.currentUser;
                        if (currentUser != null) {
                          controller.clear();
                          final messenger = ScaffoldMessenger.of(context);
                          try {
                            await _cs.sendMessage(effectiveChatId, text);
                            AnalyticsService.instance.logChatMessageSent(chatId: effectiveChatId);
                            AnalyticsService.instance.logFirstChatSentOnce(chatId: effectiveChatId);
                            // Notify the other participant in direct chats
                            if (widget.userId != null &&
                                widget.userId != currentUser.uid) {
                              AppNotificationService.instance
                                  .notifyNewChatMessage(
                                receiverId: widget.userId!,
                                senderName:
                                    currentUser.displayName ?? 'Someone',
                                chatId: effectiveChatId,
                                preview: text.length > 60
                                    ? text.substring(0, 60)
                                    : text,
                                senderAvatarUrl: currentUser.photoURL,
                              );
                            }
                          } catch (_) {
                            AnalyticsService.instance.logNetworkError(context: 'chat_send');
                            if (mounted) {
                              messenger.showSnackBar(
                                const SnackBar(
                                  content: Text('Failed to send — check your connection'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                              // Restore unsent text
                              controller.text = text;
                            }
                          }
                        }
                      }
                    },
                  ),        // closes IconButton
                ),          // closes Container
              ),            // closes AnimatedScale
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Merge paginated older messages with the live stream messages,
  /// de-duplicating by id and sorting by timestamp.
  List<ChatMessage> _mergeMessages(
      List<ChatMessage> older, List<ChatMessage> live) {
    final seen = <String>{};
    final merged = <ChatMessage>[];
    for (final m in [...live, ...older]) {
      if (seen.add(m.id)) merged.add(m);
    }
    merged.sort((a, b) => a.timestamp.compareTo(b.timestamp));
    return merged;
  }

  /// Shows an emoji reaction picker for [msg].
  Future<void> _showReactionPicker(
      BuildContext context,
      ChatMessage msg,
      String chatId,
      String userId) async {
    const emojis = ['❤️', '😂', '😮', '😢', '👍', '🔥'];
    final chosen = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: const Color(0xFF1A1A3A),
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: emojis
              .map((e) => GestureDetector(
                    onTap: () => Navigator.pop(context, e),
                    child: Text(e, style: const TextStyle(fontSize: 30)),
                  ))
              .toList(),
        ),
      ),
    );
    if (chosen == null) return;
    if (msg.reactionsMap?[userId] == chosen) {
      await _cs.removeReaction(chatId, msg.id, userId);
    } else {
      await _cs.addReaction(chatId, msg.id, userId, chosen);
    }
  }

  Future<void> _pickAndUploadFile() async {
    try {
      setState(() => _isUploading = true);

      final result = await file_picker.FilePicker.platform.pickFiles(
        type: file_picker.FileType.any,
        withData: true,
      );

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        final currentUser = FirebaseAuth.instance.currentUser;

        if (currentUser != null) {
          final fileShareService = ref.read(fileShareServiceProvider);

          await fileShareService.uploadFileFromBytes(
            bytes: file.bytes!,
            fileName: file.name,
            chatId: widget.chatId ?? '',
            senderId: currentUser.uid,
            senderName:
                currentUser.displayName ?? currentUser.email ?? 'Anonymous',
          );

          // Send file message
          _cs.sendMessage(widget.chatId ?? '', 'ðŸ“Ž ${file.name}');

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('File uploaded!')),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Upload failed: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isUploading = false);
      }
    }
  }
}

class _SenderNameWidget extends ConsumerWidget {
  final String senderId;
  final WidgetRef ref;

  const _SenderNameWidget({
    required this.senderId,
    required this.ref,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Fetch sender name from Firestore profile
    final senderProfileAsync = ref.watch(userProfileProvider(senderId));

    return senderProfileAsync.when(
      data: (profile) {
        String displayName = 'User';
        if (profile?.displayName != null && profile!.displayName!.isNotEmpty) {
          displayName = profile.displayName!;
        } else if (profile?.nickname != null && profile!.nickname!.isNotEmpty) {
          displayName = profile.nickname!;
        }
        return Text(
          displayName,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.secondary,
          ),
        );
      },
      loading: () => Text(
        'Loading...',
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Theme.of(context).colorScheme.secondary,
        ),
      ),
      error: (_, __) => Text(
        'User',
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Theme.of(context).colorScheme.secondary,
        ),
      ),
    );
  }
}

/// Horizontal strip that shows emoji reactions on a message bubble.
class _ReactionStrip extends StatelessWidget {
  final Map<String, String> reactionsMap; // userId → emoji
  final String currentUserId;
  final void Function(String emoji) onTap;

  const _ReactionStrip({
    required this.reactionsMap,
    required this.currentUserId,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // Aggregate: emoji → count
    final counts = <String, int>{};
    for (final e in reactionsMap.values) {
      counts[e] = (counts[e] ?? 0) + 1;
    }
    final myReaction = reactionsMap[currentUserId];

    return Wrap(
      spacing: 4,
      children: counts.entries.map((entry) {
        final selected = entry.key == myReaction;
        return GestureDetector(
          onTap: () => onTap(entry.key),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: selected
                  ? Colors.purpleAccent.withValues(alpha: 0.25)
                  : Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: selected
                    ? Colors.purpleAccent.withValues(alpha: 0.6)
                    : Colors.white24,
              ),
            ),
            child: Text(
              '${entry.key} ${entry.value}',
              style: const TextStyle(fontSize: 12),
            ),
          ),
        );
      }).toList(),
    );
  }
}
