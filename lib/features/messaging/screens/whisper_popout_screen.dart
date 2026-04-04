import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../presentation/providers/user_provider.dart';
import '../providers/messaging_provider.dart';
import 'chat_screen.dart';

/// A minimal standalone screen used when a whisper pop-out window is opened
/// on web. It resolves (or creates) the DM conversation with [targetUserId]
/// and then embeds `ChatScreen` in a bare scaffold (no app drawer/shell).
class WhisperPopoutScreen extends ConsumerStatefulWidget {
  const WhisperPopoutScreen({super.key, required this.targetUserId});

  final String targetUserId;

  @override
  ConsumerState<WhisperPopoutScreen> createState() =>
      _WhisperPopoutScreenState();
}

class _WhisperPopoutScreenState extends ConsumerState<WhisperPopoutScreen> {
  String? _conversationId;
  String? _error;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _resolve();
  }

  Future<void> _resolve() async {
    try {
      final currentUser = ref.read(userProvider);
      if (currentUser == null) throw Exception('Not signed in.');
      final conversationId = await ref
          .read(messagingControllerProvider)
          .createDirectConversation(
            userId1: currentUser.id,
            user1Name: currentUser.username,
            user1AvatarUrl: currentUser.avatarUrl,
            userId2: widget.targetUserId,
            user2Name: '',
            user2AvatarUrl: null,
          );
      if (mounted) {
        setState(() {
          _conversationId = conversationId;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (_error != null) {
      return Scaffold(
        body: Center(
          child: Text(_error!, style: const TextStyle(color: Colors.red)),
        ),
      );
    }
    return ChatScreen(
      conversationId: _conversationId!,
      userId: widget.targetUserId,
      username: '',
    );
  }
}
