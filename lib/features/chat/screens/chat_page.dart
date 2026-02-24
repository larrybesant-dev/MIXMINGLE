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
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    controller.addListener(_onTextChanged);
  }

  void _onTextChanged() {
    if (controller.text.isNotEmpty && widget.chatId != null) {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null) {
        final typingService = ref.read(typingServiceProvider);
        typingService.startTyping(
          widget.chatId!,
          currentUser.uid,
          currentUser.displayName ?? 'User',
        );
      }
    }
  }

  @override
  void dispose() {
    controller.dispose();
    if (widget.chatId != null) {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null) {
        final typingService = ref.read(typingServiceProvider);
        typingService.stopTyping(widget.chatId!, currentUser.uid);
      }
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
                builder: (BuildContext context,
                    AsyncSnapshot<List<ChatMessage>?> snap) {
                  if (!snap.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final messages = snap.data!;
                  return ListView.builder(
                    reverse: true,
                    itemCount: messages.length,
                    itemBuilder: (ctx, i) {
                      final msg = messages[messages.length - 1 - i];
                      final senderId = msg.senderId;
                      final currentUser = FirebaseAuth.instance.currentUser;
                      final isCurrentUser = senderId == currentUser?.uid;

                      return Align(
                        alignment: isCurrentUser
                            ? Alignment.centerRight
                            : Alignment.centerLeft,
                        child: Container(
                          margin: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          padding: const EdgeInsets.all(12),
                          constraints: BoxConstraints(
                            maxWidth: MediaQuery.of(context).size.width * 0.7,
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
                              if (!isCurrentUser)
                                _SenderNameWidget(
                                  senderId: senderId,
                                  ref: ref,
                                ),
                              if (!isCurrentUser) const SizedBox(height: 4),
                              Text(
                                msg.content,
                                style: const TextStyle(color: Colors.white),
                              ),
                            ],
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
