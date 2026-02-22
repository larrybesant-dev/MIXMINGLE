import 'package:flutter/material.dart';
import '../../../controllers/video_window_controller.dart';
import '../../../models/video_tile_model.dart';
import '../../../core/design_system/design_constants.dart';

class VideoTileWidget extends StatefulWidget {
  final VideoWindowController controller;
  final VoidCallback? onTap;
  final VoidCallback? onDoubleTap;
  final Function(Offset)? onDragStart;
  final Function(Offset)? onDragUpdate;
  final Function(Offset)? onDragEnd;

  const VideoTileWidget({
    super.key,
    required this.controller,
    this.onTap,
    this.onDoubleTap,
    this.onDragStart,
    this.onDragUpdate,
    this.onDragEnd,
  });

  @override
  State<VideoTileWidget> createState() => _VideoTileWidgetState();
}

class _VideoTileWidgetState extends State<VideoTileWidget> {
  Offset? _dragStartPosition;

  @override
  Widget build(BuildContext context) {
    final tile = widget.controller.videoTile;
    final window = widget.controller.windowState;

    return Positioned(
      left: window.position.dx,
      top: window.position.dy,
      child: GestureDetector(
        onTap: widget.onTap,
        onDoubleTap: widget.onDoubleTap,
        onPanStart: (details) {
          _dragStartPosition = details.globalPosition;
          widget.onDragStart?.call(details.globalPosition);
        },
        onPanUpdate: (details) {
          if (_dragStartPosition != null) {
            final delta = details.globalPosition - _dragStartPosition!;
            widget.onDragUpdate?.call(delta);
          }
        },
        onPanEnd: (details) {
          widget.onDragEnd?.call(details.velocity.pixelsPerSecond);
          _dragStartPosition = null;
        },
        child: Container(
          width: window.size.width,
          height: window.size.height,
          decoration: BoxDecoration(
            color: DesignColors.background,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: tile.state == VideoTileState.pinned
                  ? DesignColors.gold
                  : DesignColors.divider,
              width: tile.state == VideoTileState.pinned ? 3 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: DesignColors.shadowColor,
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Stack(
            children: [
              // Video content placeholder
              Center(
                child: Icon(
                  tile.isVideoEnabled ? Icons.videocam : Icons.videocam_off,
                  color: DesignColors.white,
                  size: 48,
                ),
              ),

              // User name
              Positioned(
                bottom: 8,
                left: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: DesignColors.overlay,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'User ${tile.userId.substring(0, 8)}',
                    style: const TextStyle(
                      color: DesignColors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),

              // Mute indicator
              if (!tile.isMuted)
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: DesignColors.error,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.mic_off,
                      color: DesignColors.white,
                      size: 16,
                    ),
                  ),
                ),

              // State indicator
              Positioned(
                top: 8,
                left: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: _getStateColor(tile.state),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _getStateText(tile.state),
                    style: const TextStyle(
                      color: DesignColors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getStateColor(VideoTileState state) {
    switch (state) {
      case VideoTileState.pinned:
        return DesignColors.gold;
      case VideoTileState.floating:
        return DesignColors.accent;
      case VideoTileState.minimized:
        return DesignColors.textGray;
      case VideoTileState.grid:
        return DesignColors.success;
    }
  }

  String _getStateText(VideoTileState state) {
    switch (state) {
      case VideoTileState.pinned:
        return 'PINNED';
      case VideoTileState.floating:
        return 'FLOAT';
      case VideoTileState.minimized:
        return 'MIN';
      case VideoTileState.grid:
        return 'GRID';
    }
  }
}
