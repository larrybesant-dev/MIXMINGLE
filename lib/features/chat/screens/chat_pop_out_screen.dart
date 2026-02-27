// lib/features/chat/screens/chat_pop_out_screen.dart
//
// Yahoo Messenger-style pop-out chat window.
// Opened by WebWindowService.openChat(chatId, peerName).
// URL: /buddy-chat?chatId=abc_xyz&name=Alice
// ─────────────────────────────────────────────────────────────────────────

import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../../core/design_system/design_constants.dart';

class ChatPopOutScreen extends StatefulWidget {
  final String chatId;
  final String peerName;

  const ChatPopOutScreen({
    super.key,
    required this.chatId,
    required this.peerName,
  });

  @override
  State<ChatPopOutScreen> createState() => _ChatPopOutScreenState();
}

class _ChatPopOutScreenState extends State<ChatPopOutScreen> {
  final _input = TextEditingController();
  final _scroll = ScrollController();
  final _db = FirebaseFirestore.instance;

  String? _myUid;
  String? _peerUid;
  String? _peerPhotoUrl;
  bool _peerOnline = false;
  bool _peerTyping = false;
  bool _isSending = false;

  Timer? _typingTimer;
  StreamSubscription? _presenceSub;
  StreamSubscription? _typingSub;

  @override
  void initState() {
    super.initState();
    _myUid = FirebaseAuth.instance.currentUser?.uid;
    _resolvePeer();
  }

  // ── Resolve peer uid from chatId (format: uid1_uid2) ─────────────────

  void _resolvePeer() {
    if (_myUid == null) return;
    final parts = widget.chatId.split('_');
    if (parts.length >= 2) {
      _peerUid = parts.firstWhere((p) => p != _myUid, orElse: () => parts[0]);
      _loadPeerProfile();
      _listenPresence();
      _listenTyping();
    }
  }

  Future<void> _loadPeerProfile() async {
    if (_peerUid == null) return;
    final doc =
        await _db.collection('users').doc(_peerUid).get();
    if (!mounted) return;
    final data = doc.data();
    setState(() {
      _peerPhotoUrl = data?['photoUrl'] as String?;
      _peerOnline = data?['isOnline'] == true ||
          data?['presence'] == 'online';
    });
  }

  void _listenPresence() {
    if (_peerUid == null) return;
    _presenceSub = _db
        .collection('users')
        .doc(_peerUid)
        .snapshots()
        .listen((s) {
      if (!mounted) return;
      final d = s.data();
      setState(() {
        _peerOnline = d?['isOnline'] == true || d?['presence'] == 'online';
        _peerPhotoUrl = d?['photoUrl'] as String? ?? _peerPhotoUrl;
      });
    });
  }

  void _listenTyping() {
    if (_peerUid == null) return;
    _typingSub = _db
        .collection('chatRooms')
        .doc(widget.chatId)
        .collection('typing')
        .doc(_peerUid)
        .snapshots()
        .listen((s) {
      if (!mounted) return;
      setState(() => _peerTyping = s.data()?['isTyping'] == true);
    });
  }

  // ── Typing handling ────────────────────────────────────────────────────

  void _onTextChanged(String _) {
    if (_myUid == null) return;
    _db
        .collection('chatRooms')
        .doc(widget.chatId)
        .collection('typing')
        .doc(_myUid)
        .set({'isTyping': true, 'at': FieldValue.serverTimestamp()});

    _typingTimer?.cancel();
    _typingTimer = Timer(const Duration(seconds: 3), _clearTyping);
  }

  void _clearTyping() {
    if (_myUid == null) return;
    _db
        .collection('chatRooms')
        .doc(widget.chatId)
        .collection('typing')
        .doc(_myUid)
        .set({'isTyping': false});
  }

  // ── Send message ───────────────────────────────────────────────────────

  Future<void> _send() async {
    final text = _input.text.trim();
    if (text.isEmpty || _isSending) return;
    final uid = _myUid;
    if (uid == null) return;

    setState(() => _isSending = true);
    _input.clear();
    _clearTyping();

    final user = FirebaseAuth.instance.currentUser;

    try {
      final msgRef = _db
          .collection('chatRooms')
          .doc(widget.chatId)
          .collection('messages')
          .doc();
      await msgRef.set({
        'id': msgRef.id,
        'content': text,
        'senderId': uid,
        'senderName': user?.displayName ?? 'Me',
        'timestamp': FieldValue.serverTimestamp(),
        'isRead': false,
      });

      final peerUid = _peerUid ?? '';
      final roomUpdate = <String, dynamic>{
        'participants': ([uid, peerUid]..sort()),
        'lastMessage': text,
        'lastMessageTime': Timestamp.now(),
        'lastSenderId': uid,
      };
      if (peerUid.isNotEmpty) {
        roomUpdate['unreadCounts.$peerUid'] = FieldValue.increment(1);
      }
      await _db.collection('chatRooms').doc(widget.chatId)
          .set(roomUpdate, SetOptions(merge: true));

      _scroll.animateTo(
        _scroll.position.maxScrollExtent + 100,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  // ── Mark messages read ─────────────────────────────────────────────────

  Future<void> _markRead(List<QueryDocumentSnapshot> docs) async {
    final uid = _myUid;
    if (uid == null) return;
    final batch = _db.batch();
    for (final doc in docs) {
      final data = doc.data() as Map<String, dynamic>;
      final senderId = (data['senderId'] as String?) ?? '';
      final isAlreadyRead = data['isRead'] == true;
      if (senderId != uid && !isAlreadyRead) {
        batch.update(doc.reference, {'isRead': true});
      }
    }
    // Reset this user's unread counter on the room doc
    batch.set(
      _db.collection('chatRooms').doc(widget.chatId),
      {'unreadCounts.$uid': 0},
      SetOptions(merge: true),
    );
    await batch.commit();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> _messagesStream() => _db
      .collection('chatRooms')
      .doc(widget.chatId)
      .collection('messages')
      .orderBy('timestamp', descending: false)
      .snapshots();

  @override
  void dispose() {
    _input.dispose();
    _scroll.dispose();
    _typingTimer?.cancel();
    _clearTyping();
    _presenceSub?.cancel();
    _typingSub?.cancel();
    super.dispose();
  }

  // ── Build ─────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0E0E1A),
      appBar: _buildAppBar(),
      body: Column(
        children: [
          Expanded(child: _buildMessageList()),
          if (_peerTyping) _buildTypingIndicator(),
          _buildQuickEmojis(),
          _buildInputBar(),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: const Color(0xFF12082A),
      elevation: 0,
      automaticallyImplyLeading: false,
      titleSpacing: 10,
      title: Row(children: [
        Stack(alignment: Alignment.bottomRight, children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: DesignColors.accent.withValues(alpha: 0.2),
            backgroundImage: _peerPhotoUrl != null
                ? NetworkImage(_peerPhotoUrl!)
                : null,
            child: _peerPhotoUrl == null
                ? Text(
                    widget.peerName.isNotEmpty
                        ? widget.peerName[0].toUpperCase()
                        : '?',
                    style: const TextStyle(
                        color: DesignColors.accent,
                        fontSize: 13,
                        fontWeight: FontWeight.bold),
                  )
                : null,
          ),
          Container(
            width: 9,
            height: 9,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _peerOnline
                  ? const Color(0xFF00E676)
                  : Colors.white24,
              border: Border.all(
                  color: const Color(0xFF12082A), width: 1.5),
            ),
          ),
        ]),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.peerName,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                _peerOnline ? 'Online' : 'Offline',
                style: TextStyle(
                  color: _peerOnline
                      ? const Color(0xFF00E676)
                      : Colors.white38,
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ),
      ]),
      actions: [
        IconButton(
          icon: const Icon(Icons.videocam_outlined,
              color: Colors.white54, size: 18),
          tooltip: 'Video call',
          onPressed: _peerUid != null
              ? () {
                  // Video call placeholder — hook Agora here
                }
              : null,
        ),
        IconButton(
          icon: const Icon(Icons.close, color: Colors.white38, size: 18),
          tooltip: 'Close',
          onPressed: () => Navigator.maybePop(context),
        ),
      ],
    );
  }

  Widget _buildMessageList() {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: _messagesStream(),
      builder: (ctx, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(
              child: CircularProgressIndicator(
                  color: DesignColors.accent, strokeWidth: 2));
        }

        final docs = snap.data?.docs ?? [];
        if (docs.isEmpty) {
          return Center(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              const Icon(Icons.chat_bubble_outline,
                  color: Colors.white12, size: 42),
              const SizedBox(height: 10),
              Text(
                'Say hi to ${widget.peerName}!',
                style: const TextStyle(color: Colors.white38, fontSize: 13),
              ),
            ]),
          );
        }

        // Mark incoming as read
        if (_myUid != null) _markRead(docs);

        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_scroll.hasClients) {
            _scroll.animateTo(
              _scroll.position.maxScrollExtent,
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOut,
            );
          }
        });

        return ListView.builder(
          controller: _scroll,
          padding: const EdgeInsets.fromLTRB(10, 8, 10, 6),
          itemCount: docs.length,
          itemBuilder: (_, i) {
            final data = docs[i].data();
            final text = (data['content'] as String?) ?? '';
            final ts = (data['timestamp'] as Timestamp?)?.toDate();
            final senderId = (data['senderId'] as String?) ?? '';
            final isMe = senderId == _myUid;
            final isRead = data['isRead'] == true;

            return _Bubble(
              text: text,
              timestamp: ts,
              isMe: isMe,
              isRead: isMe ? isRead : null,
            );
          },
        );
      },
    );
  }

  Widget _buildTypingIndicator() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 0, 14, 4),
      child: Row(children: [
        Text(
          '${widget.peerName} is typing',
          style: const TextStyle(color: Colors.white38, fontSize: 11),
        ),
        const SizedBox(width: 6),
        const _TypingDots(),
      ]),
    );
  }

  Widget _buildQuickEmojis() {
    const emojis = ['😂', '❤️', '🔥', '👏', '😍', '💯'];
    return SizedBox(
      height: 34,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        children: emojis
            .map((e) => GestureDetector(
                  onTap: () {
                    _input.text += e;
                    _input.selection = TextSelection.fromPosition(
                        TextPosition(offset: _input.text.length));
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Text(e, style: const TextStyle(fontSize: 20)),
                  ),
                ))
            .toList(),
      ),
    );
  }

  Widget _buildInputBar() {
    return Container(
      color: const Color(0xFF12082A),
      padding: const EdgeInsets.fromLTRB(10, 6, 10, 12),
      child: Row(children: [
        Expanded(
          child: TextField(
            controller: _input,
            style: const TextStyle(color: Colors.white, fontSize: 13),
            onChanged: _onTextChanged,
            onSubmitted: (_) => _send(),
            maxLines: null,
            decoration: InputDecoration(
              hintText: 'Message ${widget.peerName}…',
              hintStyle:
                  const TextStyle(color: Colors.white38, fontSize: 13),
              filled: true,
              fillColor: const Color(0xFF1A0A2A),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide.none),
            ),
          ),
        ),
        const SizedBox(width: 8),
        GestureDetector(
          onTap: _send,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _isSending
                  ? DesignColors.accent.withValues(alpha: 0.4)
                  : DesignColors.accent,
            ),
            child: Icon(
              _isSending ? Icons.hourglass_empty : Icons.send_rounded,
              color: Colors.white,
              size: 17,
            ),
          ),
        ),
      ]),
    );
  }
}

// ── Bubble ─────────────────────────────────────────────────────────────────

class _Bubble extends StatelessWidget {
  final String text;
  final DateTime? timestamp;
  final bool isMe;
  final bool? isRead;

  const _Bubble({
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
          bottom: 5,
          left: isMe ? 48 : 0,
          right: isMe ? 0 : 48,
        ),
        padding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          gradient: isMe
              ? LinearGradient(colors: [
                  DesignColors.accent.withValues(alpha: 0.9),
                  DesignColors.tertiary.withValues(alpha: 0.8),
                ])
              : null,
          color: isMe ? null : const Color(0xFF1E1A2E),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(14),
            topRight: const Radius.circular(14),
            bottomLeft: Radius.circular(isMe ? 14 : 3),
            bottomRight: Radius.circular(isMe ? 3 : 14),
          ),
        ),
        child: Column(
          crossAxisAlignment:
              isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(text,
                style: const TextStyle(
                    color: Colors.white, fontSize: 13)),
            const SizedBox(height: 3),
            Row(mainAxisSize: MainAxisSize.min, children: [
              if (timestamp != null)
                Text(
                  timeago.format(timestamp!),
                  style: const TextStyle(
                      color: Colors.white38, fontSize: 9),
                ),
              if (isMe && isRead != null) ...[
                const SizedBox(width: 3),
                Icon(
                  isRead! ? Icons.done_all_rounded : Icons.check_rounded,
                  size: 11,
                  color: isRead!
                      ? DesignColors.accent
                      : Colors.white38,
                ),
              ],
            ]),
          ],
        ),
      ),
    );
  }
}

// ── Animated typing dots ────────────────────────────────────────────────────

class _TypingDots extends StatefulWidget {
  const _TypingDots();

  @override
  State<_TypingDots> createState() => _TypingDotsState();
}

class _TypingDotsState extends State<_TypingDots>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 900))
      ..repeat();
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
      builder: (_, __) {
        final t = _ctrl.value;
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (i) {
            final phase = (t - i * 0.18).clamp(0.0, 1.0);
            final opacity = (phase < 0.5 ? phase * 2 : (1 - phase) * 2)
                .clamp(0.3, 1.0);
            return Container(
              width: 5,
              height: 5,
              margin: const EdgeInsets.symmetric(horizontal: 1.5),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white38.withValues(alpha: opacity),
              ),
            );
          }),
        );
      },
    );
  }
}
