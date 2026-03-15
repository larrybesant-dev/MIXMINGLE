// lib/features/buddy_list/buddy_list_screen.dart
//
// Standalone Yahoo Messenger-style Buddy List window.
// Opened via window.open('/buddy-list', 'buddyListWindow', ...).
//
// Shows:
//   • Search bar
//   • Online / Away / Offline sections
//   • Real-time presence via Firestore following sub-collection
//   • Click avatar → opens /buddy-profile in a new pop-out window
//   • Double-click → joins that friend's current room in a pop-out
//   • "Chat" action → opens /buddy-chat in a pop-out
// ─────────────────────────────────────────────────────────────────────────

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../core/design_system/design_constants.dart';
import '../../core/web/web_window_service.dart';

class BuddyListScreen extends StatefulWidget {
  const BuddyListScreen({super.key});

  @override
  State<BuddyListScreen> createState() => _BuddyListScreenState();
}

class _BuddyListScreenState extends State<BuddyListScreen> {
  final _search = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _search.dispose();
    // Tell the main window the buddy list was closed
    WebWindowService.persistWindowClosed('buddyList');
    super.dispose();
  }

  // ── Firestore stream: following list ────────────────────────────────────

  Stream<List<_BuddyEntry>> _buddiesStream() {
    final myUid = FirebaseAuth.instance.currentUser?.uid;
    if (myUid == null) return const Stream.empty();

    return FirebaseFirestore.instance
        .collection('users')
        .doc(myUid)
        .collection('following')
        .snapshots()
        .asyncMap((snap) async {
      if (snap.docs.isEmpty) return <_BuddyEntry>[];

      final uids = snap.docs.map((d) => d.id).take(200).toList();

      // Batch read profiles (Firestore whereIn limit = 30 per query)
      final entries = <_BuddyEntry>[];
      for (int i = 0; i < uids.length; i += 30) {
        final batch = uids.sublist(i, (i + 30).clamp(0, uids.length));
        final res = await FirebaseFirestore.instance
            .collection('users')
            .where(FieldPath.documentId, whereIn: batch)
            .get();
        for (final doc in res.docs) {
          final d = doc.data();
          entries.add(_BuddyEntry(
            uid: doc.id,
            displayName: (d['displayName'] as String?) ?? 'Unknown',
            photoUrl: d['photoUrl'] as String?,
            isOnline: d['isOnline'] == true || d['presence'] == 'online',
            isAway: d['presence'] == 'away',
            currentRoomId: d['currentRoomId'] as String?,
            currentRoomName: d['currentRoomName'] as String?,
          ));
        }
      }

      // Sort: online first, then away, then offline; alpha within group
      entries.sort((a, b) {
        final aRank = a.isOnline ? 0 : a.isAway ? 1 : 2;
        final bRank = b.isOnline ? 0 : b.isAway ? 1 : 2;
        if (aRank != bRank) return aRank.compareTo(bRank);
        return a.displayName.compareTo(b.displayName);
      });

      return entries;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0E0E1A),
      appBar: _buildAppBar(),
      body: Column(
        children: [
          _buildMyStatusBar(),
          _buildSearchBar(),
          Expanded(
            child: StreamBuilder<List<_BuddyEntry>>(
              stream: _buddiesStream(),
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(
                        color: DesignColors.accent),
                  );
                }
                if (!snap.hasData || snap.data!.isEmpty) {
                  return _buildEmpty();
                }
                final all = snap.data!;
                final filtered = _query.isEmpty
                    ? all
                    : all
                        .where((b) => b.displayName
                            .toLowerCase()
                            .contains(_query.toLowerCase()))
                        .toList();
                return _buildList(filtered);
              },
            ),
          ),
        ],
      ),
    );
  }

  // ── My Status bar ──────────────────────────────────────────────────────────

  static const _statuses = [
    ('Online', Color(0xFF00E676), 'online'),
    ('Away', Color(0xFFFFAB00), 'away'),
    ('Busy', Color(0xFFFF4C4C), 'busy'),
    ('Invisible', Colors.white24, 'offline'),
  ];

  String _myStatus = 'online';

  void _setStatus(String status) {
    final myUid = FirebaseAuth.instance.currentUser?.uid;
    if (myUid == null) return;
    setState(() => _myStatus = status);
    FirebaseFirestore.instance.collection('users').doc(myUid).update({
      'presence': status,
      'isOnline': status == 'online',
    });
  }

  Widget _buildMyStatusBar() {
    return Container(
      color: const Color(0xFF12082A),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      child: Row(
        children: [
          const Text('Status:',
              style: TextStyle(color: Colors.white38, fontSize: 11)),
          const SizedBox(width: 8),
          ..._statuses.map((s) {
            final isSelected = _myStatus == s.$3;
            return GestureDetector(
              onTap: () => _setStatus(s.$3),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                margin: const EdgeInsets.only(right: 6),
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: isSelected
                      ? s.$2.withValues(alpha: 0.2)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected
                        ? s.$2
                        : Colors.white12,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 7,
                      height: 7,
                      decoration: BoxDecoration(
                          shape: BoxShape.circle, color: s.$2),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      s.$1,
                      style: TextStyle(
                        color: isSelected ? s.$2 : Colors.white38,
                        fontSize: 10,
                        fontWeight: isSelected
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  // ── App Bar ─────────────────────────────────────────────────────────────

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: const Color(0xFF12082A),
      elevation: 0,
      automaticallyImplyLeading: false,
      titleSpacing: 12,
      title: Row(children: [
        Container(
          width: 9,
          height: 9,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: DesignColors.accent,
            boxShadow: [
              BoxShadow(
                  color: DesignColors.accent.withValues(alpha: 0.8),
                  blurRadius: 8),
            ],
          ),
        ),
        const SizedBox(width: 8),
        const Text(
          'Friends',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.8,
          ),
        ),
      ]),
      actions: [
        IconButton(
          icon: const Icon(Icons.close, color: Colors.white54, size: 18),
          tooltip: 'Close',
          onPressed: () {
            WebWindowService.persistWindowClosed('buddyList');
            // On web, closing the pop-out window happens naturally when the
            // user closes the browser tab — we just persist the state.
          },
        ),
      ],
    );
  }

  // ── Search bar ──────────────────────────────────────────────────────────

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 4),
      child: TextField(
        controller: _search,
        style: const TextStyle(color: Colors.white, fontSize: 13),
        decoration: InputDecoration(
          hintText: 'Search friends…',
          hintStyle: const TextStyle(color: Colors.white38, fontSize: 13),
          prefixIcon:
              const Icon(Icons.search, color: Colors.white38, size: 18),
          filled: true,
          fillColor: const Color(0xFF1E1A2E),
          contentPadding:
              const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
            borderSide: BorderSide.none,
          ),
        ),
        onChanged: (v) => setState(() => _query = v),
      ),
    );
  }

  // ── List ────────────────────────────────────────────────────────────────

  Widget _buildList(List<_BuddyEntry> entries) {
    // Group by status
    final online = entries.where((e) => e.isOnline).toList();
    final away = entries.where((e) => !e.isOnline && e.isAway).toList();
    final offline = entries.where((e) => !e.isOnline && !e.isAway).toList();

    return ListView(
      children: [
        if (online.isNotEmpty) ...[
          _sectionHeader(
              'Online', online.length, const Color(0xFF00E676)),
          ...online.map(_buildBuddyTile),
        ],
        if (away.isNotEmpty) ...[
          _sectionHeader(
              'Away', away.length, const Color(0xFFFFAB00)),
          ...away.map(_buildBuddyTile),
        ],
        if (offline.isNotEmpty) ...[
          _sectionHeader(
              'Offline', offline.length, Colors.white24),
          ...offline.map(_buildBuddyTile),
        ],
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _sectionHeader(String label, int count, Color color) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 4),
      child: Row(children: [
        Container(
            width: 8,
            height: 8,
            decoration:
                BoxDecoration(shape: BoxShape.circle, color: color)),
        const SizedBox(width: 6),
        Text(
          '$label ($count)',
          style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.6),
        ),
        const SizedBox(width: 8),
        Expanded(child: Container(height: 1, color: color.withValues(alpha: 0.2))),
      ]),
    );
  }

  Widget _buildBuddyTile(_BuddyEntry buddy) {
    final statusColor = buddy.isOnline
        ? const Color(0xFF00E676)
        : buddy.isAway
            ? const Color(0xFFFFAB00)
            : Colors.white24;

    return InkWell(
      onTap: () => WebWindowService.openProfile(uid: buddy.uid),
      onDoubleTap: buddy.currentRoomId != null
          ? () => WebWindowService.openRoom(
              roomId: buddy.currentRoomId!,
              roomName: buddy.currentRoomName ?? '')
          : null,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        child: Row(children: [
          // Avatar + status dot
          Stack(alignment: Alignment.bottomRight, children: [
            CircleAvatar(
              radius: 18,
              backgroundImage: buddy.photoUrl != null
                  ? NetworkImage(buddy.photoUrl!)
                  : null,
              backgroundColor:
                  DesignColors.accent.withValues(alpha: 0.2),
              child: buddy.photoUrl == null
                  ? Text(
                      buddy.displayName.isNotEmpty
                          ? buddy.displayName[0].toUpperCase()
                          : '?',
                      style: const TextStyle(
                          color: DesignColors.accent,
                          fontSize: 14,
                          fontWeight: FontWeight.w700),
                    )
                  : null,
            ),
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: statusColor,
                shape: BoxShape.circle,
                border:
                    Border.all(color: const Color(0xFF0E0E1A), width: 1.5),
              ),
            ),
          ]),
          const SizedBox(width: 10),
          // Name + activity
          Expanded(
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    buddy.displayName,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w600),
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (buddy.currentRoomName != null)
                    Text(
                      'In: ${buddy.currentRoomName}',
                      style: TextStyle(
                          color: DesignColors.accent.withValues(alpha: 0.8),
                          fontSize: 11),
                      overflow: TextOverflow.ellipsis,
                    ),
                ]),
          ),
          // Quick-action buttons
          _quickBtn(Icons.chat_bubble_outline, 'Chat', () {
            WebWindowService.openChat(
                chatId: _makeChatId(buddy.uid),
                peerName: buddy.displayName);
          }),
          if (buddy.currentRoomId != null)
            _quickBtn(Icons.videocam_outlined, 'Join', () {
              WebWindowService.openRoom(
                  roomId: buddy.currentRoomId!,
                  roomName: buddy.currentRoomName ?? '');
            }),
        ]),
      ),
    );
  }

  Widget _quickBtn(IconData icon, String tooltip, VoidCallback onTap) {
    return Tooltip(
      message: tooltip,
      child: IconButton(
        icon: Icon(icon, size: 17, color: Colors.white38),
        onPressed: onTap,
        padding: const EdgeInsets.all(4),
        constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
        splashRadius: 16,
      ),
    );
  }

  String _makeChatId(String otherUid) {
    final myUid =
        FirebaseAuth.instance.currentUser?.uid ?? 'anon';
    final ids = [myUid, otherUid]..sort();
    return ids.join('_');
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        const Icon(Icons.people_outline, color: Colors.white24, size: 48),
        const SizedBox(height: 12),
        const Text('No friends yet',
            style: TextStyle(color: Colors.white38, fontSize: 14)),
        const SizedBox(height: 6),
        Text('Follow users to see them here',
            style: TextStyle(
                color: Colors.white24.withValues(alpha: 0.7), fontSize: 12)),
      ]),
    );
  }
}

// ── Simple model ──────────────────────────────────────────────────────────

class _BuddyEntry {
  final String uid;
  final String displayName;
  final String? photoUrl;
  final bool isOnline;
  final bool isAway;
  final String? currentRoomId;
  final String? currentRoomName;

  const _BuddyEntry({
    required this.uid,
    required this.displayName,
    this.photoUrl,
    required this.isOnline,
    required this.isAway,
    this.currentRoomId,
    this.currentRoomName,
  });
}
