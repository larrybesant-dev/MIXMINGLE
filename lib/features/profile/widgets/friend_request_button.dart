// lib/features/profile/widgets/friend_request_button.dart
//
// Adaptive button that reflects the full friend-relationship lifecycle:
//   none          →  "Add Friend"   (blue)
//   pendingSent   →  "Pending"      (grey, tap = cancel)
//   pendingReceived → "Accept" + "Decline" (green / red)
//   friends       →  "Friends ✓"   (muted, tap = unfriend sheet)
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/providers/friend_providers.dart';
import '../../../services/social/friend_service.dart';
import '../../../services/notifications/app_notification_service.dart';
import '../../../core/design_system/design_constants.dart';
import '../../../core/analytics/analytics_service.dart';

class FriendRequestButton extends ConsumerWidget {
  final String targetUserId;
  final String? targetUserName;
  final String? targetUserAvatarUrl;

  const FriendRequestButton({
    super.key,
    required this.targetUserId,
    this.targetUserName,
    this.targetUserAvatarUrl,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final relAsync =
        ref.watch(friendRelationshipProvider(targetUserId));

    return relAsync.when(
      data: (rel) => _buildButton(context, ref, rel),
      loading: () => const SizedBox(
        width: 120,
        height: 38,
        child: Center(
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: DesignColors.accent,
            ),
          ),
        ),
      ),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  Widget _buildButton(
    BuildContext context,
    WidgetRef ref,
    FriendRelationship rel,
  ) {
    switch (rel) {
      // ── No relationship ─────────────────────────────────────────────────────
      case FriendRelationship.none:
        return _NeonButton(
          label: 'Add Friend',
          icon: Icons.person_add_alt_1_outlined,
          color: DesignColors.accent,
          onTap: () async {
            AnalyticsService.instance.logFriendRequestSent(targetUserId: targetUserId);
            await ref.read(sendFriendRequestProvider({
              'receiverId': targetUserId,
              'receiverName': targetUserName,
              'receiverAvatarUrl': targetUserAvatarUrl,
            }).future);
            // Send in-app notification
            if (targetUserId.isNotEmpty) {
              await AppNotificationService.instance.notifyFriendRequest(
                receiverId: targetUserId,
                senderName: 'Someone', // caller sets sender
              );
            }
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                _snack('Friend request sent!'),
              );
            }
          },
        );

      // ── Pending sent ────────────────────────────────────────────────────────
      case FriendRelationship.pendingSent:
        return _NeonButton(
          label: 'Pending',
          icon: Icons.hourglass_top_rounded,
          color: Colors.grey,
          onTap: () => _confirmCancelRequest(context, ref),
        );

      // ── Pending received ────────────────────────────────────────────────────
      case FriendRelationship.pendingReceived:
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _NeonButton(
              label: 'Accept',
              icon: Icons.check_circle_outline,
              color: Colors.green,
              onTap: () async {
                final reqId = await FriendService.instance
                    .incomingRequestId(targetUserId);
                if (reqId != null) {
                  await ref.read(acceptFriendRequestProvider({
                    'requestId': reqId,
                    'senderId': targetUserId,
                  }).future);
                  AnalyticsService.instance.logFriendRequestAccepted(targetUserId: targetUserId);
                  AnalyticsService.instance.logFirstFriendAddedOnce(userId: targetUserId);
                  // Notify the sender that request was accepted
                  await AppNotificationService.instance.notifyFriendAccepted(
                    receiverId: targetUserId,
                    acceptorName: 'Someone',
                  );
                  if (context.mounted) {
                    ScaffoldMessenger.of(context)
                        .showSnackBar(_snack('You are now friends! 🎉'));
                  }
                }
              },
            ),
            const SizedBox(width: 8),
            _NeonButton(
              label: 'Decline',
              icon: Icons.cancel_outlined,
              color: Colors.red,
              onTap: () async {
                final reqId = await FriendService.instance
                    .incomingRequestId(targetUserId);
                if (reqId != null) {
                  await ref.read(declineFriendRequestProvider({
                    'requestId': reqId,
                    'senderId': targetUserId,
                  }).future);
                }
              },
            ),
          ],
        );

      // ── Already friends ─────────────────────────────────────────────────────
      case FriendRelationship.friends:
        return _NeonButton(
          label: 'Friends ✓',
          icon: Icons.people_alt_outlined,
          color: DesignColors.secondary,
          onTap: () => _confirmUnfriend(context, ref),
        );
    }
  }

  // ── Dialogs ─────────────────────────────────────────────────────────────────

  Future<void> _confirmCancelRequest(
      BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF1A1F2E),
        title: const Text('Cancel Request?',
            style: TextStyle(color: Colors.white)),
        content: Text(
          'Cancel your friend request to ${targetUserName ?? 'this user'}?',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('No')),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Cancel Request',
                  style: TextStyle(color: Colors.redAccent))),
        ],
      ),
    );
    if (confirmed == true) {
      final reqId =
          await FriendService.instance.pendingRequestId(targetUserId);
      if (reqId != null) {
        await ref.read(cancelFriendRequestProvider({
          'requestId': reqId,
          'receiverId': targetUserId,
        }).future);
      }
    }
  }

  Future<void> _confirmUnfriend(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF1A1F2E),
        title: const Text('Unfriend?',
            style: TextStyle(color: Colors.white)),
        content: Text(
          'Remove ${targetUserName ?? 'this user'} from your friends?',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Unfriend',
                  style: TextStyle(color: Colors.redAccent))),
        ],
      ),
    );
    if (confirmed == true) {
      await ref.read(unfriendProvider(targetUserId).future);
    }
  }
}

// ── Reusable neon button ─────────────────────────────────────────────────────

class _NeonButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _NeonButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: color.withValues(alpha: 0.8), width: 1.4),
          boxShadow: [
            BoxShadow(
                color: color.withValues(alpha: 0.3),
                blurRadius: 8,
                spreadRadius: 1),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 16),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 13,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── helper ────────────────────────────────────────────────────────────────────

SnackBar _snack(String msg) => SnackBar(
      content: Text(msg),
      backgroundColor: const Color(0xFF1A1F2E),
      behavior: SnackBarBehavior.floating,
    );
