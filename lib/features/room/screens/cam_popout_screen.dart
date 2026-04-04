import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../presentation/providers/user_provider.dart';
import '../../../services/room_service.dart';
import '../../../services/notification_service.dart';

/// Direct one-on-one video call screen.
///
/// When opened, it creates a private 2-person room, navigates the caller into
/// it, and sends an in-app notification to the target user with a deep link.
/// The target user joins the same room to connect.
class CamPopoutScreen extends ConsumerStatefulWidget {
  const CamPopoutScreen({super.key, required this.targetUserId});

  final String targetUserId;

  @override
  ConsumerState<CamPopoutScreen> createState() => _CamPopoutScreenState();
}

class _CamPopoutScreenState extends ConsumerState<CamPopoutScreen> {
  bool _calling = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _startCall());
  }

  Future<void> _startCall() async {
    final caller = ref.read(userProvider);
    if (caller == null) {
      setState(() => _error = 'You must be logged in to make a call.');
      return;
    }

    setState(() {
      _calling = true;
      _error = null;
    });

    try {
      final roomService = ref.read(roomServiceProvider);
      final callerName = caller.username.trim().isEmpty ? 'Someone' : caller.username;

      // Fetch target user's display name for the room title.
      final targetDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.targetUserId)
          .get();
      final targetName = targetDoc.exists
          ? (targetDoc.data()?['username'] as String? ?? 'User').trim()
          : 'User';

      final roomId = await roomService.createRoom(
        hostId: caller.id,
        name: '$callerName & $targetName',
        description: 'Private video call',
        isLive: true,
        category: 'call',
      );

      // Set maxBroadcasters = 2 and flag as a direct call.
      await FirebaseFirestore.instance.collection('rooms').doc(roomId).update({
        'maxBroadcasters': 2,
        'isDirectCall': true,
        'calleeId': widget.targetUserId,
      });

      // Notify the target user.
      await NotificationService(
        firestore: FirebaseFirestore.instance,
      ).inAppNotification(
        widget.targetUserId,
        '📹 $callerName is calling you! Join at mixvy.app/room/$roomId',
      );

      if (!mounted) return;
      // Navigate the caller directly into the room.
      context.go('/room/$roomId');
    } catch (e) {
      if (mounted) {
        setState(() {
          _calling = false;
          _error = 'Could not start call: $e';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (_error != null) ...[
                const Icon(Icons.error_outline, size: 56, color: Colors.redAccent),
                const SizedBox(height: 16),
                Text(
                  _error!,
                  style: const TextStyle(color: Colors.white70),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: _startCall,
                  child: const Text('Retry'),
                ),
              ] else ...[
                const SizedBox(
                  width: 64,
                  height: 64,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 3,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  _calling ? 'Starting call…' : 'Connecting…',
                  style: theme.textTheme.titleMedium
                      ?.copyWith(color: Colors.white70),
                ),
                const SizedBox(height: 32),
                TextButton(
                  onPressed: () => context.pop(),
                  child: const Text(
                    'Cancel',
                    style: TextStyle(color: Colors.white54),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
