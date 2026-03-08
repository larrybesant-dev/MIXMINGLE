import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../../core/design_system/design_constants.dart';
import '../../../shared/providers/auth_providers.dart';

/// Shows incoming DM requests from users the current user hasn't chatted with.
/// Reads from the `messageRequests` sub-collection on the current user doc.
class MessageRequestsPage extends ConsumerWidget {
  const MessageRequestsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(currentUserProvider);
    final uid = userAsync.value?.id;

    if (uid == null) {
      return Scaffold(
        backgroundColor: DesignColors.background,
        appBar: AppBar(
          backgroundColor: DesignColors.surfaceDefault,
          title: const Text('Message Requests',
              style: TextStyle(color: Colors.white)),
          leading: const BackButton(color: Colors.white),
        ),
        body: const Center(
          child: CircularProgressIndicator(color: DesignColors.accent),
        ),
      );
    }

    final stream = FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('messageRequests')
        .orderBy('timestamp', descending: true)
        .snapshots();

    return Scaffold(
      backgroundColor: DesignColors.background,
      appBar: AppBar(
        backgroundColor: DesignColors.surfaceDefault,
        title: const Text('Message Requests',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        leading: const BackButton(color: Colors.white),
        elevation: 0,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: stream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: DesignColors.accent),
            );
          }

          final docs = snapshot.data?.docs ?? [];
          if (docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.mark_chat_unread_outlined,
                    size: 64,
                    color: Colors.white.withValues(alpha: 0.2),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No message requests',
                    style: DesignTypography.heading.copyWith(
                      color: Colors.white.withValues(alpha: 0.5),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'When someone you don\'t know messages you,\nit will appear here.',
                    textAlign: TextAlign.center,
                    style: DesignTypography.caption.copyWith(
                      color: Colors.white.withValues(alpha: 0.35),
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: docs.length,
            separatorBuilder: (_, __) =>
                const Divider(color: Colors.white10, height: 1),
            itemBuilder: (context, i) {
              final data = docs[i].data() as Map<String, dynamic>;
              final requestId = docs[i].id;
              final senderName =
                  data['senderName'] as String? ?? 'Someone';
              final preview =
                  data['messagePreview'] as String? ?? 'Sent you a message';
              final ts =
                  (data['timestamp'] as Timestamp?)?.toDate();
              final avatarUrl = data['senderAvatarUrl'] as String?;

              return ListTile(
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                leading: CircleAvatar(
                  radius: 26,
                  backgroundImage:
                      avatarUrl != null ? NetworkImage(avatarUrl) : null,
                  backgroundColor: DesignColors.accent.withValues(alpha: 0.2),
                  child: avatarUrl == null
                      ? Text(
                          senderName.isNotEmpty
                              ? senderName[0].toUpperCase()
                              : '?',
                          style: const TextStyle(
                            color: DesignColors.accent,
                            fontWeight: FontWeight.bold,
                          ),
                        )
                      : null,
                ),
                title: Text(
                  senderName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                subtitle: Text(
                  preview,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.5)),
                ),
                trailing: ts != null
                    ? Text(
                        timeago.format(ts, locale: 'en_short'),
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.35),
                          fontSize: 11,
                        ),
                      )
                    : null,
                onTap: () =>
                    _showRequestOptions(context, uid, requestId, data),
              );
            },
          );
        },
      ),
    );
  }

  void _showRequestOptions(
    BuildContext context,
    String uid,
    String requestId,
    Map<String, dynamic> data,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: DesignColors.surfaceDefault,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _RequestOptionsSheet(
        uid: uid,
        requestId: requestId,
        data: data,
      ),
    );
  }
}

class _RequestOptionsSheet extends StatelessWidget {
  final String uid;
  final String requestId;
  final Map<String, dynamic> data;

  const _RequestOptionsSheet({
    required this.uid,
    required this.requestId,
    required this.data,
  });

  @override
  Widget build(BuildContext context) {
    final senderName = data['senderName'] as String? ?? 'this user';
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Message from $senderName',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: const Icon(Icons.check_circle_outline,
                  color: Color(0xFF00E5CC)),
              title: const Text('Accept',
                  style: TextStyle(color: Colors.white)),
              subtitle: Text(
                'Open a chat with $senderName',
                style:
                    TextStyle(color: Colors.white.withValues(alpha: 0.5)),
              ),
              onTap: () => _accept(context),
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline, color: Colors.red),
              title: const Text('Decline',
                  style: TextStyle(color: Colors.white)),
              subtitle: Text(
                'Remove this request',
                style:
                    TextStyle(color: Colors.white.withValues(alpha: 0.5)),
              ),
              onTap: () => _decline(context),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _accept(BuildContext context) async {
    Navigator.pop(context);
    final chatId = data['chatId'] as String?;
    // Move request to active chats by creating/updating the chat doc
    if (chatId != null) {
      await FirebaseFirestore.instance
          .collection('chats')
          .doc(chatId)
          .set({'accepted': true}, SetOptions(merge: true));
    }
    await _deleteRequest();
    if (context.mounted && chatId != null) {
      Navigator.pushNamed(context, '/chat/$chatId');
    }
  }

  Future<void> _decline(BuildContext context) async {
    Navigator.pop(context);
    await _deleteRequest();
  }

  Future<void> _deleteRequest() async {
    await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('messageRequests')
        .doc(requestId)
        .delete();
  }
}
