import 'package:flutter/material.dart';
import 'package:mix_and_mingle/shared/models/camera_state.dart';

class CameraTile extends StatelessWidget {
  final CameraState cameraState;
  final String roomId;
  final bool isSpotlighted;
  final VoidCallback onSelected;

  const CameraTile({
    super.key,
    required this.cameraState,
    required this.roomId,
    required this.isSpotlighted,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onSelected,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSpotlighted ? Colors.blue : Colors.grey[300]!,
            width: isSpotlighted ? 3 : 1,
          ),
          color: Colors.black87,
        ),
        child: Stack(
          children: [
            // Camera placeholder
            Center(
              child: Icon(
                Icons.videocam,
                size: 48,
                color: Colors.grey[600],
              ),
            ),

            // Status indicator
            Positioned(
              top: 8,
              left: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: _getStatusColor(),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _getStatusIcon(),
                    const SizedBox(width: 4),
                    Text(
                      _getStatusText(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Quality badge
            Positioned(
              top: 8,
              right: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 6,
                  vertical: 3,
                ),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  cameraState.qualityIcon,
                  style: const TextStyle(fontSize: 14),
                ),
              ),
            ),

            // User info
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.8),
                      Colors.black.withValues(alpha: 0.0),
                    ],
                  ),
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(12),
                    bottomRight: Radius.circular(12),
                  ),
                ),
                padding: const EdgeInsets.all(8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            cameraState.userName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ),
                        if (cameraState.isVIP)
                          const Padding(
                            padding: EdgeInsets.only(left: 4),
                            child: Icon(
                              Icons.star,
                              color: Colors.amber,
                              size: 14,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Icon(
                          Icons.visibility,
                          color: Colors.grey[400],
                          size: 12,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${cameraState.viewCount} views',
                          style: TextStyle(
                            color: Colors.grey[400],
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // Spotlight indicator
            if (isSpotlighted)
              Positioned(
                top: 50,
                left: 0,
                right: 0,
                bottom: 0,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.blue.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.blue, width: 2),
                    ),
                    child: const Icon(
                      Icons.center_focus_strong,
                      color: Colors.blue,
                      size: 28,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor() {
    switch (cameraState.status) {
      case CameraStatus.active:
        return Colors.green;
      case CameraStatus.loading:
        return Colors.orange;
      case CameraStatus.frozen:
        return Colors.red;
      case CameraStatus.error:
        return Colors.red;
      case CameraStatus.inactive:
        return Colors.grey;
    }
  }

  Widget _getStatusIcon() {
    switch (cameraState.status) {
      case CameraStatus.active:
        return const Icon(Icons.fiber_manual_record, size: 10, color: Colors.white);
      case CameraStatus.loading:
        return const SizedBox(
          width: 10,
          height: 10,
          child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation(Colors.white)),
        );
      case CameraStatus.frozen:
        return const Icon(Icons.ac_unit, size: 10, color: Colors.white);
      case CameraStatus.error:
        return const Icon(Icons.warning, size: 10, color: Colors.white);
      case CameraStatus.inactive:
        return const Icon(Icons.circle, size: 10, color: Colors.white);
    }
  }

  String _getStatusText() {
    switch (cameraState.status) {
      case CameraStatus.active:
        return 'LIVE';
      case CameraStatus.loading:
        return 'LOADING';
      case CameraStatus.frozen:
        return 'FROZEN';
      case CameraStatus.error:
        return 'ERROR';
      case CameraStatus.inactive:
        return 'OFFLINE';
    }
  }
}


