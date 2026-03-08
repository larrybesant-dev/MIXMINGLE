/// Chats List Page
/// View all conversations
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../../core/design_system/design_constants.dart';
import '../../../shared/widgets/club_background.dart';
import '../../../shared/widgets/neon_components.dart';
import '../../../shared/providers/auth_providers.dart';
import '../../../core/routing/app_routes.dart';

/// Chats List - All conversations
class ChatsListPage extends ConsumerWidget {
  const ChatsListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider).value;

    if (user == null) {
      return const Scaffold(
        body: Center(child: Text('Please sign in')),
      );
    }

    return ClubBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: const NeonText(
            'MESSAGES',
            fontSize: 24,
            fontWeight: FontWeight.w900,
            textColor: DesignColors.white,
            glowColor: DesignColors.accent,
          ),
          backgroundColor: Colors.transparent,
          elevation: 0,
          actions: [
            IconButton(
              icon: const Icon(Icons.mark_email_unread_outlined, color: DesignColors.accent),
              tooltip: 'Message Requests',
              onPressed: () => Navigator.pushNamed(context, AppRoutes.messageRequests),
            ),
          ],
        ),
        body: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('chats')
              .where('participantIds', arrayContains: user.id)
              .orderBy('lastMessageTimestamp', descending: true)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Center(
                child: Text('Error: ${snapshot.error}'),
              );
            }

            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            final chats = snapshot.data?.docs ?? [];

            if (chats.isEmpty) {
              return _buildEmptyState();
            }

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: chats.length,
              itemBuilder: (context, index) {
                final chatDoc = chats[index];
                final chatData = chatDoc.data() as Map<String, dynamic>;
                final chatId = chatDoc.id;

                return _buildChatTile(
                  context,
                  chatId,
                  chatData,
                  user.id,
                );
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildChatTile(
    BuildContext context,
    String chatId,
    Map<String, dynamic> chatData,
    String currentUserId,
  ) {
    // Get other participant info
    final participantIds =
        List<String>.from(chatData['participantIds'] ?? []);
    final otherUserId =
        participantIds.firstWhere((id) => id != currentUserId, orElse: () => '');

    final participantNames =
        Map<String, String>.from(chatData['participantNames'] ?? {});
    final participantPhotos =
        Map<String, String>.from(chatData['participantPhotos'] ?? {});

    final otherUserName = participantNames[otherUserId] ?? 'Unknown';
    final otherUserPhoto = participantPhotos[otherUserId];

    final lastMessage = chatData['lastMessage'] as String?;
    final lastMessageTimestamp =
        (chatData['lastMessageTimestamp'] as Timestamp?)?.toDate();
    final unreadCount = (chatData['unreadCount'] as Map<String, dynamic>?)?[currentUserId] ?? 0;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: NeonGlowCard(
        glowColor: DesignColors.accent,
        onTap: () {
          Navigator.pushNamed(
            context,
            '/chat',
            arguments: chatId,
          );
        },
        child: Row(
          children: [
            // Avatar
            Stack(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: DesignColors.accent.withValues(alpha: 255, red: 255, green: 255, blue: 255),
                  backgroundImage:
                      otherUserPhoto != null ? NetworkImage(otherUserPhoto) : null,
                  child: otherUserPhoto == null
                      ? Text(
                          otherUserName[0].toUpperCase(),
                          style: const TextStyle(
                            color: DesignColors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        )
                      : null,
                ),
                if (unreadCount > 0)
                Positioned(
                  top: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 20,
                      minHeight: 20,
                    ),
                    child: Center(
                      child: Text(
                        unreadCount > 9 ? '9+' : unreadCount.toString(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 12),

            // Chat info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      otherUserName,
                      style: TextStyle(
                        color: DesignColors.white,
                        fontSize: 16,
                        fontWeight: unreadCount > 0
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                    if (lastMessageTimestamp != null)
                      Text(
                        timeago.format(lastMessageTimestamp),
                        style: TextStyle(
                          color: DesignColors.white.withValues(alpha: 255, red: 255, green: 255, blue: 255),
                          fontSize: 12,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  lastMessage ?? 'No messages yet',
                  style: TextStyle(
                    color: DesignColors.white.withValues(alpha: 255, red: 255, green: 255, blue: 255),
                    fontSize: 14,
                    fontWeight:
                        unreadCount > 0 ? FontWeight.w600 : FontWeight.normal,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.chat_bubble_outline,
            size: 80,
            color: DesignColors.white.withValues(alpha: 255, red: 255, green: 255, blue: 255),
          ),
          const SizedBox(height: 16),
          Text(
            'No messages yet',
            style: TextStyle(
              color: DesignColors.white.withValues(alpha: 255, red: 255, green: 255, blue: 255),
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Match with someone to start chatting!',
            style: TextStyle(
              color: DesignColors.white,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}
