// lib/features/buddy_list/buddy_profile_screen.dart
//
// Pop-out user profile screen.
// Route: /buddy-profile?uid={userId}
//
// Opened from the Buddy List when a user clicks an avatar, or from any
// avatar tap throughout the app (rooms, chat, feed).
// ─────────────────────────────────────────────────────────────────────────

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../core/design_system/design_constants.dart';
import '../../core/web/web_window_service.dart';

class BuddyProfileScreen extends StatelessWidget {
  final String uid;

  const BuddyProfileScreen({super.key, required this.uid});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0E0E1A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF12082A),
        elevation: 0,
        automaticallyImplyLeading: false,
        title: const Text('Profile',
            style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w700)),
        actions: [
          IconButton(
            icon:
                const Icon(Icons.close, color: Colors.white54, size: 18),
            onPressed: () {},
          )
        ],
      ),
      body: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance.collection('users').doc(uid).get(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(
                child:
                    CircularProgressIndicator(color: DesignColors.accent));
          }
          if (!snap.hasData || !snap.data!.exists) {
            return const Center(
                child: Text('User not found',
                    style: TextStyle(color: Colors.white54)));
          }

          final d = snap.data!.data() as Map<String, dynamic>;
          final name =
              (d['displayName'] as String?) ?? 'Unknown';
          final photo = d['photoUrl'] as String?;
          final bio = d['bio'] as String?;
          final isOnline =
              d['isOnline'] == true || d['presence'] == 'online';
          final currentRoomId = d['currentRoomId'] as String?;
          final currentRoomName = d['currentRoomName'] as String?;
          final isMe =
              FirebaseAuth.instance.currentUser?.uid == uid;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Avatar
                Stack(alignment: Alignment.bottomRight, children: [
                  CircleAvatar(
                    radius: 52,
                    backgroundImage:
                        photo != null ? NetworkImage(photo) : null,
                    backgroundColor:
                        DesignColors.accent.withValues(alpha: 0.15),
                    child: photo == null
                        ? Text(
                            name.isNotEmpty
                                ? name[0].toUpperCase()
                                : '?',
                            style: const TextStyle(
                                color: DesignColors.accent,
                                fontSize: 36,
                                fontWeight: FontWeight.w800),
                          )
                        : null,
                  ),
                  Container(
                    width: 14,
                    height: 14,
                    decoration: BoxDecoration(
                      color: isOnline
                          ? const Color(0xFF00E676)
                          : Colors.white24,
                      shape: BoxShape.circle,
                      border: Border.all(
                          color: const Color(0xFF0E0E1A), width: 2),
                    ),
                  ),
                ]),
                const SizedBox(height: 14),
                Text(name,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w800)),
                const SizedBox(height: 4),
                Text(
                  isOnline ? 'Online' : 'Offline',
                  style: TextStyle(
                      color: isOnline
                          ? const Color(0xFF00E676)
                          : Colors.white38,
                      fontSize: 12,
                      fontWeight: FontWeight.w600),
                ),
                if (bio != null && bio.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Text(bio,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          color: Colors.white70, fontSize: 13)),
                ],
                const SizedBox(height: 24),

                // Action buttons
                if (!isMe) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _actionBtn(
                        icon: Icons.chat_bubble_outline,
                        label: 'Message',
                        color: DesignColors.accent,
                        onTap: () {
                          final ids = [
                            FirebaseAuth.instance.currentUser?.uid ?? '',
                            uid,
                          ]..sort();
                          WebWindowService.openChat(
                              chatId: ids.join('_'), peerName: name);
                        },
                      ),
                      const SizedBox(width: 12),
                      if (currentRoomId != null)
                        _actionBtn(
                          icon: Icons.videocam_outlined,
                          label: 'Join Room',
                          color: DesignColors.secondary,
                          onTap: () => WebWindowService.openRoom(
                              roomId: currentRoomId,
                              roomName: currentRoomName ?? ''),
                        ),
                    ],
                  ),
                ],

                if (currentRoomId != null) ...[
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: DesignColors.accent.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color:
                              DesignColors.accent.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.live_tv,
                              color: DesignColors.accent, size: 16),
                          const SizedBox(width: 8),
                          Text(
                            'Live in: ${currentRoomName ?? 'a room'}',
                            style: const TextStyle(
                                color: DesignColors.accent,
                                fontSize: 12,
                                fontWeight: FontWeight.w600),
                          ),
                        ]),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _actionBtn({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return ElevatedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 16),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: color.withValues(alpha: 0.15),
        foregroundColor: color,
        side: BorderSide(color: color.withValues(alpha: 0.5)),
        elevation: 0,
        padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
    );
  }
}
