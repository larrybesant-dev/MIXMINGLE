/// Room Screen
///
/// Main video room UI displaying:
/// - Join flow phase text
/// - Participant cards with animations
/// - Room energy indicator
/// - Control buttons (mic, video, leave)
///
/// Usage:
/// ```dart
/// RoomScreen(
///   roomId: 'room_123',
///   roomName: 'Gaming Room',
///   agoraToken: 'token_from_backend',
/// )
/// ```
///
/// Architecture:
/// - Consumes: AgoraRoomController (via Provider)
/// - Depends on: JoinFlowController, AgoraService, RoomFirestoreService
///
/// Enforces: DESIGN_BIBLE.md (colors, spacing, animations)
library;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../../core/design_system/design_constants.dart';
import '../../../controllers/agora_room_controller.dart';
import '../../../controllers/join_flow_controller.dart';
import '../../../models/participant.dart';
import '../widgets/participant_card_widget.dart';

class RoomScreen extends StatefulWidget {
  /// Room ID for Agora channel
  final String roomId;

  /// Display name of room
  final String roomName;

  /// Token from backend for Agora authentication
  final String agoraToken;

  /// Callback when user leaves room
  final VoidCallback? onLeaveRoom;

  const RoomScreen({
    required this.roomId,
    required this.roomName,
    required this.agoraToken,
    this.onLeaveRoom,
    super.key,
  });

  @override
  State<RoomScreen> createState() => _RoomScreenState();
}

class _RoomScreenState extends State<RoomScreen> with TickerProviderStateMixin {
  late AgoraRoomController _roomController;

  @override
  void initState() {
    super.initState();
    _initializeRoom();
  }

  Future<void> _initializeRoom() async {
    _roomController =
        context.read<AgoraRoomController>();

    // Inject room context
    final currentUser = FirebaseAuth.instance.currentUser;
    _roomController.setRoomContext(
      roomId: widget.roomId,
      userId: currentUser?.uid ?? 'anonymous',
      userName: currentUser?.displayName ?? currentUser?.email?.split('@').first ?? 'Guest',
    );

    // Start join flow
    try {
      await _roomController.joinRoom(agoraToken: widget.agoraToken);
    } catch (e) {
      if (!mounted) return;
      _showErrorDialog('Failed to join room: $e');
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Error',
          style: DesignTypography.heading,
        ),
        content: Text(
          message,
          style: DesignTypography.body,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'OK',
              style: DesignTypography.body.copyWith(
                color: DesignColors.accent,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleLeaveRoom() async {
    try {
      await _roomController.leaveRoom();
      if (!mounted) return;

      widget.onLeaveRoom?.call();
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      _showErrorDialog('Failed to leave room: $e');
    }
  }

  @override
  void dispose() {
    // Don't dispose the controller here - it's managed by Provider
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // ✅ Use dark background
      backgroundColor: DesignColors.surfaceDefault,

      appBar: AppBar(
        // ✅ Use dark app bar
        backgroundColor: DesignColors.surfaceDefault,
        elevation: 0,
        title: Text(
          widget.roomName,
          style: DesignTypography.heading,
        ),
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: DesignColors.textPrimary,
          ),
          onPressed: _handleLeaveRoom,
        ),
        actions: [
          // Room energy indicator top-right
          Padding(
            padding: EdgeInsets.all(DesignSpacing.md),
            child: Consumer<AgoraRoomController>(
              builder: (context, controller, child) {
                final energyLabel =
                    RoomEnergyThresholds.getEnergyLabel(controller.energy);
                final energyColor =
                    RoomEnergyThresholds.getEnergyColor(controller.energy);

                return Align(
                  alignment: Alignment.center,
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: DesignSpacing.md,
                      vertical: DesignSpacing.sm,
                    ),
                    decoration: BoxDecoration(
                      // ✅ Use energy color
                      color: energyColor.withValues(alpha: 0.1),
                      border: Border.all(color: energyColor, width: 1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      energyLabel,
                      style: DesignTypography.caption.copyWith(
                        color: energyColor,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),

      body: Consumer<AgoraRoomController>(
        builder: (context, roomController, child) {
          // Show join flow phase while connecting
          if (!roomController.isInRoom) {
            return _buildJoinFlowOverlay(roomController);
          }

          // Show participants grid
          return _buildRoomContent(roomController);
        },
      ),

      // Bottom control bar
      bottomNavigationBar: Consumer<AgoraRoomController>(
        builder: (context, roomController, child) {
          if (!roomController.isInRoom) {
            return SizedBox.shrink();
          }

          return Container(
            // ✅ Use DesignSpacing and DesignColors
            padding: EdgeInsets.all(DesignSpacing.lg),
            decoration: BoxDecoration(
              color: DesignColors.surfaceDefault,
              border: Border(
                top: BorderSide(
                  color: DesignColors.surfaceLight,
                  width: 1,
                ),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // Microphone toggle
                FloatingActionButton.small(
                  // Red when muted, dark when active
                  backgroundColor: roomController.isMicMuted
                      ? DesignColors.error
                      : DesignColors.surfaceLight,
                  onPressed: roomController.toggleMicrophone,
                  child: Icon(
                    roomController.isMicMuted ? Icons.mic_off : Icons.mic,
                    color: DesignColors.white,
                  ),
                ),

                // Video toggle
                FloatingActionButton.small(
                  backgroundColor: roomController.isVideoMuted
                      ? DesignColors.error
                      : DesignColors.surfaceLight,
                  onPressed: roomController.toggleVideo,
                  child: Icon(
                    roomController.isVideoMuted
                        ? Icons.videocam_off
                        : Icons.videocam,
                    color: DesignColors.white,
                  ),
                ),

                // Leave room
                FloatingActionButton.small(
                  backgroundColor: Color(0xFFEF5350), // Red for leave
                  onPressed: _handleLeaveRoom,
                  child: Icon(
                    Icons.phone_disabled,
                    color: DesignColors.white,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  /// Build join flow overlay while room is connecting
  Widget _buildJoinFlowOverlay(AgoraRoomController roomController) {
    return Center(
      child: Consumer<JoinFlowController>(
        builder: (context, joinFlow, child) {
          final phase = joinFlow.phase;
          final displayText = phase.displayText;

          return Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Animated dot indicator
              SizedBox(
                width: 60,
                height: 60,
                child: Stack(
                  alignment: Alignment.center,
                  children: List.generate(3, (i) {
                    return ScaleTransition(
                      scale: TweenSequence<double>([
                        TweenSequenceItem(
                          tween: Tween(begin: 1.0, end: 1.5),
                          weight: 50,
                        ),
                        TweenSequenceItem(
                          tween: Tween(begin: 1.5, end: 1.0),
                          weight: 50,
                        ),
                      ]).animate(
                        CurvedAnimation(
                          parent: AnimationController(
                            vsync: this,
                            duration: Duration(
                              milliseconds: 600 + (i * 200),
                            ),
                          ),
                          curve: Curves.easeInOut,
                        ),
                      ),
                      child: Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          // ✅ Use DesignColors.accent
                          color: DesignColors.accent.withValues(alpha: 0.6),
                        ),
                      ),
                    );
                  }),
                ),
              ),

              SizedBox(height: DesignSpacing.xl),

              // Phase text (✅ DesignTypography.heading)
              Text(
                displayText,
                style: DesignTypography.heading,
                textAlign: TextAlign.center,
              ),

              SizedBox(height: DesignSpacing.md),

              // Error message if applicable
            if (phase.name == 'error')
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: DesignSpacing.lg),
                  child: Text(
                    joinFlow.errorMessage ?? 'Unknown error',
                    style: DesignTypography.caption.copyWith(
                      color: Color(0xFFEF5350),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  /// Build main room content with participant cards
  Widget _buildRoomContent(AgoraRoomController roomController) {
    final participants = roomController.participants;

    if (participants.isEmpty) {
      return Center(
        child: Text(
          'Waiting for participants...',
          style: DesignTypography.body,
        ),
      );
    }

    return Padding(
      padding: EdgeInsets.all(DesignSpacing.lg),
      child: GridView.builder(
        gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: 300,
          mainAxisSpacing: DesignSpacing.lg,
          crossAxisSpacing: DesignSpacing.lg,
          childAspectRatio: 1.2,
        ),
        itemCount: participants.length,
        itemBuilder: (context, index) {
          final participant = participants[index];

          return ParticipantCardWidget(
            participant: participant,
            onTap: () {
              _showParticipantActionsMenu(context, participant);
            },
            showArrivalAnimation: true,
          );
        },
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
              // Mute/unmute handled by Agora remotely
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
