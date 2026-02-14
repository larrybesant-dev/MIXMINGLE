import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import '../../providers/all_providers.dart';
import '../../models/room.dart';
import 'message_bubble.dart';
import '../../shared/club_background.dart';
import '../../shared/glow_text.dart';
import '../../shared/neon_button.dart';
import '../../shared/gift_selector.dart';

class RoomPage extends ConsumerStatefulWidget {
  final Room room;

  const RoomPage({super.key, required this.room});

  @override
  ConsumerState<RoomPage> createState() => _RoomPageState();
}

class _RoomPageState extends ConsumerState<RoomPage> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  bool _isAgoraInitialized = false;
  bool _hasInitializedAgora = false;

  @override
  void initState() {
    super.initState();
  }

  Future<void> _initializeAgora() async {
    if (_hasInitializedAgora) return;

    try {
      final agoraService = ref.read(agoraVideoServiceProvider);

      // Initialize Agora engine if needed
      if (!agoraService.isInitialized) {
        await agoraService.initialize();
      }

      // Join the room channel
      await agoraService.joinRoom(widget.room.id);

      if (mounted) {
        setState(() {
          _isAgoraInitialized = true;
          _hasInitializedAgora = true;
        });
      }
    } catch (e) {
      debugPrint('Failed to initialize Agora: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to join video: ${e.toString()}')));
      }
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    // Leave room if we were in one
    if (_isAgoraInitialized) {
      try {
        ref.read(agoraVideoServiceProvider).leaveRoom();
      } catch (e) {
        debugPrint('Error leaving room: $e');
      }
    }
    super.dispose();
  }

  Future<void> _sendMessage() async {
    if (_messageController.text.trim().isEmpty) return;

    try {
      await ref.read(
        sendRoomMessageProvider({'content': _messageController.text.trim(), 'roomId': widget.room.id}).future,
      );
      _messageController.clear();
      _scrollToBottom();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to send message: ${e.toString()}')));
      }
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final messagesAsync = ref.watch(messagesProvider(widget.room.id));

    // Initialize Agora when the widget is first built
    if (!_hasInitializedAgora) {
      _initializeAgora();
    }

    return ClubBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: GlowText(
            text: widget.room.name ?? widget.room.title,
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: const Color(0xFFFFD700),
            glowColor: const Color(0xFFFF4C4C),
          ),
          backgroundColor: Colors.transparent,
          elevation: 0,
          actions: [
            IconButton(
              icon: const Icon(Icons.card_giftcard, color: Colors.white),
              onPressed: () => _showGiftSelector(context),
            ),
            IconButton(
              icon: const Icon(Icons.more_vert, color: Colors.white),
              onPressed: () => _showRoomMenu(context),
            ),
          ],
        ),
        body: Column(
          children: [
            // Video area with Agora video views
            Container(
              height: 300,
              decoration: BoxDecoration(
                border: Border.all(color: const Color(0xFFFF4C4C).withValues(alpha: 0.5), width: 2),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(color: const Color(0xFFFF4C4C).withValues(alpha: 0.3), blurRadius: 10, spreadRadius: 2),
                ],
              ),
              margin: const EdgeInsets.all(16),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: _isAgoraInitialized && ref.read(agoraVideoServiceProvider).engine != null
                    ? Stack(
                        children: [
                          // Remote video (full screen background)
                          if (ref.read(agoraVideoServiceProvider).remoteUsers.isNotEmpty)
                            AgoraVideoView(
                              controller: VideoViewController.remote(
                                rtcEngine: ref.read(agoraVideoServiceProvider).engine!,
                                canvas: VideoCanvas(uid: ref.read(agoraVideoServiceProvider).remoteUsers.first),
                                connection: RtcConnection(channelId: widget.room.id),
                              ),
                            ),
                          // Local video (small overlay)
                          Positioned(
                            top: 10,
                            right: 10,
                            width: 100,
                            height: 133,
                            child: Container(
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.white, width: 2),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: AgoraVideoView(
                                  controller: VideoViewController(
                                    rtcEngine: ref.read(agoraVideoServiceProvider).engine!,
                                    canvas: VideoCanvas(
                                      uid: ref.read(agoraVideoServiceProvider).localUid ?? 0,
                                      renderMode: RenderModeType.renderModeHidden,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      )
                    : Container(
                        color: const Color(0xFF1E1E2F),
                        child: const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              CircularProgressIndicator(color: Color(0xFFFF4C4C)),
                              SizedBox(height: 16),
                              GlowText(text: 'Initializing video...', fontSize: 16, glowColor: Color(0xFFFF4C4C)),
                            ],
                          ),
                        ),
                      ),
              ),
            ),
            // Messages area
            Expanded(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFFF4C4C).withValues(alpha: 0.3), width: 1),
                ),
                child: messagesAsync.when(
                  data: (messages) {
                    final currentUser = ref.watch(currentUserProvider);
                    return ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.all(16),
                      itemCount: messages.length,
                      itemBuilder: (context, index) {
                        return MessageBubble(message: messages[index], currentUserId: currentUser.value?.id ?? '');
                      },
                    );
                  },
                  loading: () => const Center(
                    child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFF4C4C))),
                  ),
                  error: (error, stack) => Center(
                    child: GlowText(
                      text: 'Error loading messages: ${error.toString()}',
                      fontSize: 14,
                      color: const Color(0xFFFF4C4C),
                    ),
                  ),
                ),
              ),
            ),
            // Video controls
            if (_isAgoraInitialized) ...[
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildVideoControlButton(
                      icon: ref.watch(agoraVideoServiceProvider).isMicMuted ? Icons.mic_off : Icons.mic,
                      label: ref.watch(agoraVideoServiceProvider).isMicMuted ? 'Unmute' : 'Mute',
                      onPressed: () async {
                        final messenger = ScaffoldMessenger.of(context);
                        try {
                          await ref.read(agoraVideoServiceProvider).toggleMic();
                          if (mounted) {
                            setState(() {});
                          }
                        } catch (e) {
                          if (mounted) {
                            messenger.showSnackBar(SnackBar(content: Text('Failed to toggle microphone: $e')));
                          }
                        }
                      },
                    ),
                    const SizedBox(width: 16),
                    _buildVideoControlButton(
                      icon: ref.watch(agoraVideoServiceProvider).isVideoMuted ? Icons.videocam_off : Icons.videocam,
                      label: ref.watch(agoraVideoServiceProvider).isVideoMuted ? 'Camera On' : 'Camera Off',
                      onPressed: () async {
                        final messenger = ScaffoldMessenger.of(context);
                        try {
                          await ref.read(agoraVideoServiceProvider).toggleVideo();
                          if (mounted) {
                            setState(() {});
                          }
                        } catch (e) {
                          if (mounted) {
                            messenger.showSnackBar(SnackBar(content: Text('Failed to toggle camera: $e')));
                          }
                        }
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],
            // Message input with nightclub styling
            Container(
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: const Color(0xFFFF4C4C).withValues(alpha: 0.3), width: 1),
                boxShadow: [
                  BoxShadow(color: const Color(0xFFFF4C4C).withValues(alpha: 0.2), blurRadius: 8, spreadRadius: 1),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        hintText: 'Type a message...',
                        hintStyle: TextStyle(color: Colors.white70),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                      ),
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                  Container(
                    margin: const EdgeInsets.only(right: 8),
                    child: NeonButton(
                      onPressed: _sendMessage,
                      padding: const EdgeInsets.all(12),
                      child: const Icon(Icons.send, size: 20),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showGiftSelector(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => GiftSelector(
        receiverId: widget.room.hostId,
        receiverName: widget.room.hostName ?? 'Host',
        roomId: widget.room.id,
      ),
    );
  }

  void _showRoomMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.people),
            title: const Text('View Participants'),
            onTap: () {
              Navigator.of(context).pop();
              // TODO: Show participants list
            },
          ),
          ListTile(
            leading: const Icon(Icons.share),
            title: const Text('Share Room'),
            onTap: () {
              Navigator.of(context).pop();
              // TODO: Share room link
            },
          ),
          ListTile(
            leading: const Icon(Icons.exit_to_app),
            title: const Text('Leave Room'),
            onTap: () {
              Navigator.of(context).pop();
              Navigator.of(context).pop(); // Go back to home
            },
          ),
        ],
      ),
    );
  }

  Widget _buildVideoControlButton({required IconData icon, required String label, required VoidCallback onPressed}) {
    return Container(
      width: 80,
      height: 60,
      decoration: BoxDecoration(
        color: const Color(0xFF2A2A3D),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: const Color(0xFFFFD700).withValues(alpha: 0.3), width: 2),
      ),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(30),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(height: 2),
            Text(
              label,
              style: const TextStyle(color: Colors.white70, fontSize: 10),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
