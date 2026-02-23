import 'package:flutter/material.dart';
import 'video_tile_widget.dart';
import '../../../controllers/video_window_controller.dart';

class FloatingWindowWidget extends StatelessWidget {
  final VideoWindowController controller;
  final VoidCallback? onClose;
  final VoidCallback? onMinimize;
  final VoidCallback? onMaximize;
  final VoidCallback? onPin;

  const FloatingWindowWidget({
    super.key,
    required this.controller,
    this.onClose,
    this.onMinimize,
    this.onMaximize,
    this.onPin,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        VideoTileWidget(
          controller: controller,
          onDoubleTap: onMaximize,
        ),

        // Window controls
        Positioned(
          top: 0,
          right: 0,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.7),
              borderRadius: const BorderRadius.only(
                topRight: Radius.circular(8),
                bottomLeft: Radius.circular(8),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: Icon(
                    controller.isPinned ? Icons.push_pin : Icons.push_pin_outlined,
                    color: Colors.white,
                    size: 16,
                  ),
                  onPressed: onPin,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                ),
                IconButton(
                  icon: const Icon(Icons.minimize, color: Colors.white, size: 16),
                  onPressed: onMinimize,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                ),
                IconButton(
                  icon: const Icon(Icons.crop_square, color: Colors.white, size: 16),
                  onPressed: onMaximize,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white, size: 16),
                  onPressed: onClose,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                ),
              ],
            ),
          ),
        ),

        // Resize handle
        Positioned(
          bottom: 0,
          right: 0,
          child: GestureDetector(
            onPanUpdate: (details) {
              final newSize = Size(
                controller.windowState.size.width + details.delta.dx,
                controller.windowState.size.height + details.delta.dy,
              );
              controller.resizeTo(newSize);
            },
            child: Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.7),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(8),
                ),
              ),
              child: const Icon(
                Icons.open_with,
                color: Colors.white,
                size: 12,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
