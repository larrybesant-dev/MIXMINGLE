import 'package:flutter/material.dart';
import '../../../controllers/video_window_controller.dart';
import '../../../core/design_system/design_constants.dart';

class MinimizedWindowWidget extends StatelessWidget {
  final VideoWindowController controller;
  final VoidCallback? onRestore;
  final VoidCallback? onClose;

  const MinimizedWindowWidget({
    super.key,
    required this.controller,
    this.onRestore,
    this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 200,
      height: 40,
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: DesignColors.surfaceLight,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: DesignColors.divider),
      ),
      child: Row(
        children: [
          // User avatar placeholder
          Container(
            width: 32,
            height: 32,
            margin: const EdgeInsets.all(4),
            decoration: const BoxDecoration(
              color: DesignColors.accent,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.person,
              color: DesignColors.white,
              size: 20,
            ),
          ),

          // User name
          Expanded(
            child: Text(
              'User ${controller.videoTile.userId.substring(0, 8)}',
              style: const TextStyle(
                color: DesignColors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),

          // Controls
          IconButton(
            icon: const Icon(Icons.restore, color: DesignColors.white, size: 16),
            onPressed: onRestore,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          ),

          IconButton(
            icon: const Icon(Icons.close, color: DesignColors.white, size: 16),
            onPressed: onClose,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          ),
        ],
      ),
    );
  }
}
