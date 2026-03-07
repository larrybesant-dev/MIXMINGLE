import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:file_picker/file_picker.dart' as file_picker;
import 'package:mixmingle/shared/widgets/club_background.dart';
import 'package:mixmingle/services/chat/chat_service.dart';
import 'package:mixmingle/shared/models/chat_message.dart';
import 'package:mixmingle/shared/widgets/typing_indicator_widget.dart';
import 'package:mixmingle/shared/providers/all_providers.dart';

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
  List<ChatMessage> _olderMessages = [];
  DocumentSnapshot? _oldestDoc;
  bool _isLoadingMore = false;
  bool _hasMore = true;

  @override
  void initState() {
    super.initState();
    controller.addListener(_onTextChanged);
    _scrollController.addListener(_onScroll);
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

    // TODO: If userId is provided but no chatId, create or find chat with that user
    final effectiveChatId = widget.chatId ?? 'temp_${widget.userId}';

    return ClubBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Column(
          children: [
            Expanded(
              child: StreamBuilder<List<ChatMessage>?>(
                stream: _cs.messagesStream(effectiveChatId),
                builder: (BuildContext context, AsyncSnapshot<List<ChatMessage>?> snap) {
                  if (!snap.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final messages = snap.data!;
                  final allMsgs = _mergeMessages(_olderMessages, messages);
                  return ListView.builder(
                    controller: _scrollController,
                    reverse: true,
                    itemCount: allMsgs.length + (_hasMore ? 1 : 0),
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
                        onLongPress: () => _showReactionPicker(context, msg,
                            effectiveRoom, currentUser?.uid ?? ''),
                        child: Align(
                          alignment: isCurrentUser
                              ? Alignment.centerRight
                              : Alignment.centerLeft,
                          child: Container(
                            margin: const EdgeInsets.symmetric(
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
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
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
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: [
                  // File upload button
                  IconButton(
                    icon: const Icon(Icons.attach_file),
                    onPressed: _isUploading ? null : _pickAndUploadFile,
                  ),
                  Expanded(
                    child: TextField(
                      controller: controller,
                      decoration: const InputDecoration(hintText: 'Message'),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.send),
                    onPressed: () {
                      final text = controller.text.trim();
                      if (text.isNotEmpty) {
                        final currentUser = FirebaseAuth.instance.currentUser;
                        if (currentUser != null) {
                          _cs.sendMessage(effectiveChatId, text);
                          controller.clear();
                        }
                      }
                    },
                  ),
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
            senderName: currentUser.displayName ?? currentUser.email ?? 'Anonymous',
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
