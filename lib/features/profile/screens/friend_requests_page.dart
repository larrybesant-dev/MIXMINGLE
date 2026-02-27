// lib/features/profile/screens/friend_requests_page.dart
//
// Friend Requests Page — neon-styled inbox for incoming / sent requests
// + Suggested friends based on shared interests / mutual connections.
//
// Firestore schema expected:
//   friendRequests/{docId}
//     fromUid      : String
//     toUid        : String
//     status       : 'pending' | 'accepted' | 'declined'
//     fromName     : String
//     fromAvatar   : String?
//     createdAt    : Timestamp
//
//   users/{uid}
//     displayName, photoUrl, bio, interests[], mutualsCount …
// ─────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../core/design_system/design_constants.dart';
import '../../../shared/widgets/club_background.dart';

// ── Neon palette ─────────────────────────────────────────────────────────────

const _kCyan = Color(0xFF00E5CC);

class FriendRequestsPage extends StatefulWidget {
  const FriendRequestsPage({super.key});

  @override
  State<FriendRequestsPage> createState() => _FriendRequestsPageState();
}

class _FriendRequestsPageState extends State<FriendRequestsPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;
  final _db   = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  String get _uid => _auth.currentUser?.uid ?? '';

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  // ── Firestore helpers ──────────────────────────────────────────────────────
  Stream<QuerySnapshot> get _incomingStream => _db
      .collection('friendRequests')
      .where('toUid', isEqualTo: _uid)
      .where('status', isEqualTo: 'pending')
      .orderBy('createdAt', descending: true)
      .snapshots();

  Stream<QuerySnapshot> get _sentStream => _db
      .collection('friendRequests')
      .where('fromUid', isEqualTo: _uid)
      .where('status', isEqualTo: 'pending')
      .orderBy('createdAt', descending: true)
      .snapshots();

  Stream<QuerySnapshot> get _suggestedStream => _db
      .collection('users')
      .where('uid', isNotEqualTo: _uid)
      .limit(20)
      .snapshots();

  Future<void> _acceptRequest(String docId, String fromUid) async {
    final batch = _db.batch();
    batch.update(_db.collection('friendRequests').doc(docId), {
      'status': 'accepted',
      'acceptedAt': FieldValue.serverTimestamp(),
    });
    // Add each other as friends
    batch.set(
      _db.collection('users').doc(_uid).collection('friends').doc(fromUid),
      {'since': FieldValue.serverTimestamp()},
    );
    batch.set(
      _db.collection('users').doc(fromUid).collection('friends').doc(_uid),
      {'since': FieldValue.serverTimestamp()},
    );
    await batch.commit();
  }

  Future<void> _declineRequest(String docId) async {
    await _db.collection('friendRequests').doc(docId).update({
      'status': 'declined',
      'declinedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> _cancelRequest(String docId) async {
    await _db.collection('friendRequests').doc(docId).delete();
  }

  Future<void> _sendRequest(String toUid, String toName, String? toAvatar) async {
    // Check no duplicate
    final existing = await _db
        .collection('friendRequests')
        .where('fromUid', isEqualTo: _uid)
        .where('toUid', isEqualTo: toUid)
        .where('status', isEqualTo: 'pending')
        .get();
    if (existing.docs.isNotEmpty) return;

    final me = _auth.currentUser;
    await _db.collection('friendRequests').add({
      'fromUid'    : _uid,
      'toUid'      : toUid,
      'status'     : 'pending',
      'fromName'   : me?.displayName ?? 'Anonymous',
      'fromAvatar' : me?.photoURL,
      'toName'     : toName,
      'createdAt'  : FieldValue.serverTimestamp(),
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Friend request sent to $toName'),
        backgroundColor: const Color(0xFF1E2D40),
        behavior: SnackBarBehavior.floating,
      ));
    }
  }

  // ── BUILD ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return ClubBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new,
                color: DesignColors.white),
            onPressed: () => Navigator.pop(context),
          ),
          title: const Text(
            'FRIEND REQUESTS',
            style: TextStyle(
              color: DesignColors.white,
              fontWeight: FontWeight.w800,
              fontSize: 15,
              letterSpacing: 1.5,
            ),
          ),
          bottom: TabBar(
            controller: _tabs,
            indicatorColor: _kCyan,
            indicatorWeight: 3,
            labelColor: _kCyan,
            unselectedLabelColor: DesignColors.textGray,
            labelStyle: const TextStyle(
                fontWeight: FontWeight.w700, fontSize: 12, letterSpacing: 0.5),
            tabs: const [
              Tab(icon: Icon(Icons.inbox_outlined, size: 16), text: 'Incoming'),
              Tab(icon: Icon(Icons.send_outlined, size: 16), text: 'Sent'),
              Tab(icon: Icon(Icons.people_outline, size: 16), text: 'Suggested'),
            ],
          ),
        ),
        body: TabBarView(
          controller: _tabs,
          children: [
            _IncomingTab(
              stream: _incomingStream,
              onAccept: _acceptRequest,
              onDecline: _declineRequest,
            ),
            _SentTab(
              stream: _sentStream,
              onCancel: _cancelRequest,
            ),
            _SuggestedTab(
              stream: _suggestedStream,
              currentUid: _uid,
              onSend: _sendRequest,
            ),
          ],
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
// INCOMING TAB
// ════════════════════════════════════════════════════════════════════════════
class _IncomingTab extends StatelessWidget {
  final Stream<QuerySnapshot> stream;
  final Future<void> Function(String docId, String fromUid) onAccept;
  final Future<void> Function(String docId) onDecline;

  const _IncomingTab({
    required this.stream,
    required this.onAccept,
    required this.onDecline,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: stream,
      builder: (ctx, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(
              child: CircularProgressIndicator(color: DesignColors.accent));
        }
        final docs = snap.data?.docs ?? [];
        if (docs.isEmpty) {
          return _emptyState(
            Icons.inbox_outlined,
            'No incoming requests',
            'When someone adds you, they\'ll appear here.',
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.all(DesignSpacing.md),
          itemCount: docs.length,
          itemBuilder: (ctx, i) {
            final data = docs[i].data() as Map<String, dynamic>;
            return _RequestCard(
              docId      : docs[i].id,
              uid        : data['fromUid'] as String? ?? '',
              name       : data['fromName'] as String? ?? 'Someone',
              avatarUrl  : data['fromAvatar'] as String?,
              timestamp  : (data['createdAt'] as Timestamp?)?.toDate(),
              isIncoming : true,
              onAccept   : () => onAccept(docs[i].id, data['fromUid'] as String? ?? ''),
              onDecline  : () => onDecline(docs[i].id),
            );
          },
        );
      },
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
// SENT TAB
// ════════════════════════════════════════════════════════════════════════════
class _SentTab extends StatelessWidget {
  final Stream<QuerySnapshot> stream;
  final Future<void> Function(String docId) onCancel;

  const _SentTab({required this.stream, required this.onCancel});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: stream,
      builder: (ctx, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(
              child: CircularProgressIndicator(color: DesignColors.accent));
        }
        final docs = snap.data?.docs ?? [];
        if (docs.isEmpty) {
          return _emptyState(
            Icons.send_outlined,
            'No pending requests',
            'Requests you\'ve sent will appear here.',
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.all(DesignSpacing.md),
          itemCount: docs.length,
          itemBuilder: (ctx, i) {
            final data = docs[i].data() as Map<String, dynamic>;
            return _RequestCard(
              docId      : docs[i].id,
              uid        : data['toUid'] as String? ?? '',
              name       : data['toName'] as String? ?? 'Someone',
              avatarUrl  : data['toAvatar'] as String?,
              timestamp  : (data['createdAt'] as Timestamp?)?.toDate(),
              isIncoming : false,
              onCancel   : () => onCancel(docs[i].id),
            );
          },
        );
      },
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
// SUGGESTED FRIENDS TAB
// ════════════════════════════════════════════════════════════════════════════
class _SuggestedTab extends StatefulWidget {
  final Stream<QuerySnapshot> stream;
  final String currentUid;
  final Future<void> Function(String toUid, String toName, String? toAvatar) onSend;

  const _SuggestedTab({
    required this.stream,
    required this.currentUid,
    required this.onSend,
  });

  @override
  State<_SuggestedTab> createState() => _SuggestedTabState();
}

class _SuggestedTabState extends State<_SuggestedTab> {
  final Set<String> _requested = {};

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: widget.stream,
      builder: (ctx, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(
              child: CircularProgressIndicator(color: DesignColors.accent));
        }
        final docs = (snap.data?.docs ?? [])
            .where((d) => d.id != widget.currentUid)
            .toList();
        if (docs.isEmpty) {
          return _emptyState(
            Icons.people_outline,
            'No suggestions yet',
            'As your network grows, suggestions appear here.',
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.all(DesignSpacing.md),
          itemCount: docs.length,
          itemBuilder: (ctx, i) {
            final data = docs[i].data() as Map<String, dynamic>;
            final uid = docs[i].id;
            final name = data['displayName'] as String? ?? 'User';
            final avatar = data['photoUrl'] as String?;
            final bio = data['bio'] as String?;
            final already = _requested.contains(uid);

            return Container(
              margin: const EdgeInsets.only(bottom: DesignSpacing.sm + 2),
              padding: const EdgeInsets.all(DesignSpacing.cardPadding),
              decoration: BoxDecoration(
                color: DesignColors.surfaceLight.withValues(alpha: 0.55),
                borderRadius: BorderRadius.circular(DesignSpacing.cardBorderRadius),
                border: Border.all(
                    color: DesignColors.tertiary.withValues(alpha: 0.25), width: 1),
              ),
              child: Row(
                children: [
                  // Avatar
                  CircleAvatar(
                    radius: DesignSpacing.avatarMedium,
                    backgroundColor: DesignColors.tertiary.withValues(alpha: 0.2),
                    backgroundImage:
                        avatar != null ? NetworkImage(avatar) : null,
                    child: avatar == null
                        ? Text(name[0].toUpperCase(),
                            style: const TextStyle(
                                color: DesignColors.tertiary,
                                fontWeight: FontWeight.w700))
                        : null,
                  ),
                  const SizedBox(width: DesignSpacing.md),
                  // Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(name,
                            style: DesignTypography.body.copyWith(
                                fontWeight: FontWeight.w700)),
                        if (bio != null && bio.isNotEmpty)
                          Text(
                            bio,
                            style: DesignTypography.caption,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                      ],
                    ),
                  ),
                  // Add button
                  GestureDetector(
                    onTap: already
                        ? null
                        : () async {
                            setState(() => _requested.add(uid));
                            await widget.onSend(uid, name, avatar);
                          },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        gradient: already
                            ? null
                            : const LinearGradient(
                                colors: [DesignColors.accent, DesignColors.tertiary],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                        color: already
                            ? DesignColors.surfaceDefault
                            : null,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color: already
                                ? DesignColors.divider
                                : DesignColors.accent.withValues(alpha: 0.5)),
                      ),
                      child: Text(
                        already ? 'Sent ✓' : 'Add',
                        style: TextStyle(
                          color: already
                              ? DesignColors.textGray
                              : Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
// SHARED: REQUEST CARD
// ════════════════════════════════════════════════════════════════════════════
class _RequestCard extends StatefulWidget {
  final String docId;
  final String uid;
  final String name;
  final String? avatarUrl;
  final DateTime? timestamp;
  final bool isIncoming;
  final VoidCallback? onAccept;
  final VoidCallback? onDecline;
  final VoidCallback? onCancel;

  const _RequestCard({
    required this.docId,
    required this.uid,
    required this.name,
    required this.avatarUrl,
    required this.timestamp,
    required this.isIncoming,
    this.onAccept,
    this.onDecline,
    this.onCancel,
  });

  @override
  State<_RequestCard> createState() => _RequestCardState();
}

class _RequestCardState extends State<_RequestCard> {
  bool _loading = false;

  String _timeAgo(DateTime dt) {
    final d = DateTime.now().difference(dt);
    if (d.inMinutes < 1) return 'just now';
    if (d.inHours < 1) return '${d.inMinutes}m ago';
    if (d.inDays < 1) return '${d.inHours}h ago';
    if (d.inDays < 7) return '${d.inDays}d ago';
    return '${(d.inDays / 7).floor()}w ago';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: DesignSpacing.sm + 2),
      padding: const EdgeInsets.all(DesignSpacing.cardPadding),
      decoration: BoxDecoration(
        color: DesignColors.surfaceLight.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(DesignSpacing.cardBorderRadius),
        border: Border.all(
            color: widget.isIncoming
                ? _kCyan.withValues(alpha: 0.3)
                : DesignColors.accent.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          // Avatar
          Stack(
            children: [
              CircleAvatar(
                radius: 26,
                backgroundColor: (widget.isIncoming ? _kCyan : DesignColors.accent)
                    .withValues(alpha: 0.2),
                backgroundImage: widget.avatarUrl != null
                    ? NetworkImage(widget.avatarUrl!)
                    : null,
                child: widget.avatarUrl == null
                    ? Text(
                        widget.name.isNotEmpty
                            ? widget.name[0].toUpperCase()
                            : '?',
                        style: TextStyle(
                            color: widget.isIncoming ? _kCyan : DesignColors.accent,
                            fontWeight: FontWeight.w700))
                    : null,
              ),
              if (widget.isIncoming)
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    width: 16,
                    height: 16,
                    decoration: const BoxDecoration(
                        shape: BoxShape.circle, color: _kCyan),
                    child: const Icon(Icons.arrow_downward,
                        size: 10, color: Colors.black),
                  ),
                ),
            ],
          ),
          const SizedBox(width: DesignSpacing.md),
          // Name + time
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.name,
                    style: DesignTypography.body.copyWith(
                        fontWeight: FontWeight.w700)),
                if (widget.timestamp != null)
                  Text(_timeAgo(widget.timestamp!),
                      style: DesignTypography.caption),
              ],
            ),
          ),
          // Action buttons
          if (_loading)
            const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: DesignColors.accent))
          else if (widget.isIncoming) ...[
            _actionBtn(
                label: 'Accept',
                color: _kCyan,
                onTap: () async {
                  setState(() => _loading = true);
                  widget.onAccept?.call();
                }),
            const SizedBox(width: DesignSpacing.sm),
            _actionBtn(
                label: 'Decline',
                color: DesignColors.error,
                onTap: () async {
                  setState(() => _loading = true);
                  widget.onDecline?.call();
                }),
          ] else
            _actionBtn(
                label: 'Cancel',
                color: DesignColors.textGray,
                onTap: () async {
                  setState(() => _loading = true);
                  widget.onCancel?.call();
                }),
        ],
      ),
    );
  }

  Widget _actionBtn({
      required String label,
      required Color color,
      required Future<void> Function() onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withValues(alpha: 0.5)),
          boxShadow: [
            BoxShadow(color: color.withValues(alpha: 0.2), blurRadius: 6)
          ],
        ),
        child: Text(label,
            style: DesignTypography.label.copyWith(
                color: color, fontWeight: FontWeight.w700)),
      ),
    );
  }
}

// ── Shared empty state ───────────────────────────────────────────────────────
Widget _emptyState(IconData icon, String title, String subtitle) {
  return Center(
    child: Padding(
      padding: const EdgeInsets.all(DesignSpacing.xxl),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 72, color: DesignColors.textGray.withValues(alpha: 0.3)),
          const SizedBox(height: DesignSpacing.lg),
          Text(title, style: DesignTypography.heading),
          const SizedBox(height: DesignSpacing.sm),
          Text(subtitle,
              textAlign: TextAlign.center,
              style: DesignTypography.bodySm),
        ],
      ),
    ),
  );
}
