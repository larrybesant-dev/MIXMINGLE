import 'package:flutter/material.dart';
import 'video_tile_widget.dart';
import '../controllers/video_window_controller.dart';
import '../../../core/design_system/design_constants.dart';

class FullscreenWindowWidget extends StatelessWidget {
  final VideoWindowController controller;
  final VoidCallback? onExitFullscreen;

  const FullscreenWindowWidget({
    super.key,
    required this.controller,
    this.onExitFullscreen,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DesignColors.background,
      body: Stack(
        children: [
          // Fullscreen video
          Positioned.fill(
            child: VideoTileWidget(
              controller: controller,
              onDoubleTap: onExitFullscreen,
            ),
          ),

          // Exit fullscreen button
          Positioned(
            top: 40,
            right: 20,
            child: IconButton(
              icon: const Icon(
                Icons.fullscreen_exit,
                color: DesignColors.white,
                size: 32,
              ),
              onPressed: onExitFullscreen,
            ),
          ),

          // Fullscreen controls overlay
          Positioned(
            bottom: 40,
            left: 20,
            right: 20,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: DesignColors.overlay,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  IconButton(
                    icon: Icon(
                      controller.videoTile.isMuted ? Icons.mic_off : Icons.mic,
                      color: DesignColors.white,
                      size: 28,
                    ),
                    onPressed: () {
                      // Toggle mute - would connect to controller
                    },
                  ),
                  IconButton(
                    icon: Icon(
                      controller.videoTile.isVideoEnabled
                          ? Icons.videocam
                          : Icons.videocam_off,
                      color: DesignColors.white,
                      size: 28,
                    ),
                    onPressed: () {
                      // Toggle video - would connect to controller
                    },
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.settings,
                      color: DesignColors.white,
                      size: 28,
                    ),
                    onPressed: () {
                      // Open settings - would show quality options
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
