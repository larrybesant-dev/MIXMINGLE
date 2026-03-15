import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/utils/app_logger.dart';
import 'video_room_controller.dart';
import 'video_room_state.dart';
import '../../core/design_system/design_constants.dart';

/// Clean video room UI that uses the controller
/// This widget is responsible ONLY for UI rendering
/// All logic is delegated to VideoRoomNotifier
class VideoRoomView extends ConsumerStatefulWidget {
  final String roomId;
  final String roomName;
  final String appId;
  final String userId;
  final String token;

  const VideoRoomView({
    super.key,
    required this.roomId,
    required this.roomName,
    required this.appId,
    required this.userId,
    required this.token,
  });

  @override
  ConsumerState<VideoRoomView> createState() => _VideoRoomViewState();
}

class _VideoRoomViewState extends ConsumerState<VideoRoomView> {
  late final videoRoomKey = (
    appId: widget.appId,
    roomId: widget.roomId,
    userId: widget.userId,
  );

  @override
  void initState() {
    super.initState();
    // Initialization happens explicitly via controller
  }

  @override
  void dispose() {
    // Cleanup happens explicitly via controller
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Access the video room controller
    final roomKey =
        (appId: widget.appId, roomId: widget.roomId, userId: widget.userId);
    final videoRoom = ref.read(videoRoomProvider(roomKey).notifier);
    final videoRoomState = ref.watch(videoRoomProvider(roomKey));

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.roomName),
        actions: [
          // Microphone toggle
          IconButton(
            icon: Icon(videoRoomState.micEnabled ? Icons.mic : Icons.mic_off),
            onPressed: videoRoomState.isJoined
                ? () => videoRoom.toggleMicrophone().catchError((e) {
                      AppLogger.error('Mic toggle failed: $e');
                    })
                : null,
          ),
          // Camera toggle
          IconButton(
            icon: Icon(videoRoomState.cameraEnabled
                ? Icons.videocam
                : Icons.videocam_off),
            onPressed: videoRoomState.isJoined
                ? () => videoRoom.toggleCamera().catchError((e) {
                      AppLogger.error('Camera toggle failed: $e');
                    })
                : null,
          ),
          // Leave room
          IconButton(
            icon: const Icon(Icons.exit_to_app),
            onPressed: () => _handleLeaveRoom(context, videoRoom),
          ),
        ],
      ),
      body: VideoRoomBody(
        state: videoRoomState,
        controller: videoRoom,
      ),
    );
  }

  Future<void> _handleLeaveRoom(
      BuildContext context, VideoRoomNotifier controller) async {
    if (!context.mounted) return;
    try {
      await controller.leaveRoom();
      if (context.mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      AppLogger.error('Failed to leave room: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error leaving room: $e')),
        );
      }
    }
  }
}

/// Body widget for video room content
class VideoRoomBody extends StatelessWidget {
  final VideoRoomState state;
  final VideoRoomNotifier controller;

  const VideoRoomBody({
    super.key,
    required this.state,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    // Show appropriate UI based on state phase
    return Center(
      child: switch (state.phase) {
        VideoRoomPhase.notInitialized => _buildInitializingUI(context),
        VideoRoomPhase.initializing => _buildInitializingUI(context),
        VideoRoomPhase.joining => _buildJoiningUI(),
        VideoRoomPhase.joined => _buildJoinedUI(),
        VideoRoomPhase.leaving => _buildLeavingUI(),
        VideoRoomPhase.left => _buildLeftUI(),
        VideoRoomPhase.error => _buildErrorUI(),
      },
    );
  }

  Widget _buildInitializingUI(BuildContext context) {
    // Initialize video on first build
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!state.isInitialized && !state.isInitializing) {
        try {
          await controller.initializeVideo();
          // Auto-join after init
          await controller.joinRoom(
            roomName: 'room_${state.roomId}',
            token: 'mock_token',
          );
        } catch (e) {
          AppLogger.error('Init error: $e');
        }
      }
    });

    return const Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        CircularProgressIndicator(),
        SizedBox(height: 16),
        Text('Initializing video...'),
      ],
    );
  }

  Widget _buildJoiningUI() {
    return const Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        CircularProgressIndicator(),
        SizedBox(height: 16),
        Text('Joining room...'),
      ],
    );
  }

  Widget _buildJoinedUI() {
    return Container(
      color: DesignColors.background,
      child: Stack(
        children: [
          // Main video grid
          Column(
            children: [
              // Remote videos (grid layout)
              Expanded(
                child: state.remoteUserCount > 0
                    ? GridView.builder(
                        gridDelegate:
                            const SliverGridDelegateWithMaxCrossAxisExtent(
                          maxCrossAxisExtent: 300,
                          childAspectRatio: 1,
                        ),
                        itemCount: state.remoteUserCount,
                        itemBuilder: (context, index) {
                          return Container(
                            color: DesignColors.surfaceDark,
                            child: Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.videocam,
                                      size: 48, color: DesignColors.accent),
                                  const SizedBox(height: 8),
                                  Text('User ${index + 1}',
                                      style: const TextStyle(
                                          color: DesignColors.white)),
                                ],
                              ),
                            ),
                          );
                        },
                      )
                    : Container(
                        color: DesignColors.surfaceDark,
                        child: const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.videocam_off,
                                  size: 64, color: DesignColors.accent),
                              SizedBox(height: 16),
                              Text(
                                'Waiting for participants...',
                                style: TextStyle(
                                    color: DesignColors.white, fontSize: 16),
                              ),
                            ],
                          ),
                        ),
                      ),
              ),
              // Local video (small preview at bottom)
              Container(
                height: 120,
                color: DesignColors.background,
                padding: const EdgeInsets.all(8),
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: DesignColors.accent, width: 2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          state.cameraEnabled
                              ? Icons.videocam
                              : Icons.videocam_off,
                          size: 32,
                          color: state.cameraEnabled
                              ? DesignColors.accent
                              : DesignColors.gold,
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'You',
                          style: TextStyle(color: DesignColors.white),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          // Status overlay
          if (state.error != null)
            Positioned(
              top: 16,
              left: 16,
              right: 16,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: DesignColors.error,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  state.error!,
                  style: const TextStyle(
                    color: DesignColors.white,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildLeavingUI() {
    return const Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        CircularProgressIndicator(),
        SizedBox(height: 16),
        Text('Leaving room...'),
      ],
    );
  }

  Widget _buildLeftUI() {
    return const Text('Left room');
  }

  Widget _buildErrorUI() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.error, color: DesignColors.error, size: 48),
        const SizedBox(height: 16),
        Text('Error: ${state.error}', textAlign: TextAlign.center),
      ],
    );
  }
}
