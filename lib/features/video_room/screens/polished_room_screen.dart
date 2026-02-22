import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' as riverpod;
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../core/design_system/design_constants.dart';
import '../../../controllers/agora_room_controller.dart';
import '../../../controllers/join_flow_controller.dart';
import '../../../models/participant.dart';
import '../widgets/room_header_widget.dart';
import '../widgets/participant_list_widget.dart';
import '../widgets/media_controls_widget.dart';
import '../widgets/host_controls_widget.dart';
import '../widgets/chat_overlay_widget.dart';
import 'join_room_screen.dart';
import 'leave_room_screen.dart';
import '../../../shared/models/chat_message.dart';
import '../../../providers/room_chat_presence_providers.dart';

class PolishedRoomScreen extends StatefulWidget {
  final String roomId;
  final String roomName;
  final String agoraToken;
  final VoidCallback? onLeaveRoom;

  const PolishedRoomScreen({
    required this.roomId,
    required this.roomName,
    required this.agoraToken,
    this.onLeaveRoom,
    super.key,
  });

  @override
  State<PolishedRoomScreen> createState() => _PolishedRoomScreenState();
}

class _PolishedRoomScreenState extends State<PolishedRoomScreen>
    with TickerProviderStateMixin {
  late AgoraRoomController _roomController;
  bool _showJoinScreen = true;
  bool _showLeaveScreen = false;
  bool _showChat = false;
  bool _showParticipants = false;
  int _unreadMessages = 0;

  @override
  void initState() {
    super.initState();
    _initializeRoom();
  }

  Future<void> _initializeRoom() async {
    _roomController = context.read<AgoraRoomController>();
    final currentUser = FirebaseAuth.instance.currentUser;
    _roomController.setRoomContext(
      roomId: widget.roomId,
      userId: currentUser?.uid ?? 'anonymous',
      userName: currentUser?.displayName ?? currentUser?.email?.split('@').first ?? 'Guest',
    );
  }

  void _handleJoin() async {
    setState(() => _showJoinScreen = false);
    try {
      await _roomController.joinRoom(agoraToken: widget.agoraToken);
    } catch (e) {
      _showError('Failed to join room: $e');
      setState(() => _showJoinScreen = true);
    }
  }

  void _handleLeaveAttempt() {
    setState(() => _showLeaveScreen = true);
  }

  void _handleLeaveConfirm() async {
    setState(() => _showLeaveScreen = false);
    try {
      await _roomController.leaveRoom();
      widget.onLeaveRoom?.call();
      if (mounted) Navigator.pop(context);
    } catch (e) {
      _showError('Failed to leave room: $e');
    }
  }

  void _handleLeaveCancel() {
    setState(() => _showLeaveScreen = false);
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: DesignColors.error,
      ),
    );
  }

  void _toggleChat() {
    setState(() {
      _showChat = !_showChat;
      if (_showChat) {
        _unreadMessages = 0;
      }
    });
  }

  void _toggleParticipants() {
    setState(() => _showParticipants = !_showParticipants);
  }

  void _sendMessage(String content, riverpod.WidgetRef ref) {
    final currentUser = FirebaseAuth.instance.currentUser;
    ref.read(roomMessagesProvider(widget.roomId).notifier).sendMessage(
      content,
      currentUser?.displayName ?? currentUser?.email?.split('@').first ?? 'Guest',
      currentUser?.uid ?? 'anonymous',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DesignColors.background,
      body: Consumer<AgoraRoomController>(
        builder: (context, roomController, child) {
          // Show join screen
          if (_showJoinScreen) {
            return JoinRoomScreen(
              roomName: widget.roomName,
              roomId: widget.roomId,
              onJoin: _handleJoin,
              onCancel: () => Navigator.pop(context),
            );
          }

          // Show leave confirmation
          if (_showLeaveScreen) {
            return LeaveRoomScreen(
              roomName: widget.roomName,
              participantCount: roomController.participants.length,
              timeInRoom: Duration(minutes: 15), // TODO: Track actual time
              onLeave: _handleLeaveConfirm,
              onCancel: _handleLeaveCancel,
            );
          }

          // Main room view
          return Stack(
            children: [
              // Background
              Container(color: DesignColors.background),

              // Room header
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: RoomHeader(
                  roomName: widget.roomName,
                  roomId: widget.roomId,
                  participantCount: roomController.participants.length,
                  isHost: false, // TODO: Check if user is host
                  onLeave: _handleLeaveAttempt,
                  onSettings: () {}, // TODO: Implement settings
                  onInvite: () {}, // TODO: Implement invite
                ),
              ),

              // Main content area
              Positioned(
                top: 140, // Below header
                left: 0,
                right: _showParticipants ? MediaQuery.of(context).size.width * 0.3 : 0,
                bottom: 120, // Above controls
                child: _buildMainContent(roomController),
              ),

              // Participant list panel
              if (_showParticipants)
                Positioned(
                  top: 140,
                  right: 0,
                  width: MediaQuery.of(context).size.width * 0.3,
                  bottom: 120,
                  child: Container(
                    color: DesignColors.surface,
                    child: ParticipantListWidget(
                      participants: roomController.participants,
                      hostId: null, // Host ID can be obtained from room metadata
                      onParticipantTap: (participant) {
                        _showParticipantActionsMenu(context, participant);
                      },
                    ),
                  ),
                ),

              // Media controls
              Positioned(
                bottom: 20,
                left: 0,
                right: 0,
                child: Center(
                  child: MediaControlsWidget(
                    isMicEnabled: roomController.isMicMuted == false,
                    isCameraEnabled: roomController.isVideoMuted == false,
                    onMicToggle: (enabled) {
                      // Toggle microphone using available method
                      roomController.toggleMicrophone();
                    },
                    onCameraToggle: (enabled) {
                      // Toggle video using available method
                      roomController.toggleVideo();
                    },
                    onMoreOptions: _toggleParticipants,
                  ),
                ),
              ),

              // Host controls (if user is host)
              HostControlsOverlay(
                controls: HostControlsWidget(
                  isHost: false, // TODO: Check if user is host
                  onEndRoom: _handleLeaveAttempt,
                ),
                child: const SizedBox.shrink(),
              ),

              // Chat overlay - connected to Firestore real-time messages
              riverpod.Consumer(
                builder: (context, ref, child) {
                  final messagesState = ref.watch(roomMessagesProvider(widget.roomId));
                  final chatMessages = messagesState.messages.map((rm) => ChatMessage(
                    id: rm.id,
                    senderId: rm.senderId,
                    senderName: rm.senderName,
                    content: rm.text,
                    timestamp: rm.createdAt,
                    context: MessageContext.room,
                    roomId: widget.roomId,
                    contentType: rm.type == 'system' ? MessageContentType.system : MessageContentType.text,
                  )).toList();

                  return ChatOverlayWidget(
                    messages: chatMessages,
                    isVisible: _showChat,
                    unreadCount: _unreadMessages,
                    onSendMessage: (content) => _sendMessage(content, ref),
                    onToggleVisibility: _toggleChat,
                    currentUserId: FirebaseAuth.instance.currentUser?.uid ?? '',
                  );
                },
              ),

              // Quick action buttons
              Positioned(
                top: 160,
                right: 20,
                child: Column(
                  children: [
                    // Chat toggle
                    FloatingActionButton.small(
                      onPressed: _toggleChat,
                      backgroundColor: DesignColors.accent,
                      child: Badge(
                        label: _unreadMessages > 0 ? Text(_unreadMessages.toString()) : null,
                        child: Icon(Icons.chat),
                      ),
                    ),
                    SizedBox(height: 10),
                    // Participants toggle
                    FloatingActionButton.small(
                      onPressed: _toggleParticipants,
                      backgroundColor: DesignColors.surface,
                      child: Icon(Icons.people),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildMainContent(AgoraRoomController roomController) {
    if (!roomController.isInRoom) {
      return _buildJoinFlowOverlay(roomController);
    }

    final participants = roomController.participants;
    if (participants.isEmpty) {
      return _buildWaitingForParticipants();
    }

    // Use the multi-cam video grid here
    // TODO: Integrate with VideoTileWidget and GridWindowWidget
    return Container(
      color: Colors.grey[900],
      child: GridView.builder(
        padding: EdgeInsets.all(DesignSpacing.lg),
        gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: 300,
          mainAxisSpacing: DesignSpacing.lg,
          crossAxisSpacing: DesignSpacing.lg,
          childAspectRatio: 1.2,
        ),
        itemCount: participants.length,
        itemBuilder: (context, index) {
          final participant = participants[index];
          return Container(
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: DesignColors.accent.withValues(alpha: 0.3)),
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.videocam,
                    size: 48,
                    color: DesignColors.accent,
                  ),
                  SizedBox(height: 8),
                  Text(
                    participant.name,
                    style: TextStyle(color: DesignColors.white),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildJoinFlowOverlay(AgoraRoomController roomController) {
    return Center(
      child: Consumer<JoinFlowController>(
        builder: (context, joinFlow, child) {
          return Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(DesignColors.accent),
              ),
              SizedBox(height: DesignSpacing.xl),
              Text(
                'Joining ${widget.roomName}...',
                style: DesignTypography.heading.copyWith(
                  color: DesignColors.white,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildWaitingForParticipants() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.people_outline,
            size: 64,
            color: DesignColors.textSecondary.withValues(alpha: 0.5),
          ),
          SizedBox(height: DesignSpacing.lg),
          Text(
            'Waiting for participants...',
            style: DesignTypography.heading.copyWith(
              color: DesignColors.white,
            ),
          ),
          SizedBox(height: DesignSpacing.md),
          Text(
            'Share the room link to invite others',
            style: DesignTypography.body.copyWith(
              color: DesignColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  void _showParticipantActionsMenu(BuildContext context, Participant participant) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: Icon(participant.isMuted ? Icons.volume_up : Icons.volume_off),
            title: Text(participant.isMuted ? 'Unmute for me' : 'Mute for me'),
            onTap: () {
              Navigator.of(ctx).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(participant.isMuted ? 'Unmuted ${participant.name}' : 'Muted ${participant.name}')),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.person),
            title: const Text('View Profile'),
            onTap: () {
              Navigator.of(ctx).pop();
              Navigator.of(context).pushNamed('/profile/user', arguments: participant.uid);
            },
          ),
          ListTile(
            leading: const Icon(Icons.star),
            title: const Text('Spotlight'),
            onTap: () {
              Navigator.of(ctx).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Spotlighting ${participant.name}')),
              );
            },
          ),
        ],
      ),
    );
  }
}
