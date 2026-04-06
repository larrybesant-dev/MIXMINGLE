import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Bottom sheet that shows a camera preview and lets the user confirm
/// before going live. On web it relies on the WebRTC local stream already
/// captured by [RtcRoomService]; on native it uses the Agora local preview.
///
/// The sheet is purely informational — the actual camera enable/disable is
/// handled by the parent via [onConfirm]/[onCancel].
class CamPreviewSheet extends StatelessWidget {
  const CamPreviewSheet({
    super.key,
    required this.previewWidget,
    required this.onConfirm,
    required this.onCancel,
    this.isVideoEnabled = false,
  });

  /// The local camera preview widget (AgoraVideoView / WebRTC RTCVideoRenderer view).
  final Widget previewWidget;
  final VoidCallback onConfirm;
  final VoidCallback onCancel;
  final bool isVideoEnabled;

  static Future<bool?> show(
    BuildContext context, {
    required Widget previewWidget,
    required bool isVideoEnabled,
  }) {
    return showModalBottomSheet<bool>(
      context: context,
      backgroundColor: const Color(0xFF1C2028),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => CamPreviewSheet(
        previewWidget: previewWidget,
        isVideoEnabled: isVideoEnabled,
        onConfirm: () => Navigator.of(ctx).pop(true),
        onCancel: () => Navigator.of(ctx).pop(false),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: const Color(0xFF3A3E47),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const Text(
            'Camera Preview',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          // Preview area
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: AspectRatio(
              aspectRatio: 4 / 3,
              child: ColoredBox(
                color: const Color(0xFF0B0E14),
                child: isVideoEnabled
                    ? previewWidget
                    : const Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.videocam_off,
                                color: Color(0xFFA9ABB3),
                                size: 40),
                            SizedBox(height: 8),
                            Text(
                              'Camera not started yet',
                              style: TextStyle(
                                color: Color(0xFFA9ABB3),
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Info text
          Text(
            kIsWeb
                ? 'Your camera will be visible to others once you go live.'
                : 'Preview your camera before broadcasting.',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFFA9ABB3),
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 20),
          // Action buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: onCancel,
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFF3A3E47)),
                    foregroundColor: const Color(0xFFA9ABB3),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text('Cancel'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: onConfirm,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFBA9EFF),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'Go Live 📷',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
