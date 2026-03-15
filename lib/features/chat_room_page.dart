<<<<<<< HEAD
=======
import 'dart:io';
>>>>>>> origin/develop
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/user_providers.dart';
import '../services/messaging_service.dart';

class ChatRoomPage extends ConsumerStatefulWidget {
  final String otherUserId;
  final String conversationId;

  const ChatRoomPage({
    super.key,
    required this.otherUserId,
    required this.conversationId,
  });

  @override
  ConsumerState<ChatRoomPage> createState() => _ChatRoomPageState();
}

class _ChatRoomPageState extends ConsumerState<ChatRoomPage> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scroll = ScrollController();
  bool _canSend = false;

  // Track the last seen message count so we only markAsRead when new
  // messages from the other user arrive.
  int _lastMessageCount = 0;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onTextChanged);

    // Mark as read on open.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _markAsRead();
    });
  }

  @override
  void dispose() {
    _controller.removeListener(_onTextChanged);
    _controller.dispose();
    _scroll.dispose();
    super.dispose();
  }

<<<<<<< HEAD
  void _onTextChanged() {
    final canSend = _controller.text.trim().isNotEmpty;
    if (canSend != _canSend) {
      setState(() => _canSend = canSend);
    }
  }

  void _markAsRead() {
    final currentUser = ref.read(currentUserProvider).value;
    if (currentUser != null) {
      ref
          .read(messagingServiceProvider)
          .markAsRead(widget.conversationId, currentUser.id);
=======
  void _onTypingChanged() {
    final isTypingNow = _messageController.text.trim().isNotEmpty;
    if (_isTyping != isTypingNow) {
      setState(() => _isTyping = isTypingNow);
      ref
          .read(chatActionsProvider)
          .updateTypingStatus(widget.chatRoom.id, isTypingNow);
    }
  }

  void _sendMessage() async {
    final content = _messageController.text.trim();
    if (content.isEmpty) return;

    _messageController.clear();
    setState(() => _isTyping = false);

    try {
      await ref
          .read(chatActionsProvider)
          .sendMessage(widget.chatRoom.id, content);
      _scrollToBottom();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to send message: $e')),
        );
      }
>>>>>>> origin/develop
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(
          _scroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    final currentUser = ref.read(currentUserProvider).value;
    if (currentUser == null) return;

    _controller.clear();

    try {
      await ref.read(messagingServiceProvider).sendMessage(
            conversationId: widget.conversationId,
            senderId: currentUser.id,
            text: text,
          );
      _scrollToBottom();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to send message. Please try again.'),
          ),
        );
        // Restore draft so the user doesn't lose their text.
        _controller.text = text;
        _controller.selection =
            TextSelection.collapsed(offset: _controller.text.length);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
<<<<<<< HEAD
    final currentUser = ref.watch(currentUserProvider).value;
    final messaging = ref.watch(messagingServiceProvider);

    if (currentUser == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Chat'),
=======
    final currentUserId = ref.watch(currentUserProfileProvider).value?.id ?? '';
    final otherUserId =
        widget.chatRoom.participants.firstWhere((id) => id != currentUserId);
    final otherUserAsync = ref.watch(userProfileProvider(otherUserId));
    final messagesAsync = ref.watch(messagesProvider(widget.chatRoom.id));
    final typingAsync = ref.watch(typingStatusProvider(widget.chatRoom.id));

    return Scaffold(
      appBar: AppBar(
        title: otherUserAsync.when(
          data: (user) => Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor:
                    Theme.of(context).primaryColor.withValues(alpha: 0.1),
                child: user?.photos.isNotEmpty == true
                    ? ClipOval(
                        child: Image.network(
                          user!.photos.first,
                          width: 32,
                          height: 32,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              const Icon(Icons.person, size: 16),
                        ),
                      )
                    : Text(user?.displayName?.isNotEmpty == true
                        ? user!.displayName![0].toUpperCase()
                        : '?'),
              ),
              const SizedBox(width: 8),
              Text(user?.displayName ?? 'Unknown User'),
            ],
          ),
          loading: () => const Text('Loading...'),
          error: (error, stack) => const Text('Error'),
        ),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              switch (value) {
                case 'block':
                  _showBlockUserDialog();
                  break;
                case 'report':
                  _showReportUserDialog();
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'block',
                child: Text('Block User'),
              ),
              const PopupMenuItem(
                value: 'report',
                child: Text('Report User'),
              ),
            ],
          ),
        ],
>>>>>>> origin/develop
      ),
      body: Column(
        children: [
          Expanded(
<<<<<<< HEAD
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: messaging.streamMessages(widget.conversationId),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final messages = snapshot.data!;

                // Auto-scroll and markAsRead when new messages arrive.
                if (messages.length != _lastMessageCount) {
                  _lastMessageCount = messages.length;
                  _scrollToBottom();

                  // Mark as read only if the latest message is from the other user.
                  if (messages.isNotEmpty &&
                      messages.last['senderId'] != currentUser.id) {
                    WidgetsBinding.instance.addPostFrameCallback(
                        (_) => _markAsRead());
                  }
                }

                if (messages.isEmpty) {
                  return const Center(
=======
            child: messagesAsync.when(
              data: (messages) => messages.isEmpty
                  ? const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.chat_bubble_outline,
                              size: 64, color: Colors.grey),
                          SizedBox(height: 16),
                          Text(
                            'No messages yet',
                            style: TextStyle(fontSize: 18, color: Colors.grey),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Start the conversation!',
                            style: TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.all(16),
                      itemCount: messages.length,
                      itemBuilder: (context, index) {
                        final message = messages[index];
                        final isCurrentUser = message.senderId == currentUserId;
                        final showTimestamp = index == 0 ||
                            messages[index - 1]
                                    .timestamp
                                    .difference(message.timestamp)
                                    .inMinutes >
                                5;

                        return MessageBubble(
                          message: message,
                          isCurrentUser: isCurrentUser,
                          showTimestamp: showTimestamp,
                          onDelete: isCurrentUser
                              ? () => _showDeleteDialog(message)
                              : null,
                        );
                      },
                    ),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => Center(
                child: Text('Error loading messages: $error'),
              ),
            ),
          ),

          // Typing Indicator
          typingAsync.when(
            data: (isTyping) => isTyping
                ? Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    alignment: Alignment.centerLeft,
>>>>>>> origin/develop
                    child: Text(
                      'No messages yet. Say hello!',
                      style: TextStyle(color: Colors.grey),
                    ),
                  );
                }

                return ListView.builder(
                  controller: _scroll,
                  padding: const EdgeInsets.all(12),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final msg = messages[index];
                    final isMe = msg['senderId'] == currentUser.id;

                    return Align(
                      alignment: isMe
                          ? Alignment.centerRight
                          : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        constraints: BoxConstraints(
                          maxWidth:
                              MediaQuery.of(context).size.width * 0.75,
                        ),
                        decoration: BoxDecoration(
                          color: isMe
                              ? Colors.blueAccent
                              : Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          msg['text'] ?? '',
                          softWrap: true,
                          style: TextStyle(
                            color: isMe ? Colors.white : Colors.black87,
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),

          // Input bar — sits above keyboard thanks to Scaffold resizeToAvoidBottomInset.
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            color: Colors.grey.shade200,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: TextField(
<<<<<<< HEAD
                    controller: _controller,
                    minLines: 1,
=======
                    controller: _messageController,
                    decoration: const InputDecoration(
                      hintText: 'Type a message...',
                      border: OutlineInputBorder(),
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    ),
>>>>>>> origin/develop
                    maxLines: null,
                    textInputAction: TextInputAction.newline,
                    keyboardType: TextInputType.multiline,
                    decoration: const InputDecoration(
                      hintText: 'Message...',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.send),
<<<<<<< HEAD
                  onPressed: _canSend ? _sendMessage : null,
=======
                  onPressed: _messageController.text.trim().isEmpty
                      ? null
                      : _sendMessage,
                  color: Theme.of(context).primaryColor,
>>>>>>> origin/develop
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
<<<<<<< HEAD
=======

  void _showDeleteDialog(ChatMessage message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Message'),
        content: const Text('Are you sure you want to delete this message?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await ref.read(chatActionsProvider).deleteMessage(
                      widget.chatRoom.id,
                      message.id,
                    );
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed to delete message: $e')),
                  );
                }
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Future<void> _showAttachmentOptions() async {
    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Choose from Gallery'),
              onTap: () async {
                Navigator.pop(context);
                await _pickImageAttachment();
              },
            ),
            ListTile(
              leading: const Icon(Icons.attach_file),
              title: const Text('Attach File'),
              onTap: () async {
                Navigator.pop(context);
                await _pickFileAttachment();
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Take Photo'),
              onTap: () async {
                Navigator.pop(context);
                await _takePhoto();
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickImageAttachment() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(source: ImageSource.gallery);

      if (image != null) {
        final user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          final storageRef = FirebaseStorage.instance
              .ref()
              .child('chat_images')
              .child(
                  '${user.uid}_${DateTime.now().millisecondsSinceEpoch}.jpg');

          await storageRef.putFile(File(image.path));
          final downloadUrl = await storageRef.getDownloadURL();

          // TODO: Send message with image URL to Firestore
          debugPrint('Image uploaded to: $downloadUrl');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Image uploaded successfully')),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to upload image: $e')),
        );
      }
    }
  }

  Future<void> _pickFileAttachment() async {
    try {
      final FilePickerResult? result = await FilePicker.platform.pickFiles();

      if (result != null) {
        final file = File(result.files.single.path!);
        final user = FirebaseAuth.instance.currentUser;

        if (user != null) {
          final storageRef = FirebaseStorage.instance
              .ref()
              .child('chat_files')
              .child(
                  '${user.uid}_${DateTime.now().millisecondsSinceEpoch}_${result.files.single.name}');

          await storageRef.putFile(file);
          final downloadUrl = await storageRef.getDownloadURL();

          // TODO: Send message with file URL to Firestore
          debugPrint('File uploaded to: $downloadUrl');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('File uploaded successfully')),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to upload file: $e')),
        );
      }
    }
  }

  Future<void> _takePhoto() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? photo = await picker.pickImage(source: ImageSource.camera);

      if (photo != null) {
        final user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          final storageRef = FirebaseStorage.instance
              .ref()
              .child('chat_photos')
              .child(
                  '${user.uid}_${DateTime.now().millisecondsSinceEpoch}.jpg');

          await storageRef.putFile(File(photo.path));
          final downloadUrl = await storageRef.getDownloadURL();

          // TODO: Send message with photo URL to Firestore
          debugPrint('Photo uploaded to: $downloadUrl');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Photo uploaded successfully')),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to take photo: $e')),
        );
      }
    }
  }

  void _showBlockUserDialog() {
    final otherUserId = widget.chatRoom.participants
        .firstWhere((id) => id != FirebaseAuth.instance.currentUser?.uid);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Block User'),
        content: const Text(
          'Are you sure you want to block this user? '
          'You will no longer receive messages from them.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _blockUser(otherUserId);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Block'),
          ),
        ],
      ),
    );
  }

  Future<void> _blockUser(String blockedUserId) async {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    if (currentUserId == null) return;

    try {
      final moderationService = ModerationService();
      await moderationService.blockUser(currentUserId, blockedUserId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('User blocked successfully')),
        );
        Navigator.pop(context); // Exit chat room
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to block user: $e')),
        );
      }
    }
  }

  void _showReportUserDialog() {
    final otherUserId = widget.chatRoom.participants
        .firstWhere((id) => id != FirebaseAuth.instance.currentUser?.uid);

    ReportType selectedType = ReportType.spam;
    final reasonController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Report User'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Why are you reporting this user?'),
                const SizedBox(height: 16),
                DropdownButtonFormField<ReportType>(
                  initialValue: selectedType,
                  decoration: const InputDecoration(
                    labelText: 'Report Type',
                    border: OutlineInputBorder(),
                  ),
                  items: ReportType.values.map((type) {
                    return DropdownMenuItem(
                      value: type,
                      child: Text(_formatReportType(type)),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => selectedType = value);
                    }
                  },
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: reasonController,
                  maxLines: 3,
                  maxLength: 500,
                  decoration: const InputDecoration(
                    labelText: 'Additional Details',
                    hintText: 'Describe the issue...',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                if (reasonController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please provide a reason')),
                  );
                  return;
                }
                Navigator.pop(context);
                await _reportUser(
                    otherUserId, selectedType, reasonController.text.trim());
              },
              style: TextButton.styleFrom(foregroundColor: Colors.orange),
              child: const Text('Report'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _reportUser(
      String reportedUserId, ReportType type, String description) async {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    if (currentUserId == null) return;

    try {
      final moderationService = ModerationService();
      await moderationService.reportUser(
        reporterId: currentUserId,
        reportedUserId: reportedUserId,
        roomId: widget.chatRoom.id,
        type: type,
        description: description,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Report submitted successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to submit report: $e')),
        );
      }
    }
  }

  String _formatReportType(ReportType type) {
    switch (type) {
      case ReportType.spam:
        return 'Spam';
      case ReportType.harassment:
        return 'Harassment';
      case ReportType.inappropriateContent:
        return 'Inappropriate Content';
      case ReportType.hateSpeech:
        return 'Hate Speech';
      case ReportType.violence:
        return 'Violence';
      case ReportType.scam:
        return 'Scam';
      case ReportType.other:
        return 'Other';
    }
  }
}

class MessageBubble extends StatelessWidget {
  final ChatMessage message;
  final bool isCurrentUser;
  final bool showTimestamp;
  final VoidCallback? onDelete;

  const MessageBubble({
    super.key,
    required this.message,
    required this.isCurrentUser,
    required this.showTimestamp,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment:
            isCurrentUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          if (showTimestamp)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Center(
                child: Text(
                  _formatTimestamp(message.timestamp),
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).textTheme.bodySmall?.color,
                  ),
                ),
              ),
            ),
          Row(
            mainAxisAlignment:
                isCurrentUser ? MainAxisAlignment.end : MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (!isCurrentUser) ...[
                const CircleAvatar(
                  radius: 16,
                  child: Icon(Icons.person, size: 16),
                ),
                const SizedBox(width: 8),
              ],
              Flexible(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: isCurrentUser
                        ? Theme.of(context).primaryColor
                        : Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color:
                          Theme.of(context).dividerColor.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (message.imageUrl != null)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              message.imageUrl!,
                              width: 200,
                              height: 200,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  const Icon(Icons.broken_image),
                            ),
                          ),
                        ),
                      Text(
                        message.content,
                        style: TextStyle(
                          color: isCurrentUser ? Colors.white : null,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (isCurrentUser && onDelete != null) ...[
                const SizedBox(width: 8),
                PopupMenuButton<String>(
                  icon: Icon(
                    Icons.more_vert,
                    size: 16,
                    color: Theme.of(context).textTheme.bodySmall?.color,
                  ),
                  onSelected: (value) {
                    if (value == 'delete') onDelete!();
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'delete',
                      child: Text('Delete'),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inDays == 0) {
      return 'Today ${timestamp.hour}:${timestamp.minute.toString().padLeft(2, '0')}';
    } else if (difference.inDays == 1) {
      return 'Yesterday ${timestamp.hour}:${timestamp.minute.toString().padLeft(2, '0')}';
    } else {
      return '${timestamp.month}/${timestamp.day} ${timestamp.hour}:${timestamp.minute.toString().padLeft(2, '0')}';
    }
  }
>>>>>>> origin/develop
}
