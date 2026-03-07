// lib/features/chat/screens/chat_conversation_page.dart
//
// Direct-message conversation page.
// Uses Riverpod auth, DesignColors, and shows read-receipt ticks.
// ----------------------------------------------------------------------
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../../core/design_system/design_constants.dart';
import '../../../shared/providers/auth_providers.dart';
import '../../../shared/providers/all_providers.dart';
import '../../../shared/widgets/club_background.dart';
import '../../../shared/widgets/presence_indicator.dart';
import '../../../utils/window_manager.dart';
import '../../../utils/window_sync_service.dart';

class ChatConversationPage extends ConsumerStatefulWidget {
  final String chatId;
  const ChatConversationPage({super.key, required this.chatId});

  @override
  ConsumerState<ChatConversationPage> createState() =>
      _ChatConversationPageState();
}

class _ChatConversationPageState
    extends ConsumerState<ChatConversationPage> {
  final TextEditingController _input = TextEditingController();
  final ScrollController _scroll = ScrollController();
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ── Send a message ─────────────────────────────────────────────────────
  Future<void> _send() async {
    final text = _input.text.trim();
    if (text.isEmpty) return;
    final user = ref.read(currentUserProvider).value;
    if (user == null) return;
    _input.clear();

    final ref2 = _db
        .collection('chats')
        .doc(widget.chatId)
        .collection('messages');

    await ref2.add({
      'text': text,
      'senderId': user.id,
      'senderName': user.displayName ?? user.nickname ?? 'You',
      'timestamp': FieldValue.serverTimestamp(),
      'readBy': [user.id],
    });

    // Bump the parent chat doc
    await _db.collection('chats').doc(widget.chatId).set({
      'lastMessage': text,
      'lastMessageTimestamp': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    _scroll.animateTo(0,
        duration: const Duration(milliseconds: 280), curve: Curves.easeOut);
  }

  // ── Mark messages as read ──────────────────────────────────────────────
  Future<void> _markRead(String userId, List<QueryDocumentSnapshot> docs) async {
    final batch = _db.batch();
    for (final doc in docs) {
      final data = doc.data() as Map<String, dynamic>;
      final readBy = List<String>.from(data['readBy'] ?? []);
      if (!readBy.contains(userId)) {
        batch.update(doc.reference, {
          'readBy': FieldValue.arrayUnion([userId]),
        });
      }
    }
    await batch.commit();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> _messagesStream() =>
      _db
          .collection('chats')
          .doc(widget.chatId)
          .collection('messages')
          .orderBy('timestamp', descending: true)
          .snapshots();

  @override
  void dispose() {
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider).value;

    return ClubBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: DesignColors.background.withValues(alpha: 0.85),
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_rounded,
                color: DesignColors.white, size: 20),
            onPressed: () => Navigator.of(context).maybePop(),
          ),
          title: _ChatAppBarTitle(chatId: widget.chatId),
          actions: [
            IconButton(
              icon: const Icon(Icons.open_in_new_rounded),
              tooltip: 'Pop Out Chat',
              onPressed: () {
                WindowSyncService.send('chat.popoutRequested', {
                  'chatId': widget.chatId,
                });
                WindowManager.openPrivateChat(widget.chatId);
              },
            ),
          ],
        ),
        body: Column(
          children: [
            Expanded(
              child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: _messagesStream(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                        child: CircularProgressIndicator(
                            color: DesignColors.accent));
                  }
                  if (snapshot.hasError) {
                    return Center(
                      child: Text('Error loading messages',
                          style: DesignTypography.body.copyWith(
                              color: DesignColors.error)),
                    );
                  }
                  final docs = snapshot.data?.docs ?? [];

                  // Mark new messages as read in background
                  if (user != null && docs.isNotEmpty) {
                    _markRead(user.id, docs);
                  }

                  if (docs.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.chat_bubble_outline_rounded,
                              size: 56,
                              color: DesignColors.white.withValues(alpha: 0.2)),
                          const SizedBox(height: 12),
                          Text('No messages yet. Say hello!',
                              style: DesignTypography.body.copyWith(
                                  color: DesignColors.white
                                      .withValues(alpha: 0.5))),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    controller: _scroll,
                    reverse: true,
                    padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
                    itemCount: docs.length,
                    itemBuilder: (context, index) {
                      final data = docs[index].data();
                      final text = data['text'] as String? ?? '';
                      final ts = (data['timestamp'] as Timestamp?)?.toDate();
                      final senderId = data['senderId'] as String? ?? '';
                      final isMe = senderId == user?.id;
                      final readBy =
                          List<String>.from(data['readBy'] ?? []);
                      final isRead = readBy.length >= 2;

                      return _MessageBubble(
                        text: text,
                        timestamp: ts,
                        isMe: isMe,
                        isRead: isMe ? isRead : null,
                      );
                    },
                  );
                },
              ),
            ),
            _buildInputBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildInputBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      color: DesignColors.surfaceDefault.withValues(alpha: 0.9),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _input,
                style: DesignTypography.body,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _send(),
                maxLines: null,
                decoration: InputDecoration(
                  hintText: 'Type a message...',
                  hintStyle: DesignTypography.body.copyWith(
                      color: DesignColors.white.withValues(alpha: 0.35)),
                  filled: true,
                  fillColor: DesignColors.surfaceLight,
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 18, vertical: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(26),
                    borderSide: BorderSide(
                        color: DesignColors.accent.withValues(alpha: 0.3)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(26),
                    borderSide: const BorderSide(
                        color: DesignColors.divider, width: 1),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(26),
                    borderSide: const BorderSide(
                        color: DesignColors.accent, width: 1.5),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            InkWell(
              onTap: _send,
              borderRadius: BorderRadius.circular(24),
              child: Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [DesignColors.accent, DesignColors.tertiary],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: DesignColors.accent.withValues(alpha: 0.4),
                      blurRadius: 12,
                    ),
                  ],
                ),
                child: const Icon(Icons.send_rounded,
                    color: DesignColors.white, size: 20),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Message bubble ──────────────────────────────────────────────────────
class _MessageBubble extends StatelessWidget {
  final String text;
  final DateTime? timestamp;
  final bool isMe;
  // null = other person's message (don't show receipt on their side)
  final bool? isRead;

  const _MessageBubble({
    required this.text,
    required this.timestamp,
    required this.isMe,
    this.isRead,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: EdgeInsets.only(
          bottom: 6,
          left: isMe ? 60 : 0,
          right: isMe ? 0 : 60,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.72),
        decoration: BoxDecoration(
          gradient: isMe
              ? LinearGradient(
                  colors: [
                    DesignColors.accent.withValues(alpha: 0.9),
                    DesignColors.tertiary.withValues(alpha: 0.8),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          color: isMe ? null : DesignColors.surfaceLight,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isMe ? 16 : 4),
            bottomRight: Radius.circular(isMe ? 4 : 16),
          ),
          boxShadow: isMe
              ? [
                  BoxShadow(
                    color: DesignColors.accent.withValues(alpha: 0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Column(
          crossAxisAlignment:
              isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(text,
                style: DesignTypography.body
                    .copyWith(color: DesignColors.white, fontSize: 15)),
            const SizedBox(height: 3),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (timestamp != null)
                  Text(
                    timeago.format(timestamp!),
                    style: TextStyle(
                      color: DesignColors.white.withValues(alpha: 0.55),
                      fontSize: 10,
                    ),
                  ),
                if (isMe && isRead != null) ...[
                  const SizedBox(width: 4),
                  Icon(
                    isRead! ? Icons.done_all_rounded : Icons.check_rounded,
                    size: 13,
                    color: isRead!
                        ? DesignColors.accent
                        : DesignColors.white.withValues(alpha: 0.5),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// Chat AppBar title: other user's name + real-time presence dot
// ─────────────────────────────────────────────────────────────────
class _ChatAppBarTitle extends ConsumerWidget {
  final String chatId;

  const _ChatAppBarTitle({required this.chatId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = ref.watch(currentUserProvider).value;

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('chats').doc(chatId).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || !snapshot.data!.exists) {
          return Text('Chat',
              style: DesignTypography.heading.copyWith(
                  color: DesignColors.white, fontSize: 18));
        }

        final data = snapshot.data!.data() as Map<String, dynamic>;
        final participants = List<String>.from(data['participants'] ?? []);
        final otherUserId = participants.firstWhere(
          (id) => id != currentUser?.id,
          orElse: () => participants.isNotEmpty ? participants.first : '',
        );

        if (otherUserId.isEmpty) {
          return Text('Chat',
              style: DesignTypography.heading.copyWith(
                  color: DesignColors.white, fontSize: 18));
        }

        final otherUserAsync = ref.watch(userProfileProvider(otherUserId));
        final displayName = otherUserAsync.value?.displayName ??
            otherUserAsync.value?.username ??
            'Chat';

        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: Text(
                displayName,
                style: DesignTypography.heading.copyWith(
                  color: DesignColors.white,
                  fontSize: 18,
                  shadows: DesignColors.primaryGlow,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            PresenceIndicatorWithLabel(userId: otherUserId),
          ],
        );
      },
    );
  }
}
