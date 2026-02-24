import 'package:flutter/material.dart';
import '../models/agora_participant.dart';

/// Stage Layout â€” Spotlight + Thumbnails
/// Used in turn-based rooms to highlight the current speaker
///
/// Layout:
/// ```
/// â”Œâ”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”
/// â”‚                                 â”‚
/// â”‚      Spotlight (Speaker)        â”‚ â† Large, centered
/// â”‚                                 â”‚
/// â””â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”˜
/// â”Œâ”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”
/// â”‚ Thumb  Thumb  Thumb  Thumb ...  â”‚ â† 3-column grid, scrollable
/// â”‚ Thumb  Thumb  Thumb  Thumb ...  â”‚
/// â”‚                                 â”‚
/// â””â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”˜
/// ```
class StageLayout extends StatefulWidget {
  final int? speakerId; // Agora UID of current speaker
  final Map<int, AgoraParticipant> allParticipants;
  final Function(int) onTileTapped; // For future click handling
  final bool isCurrentUserSpeaker;

  const StageLayout({
    super.key,
    required this.speakerId,
    required this.allParticipants,
    required this.onTileTapped,
    this.isCurrentUserSpeaker = false,
  });

  @override
  State<StageLayout> createState() => _StageLayoutState();
}

class _StageLayoutState extends State<StageLayout> with SingleTickerProviderStateMixin {
  late AnimationController _spotlightAnimationController;
  late Animation<double> _spotlightFadeAnimation;

  @override
  void initState() {
    super.initState();
    _spotlightAnimationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _spotlightFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _spotlightAnimationController, curve: Curves.easeIn),
    );
    _spotlightAnimationController.forward();
  }

  @override
  void didUpdateWidget(StageLayout oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Fade animation on speaker change
    if (oldWidget.speakerId != widget.speakerId) {
      _spotlightAnimationController.reset();
      _spotlightAnimationController.forward();
    }
  }

  @override
  void dispose() {
    _spotlightAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Separate speaker from listeners
    final speaker = widget.speakerId != null ? widget.allParticipants[widget.speakerId] : null;

    final listeners = widget.allParticipants.entries
        .where((entry) => entry.key != widget.speakerId)
        .map((entry) => entry.value)
        .toList();

    return Column(
      children: [
        // Spotlight section (takes 60% of space)
        Expanded(
          flex: 60,
          child: speaker != null ? _buildSpotlight(speaker) : _buildEmptySpotlight(),
        ),

        const SizedBox(height: 8),

        // Thumbnails section (takes 40% of space)
        Expanded(
          flex: 40,
          child: listeners.isEmpty
              ? Center(
                  child: Text(
                    'Waiting for participants...',
                    style: TextStyle(
                      color: Colors.grey[500],
                      fontSize: 14,
                    ),
                  ),
                )
              : _buildThumbnailGrid(listeners),
        ),
      ],
    );
  }

  /// Spotlight tile with speaker badge and animations
  Widget _buildSpotlight(AgoraParticipant speaker) {
    return FadeTransition(
      opacity: _spotlightFadeAnimation,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.black,
          border: Border.all(
            color: Colors.amber.shade700,
            width: 3,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Stack(
          children: [
            // Video background
            Container(
              color: Colors.grey[900],
              child: Center(
                child: Text(
                  speaker.displayName.isNotEmpty ? speaker.displayName[0].toUpperCase() : '?',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),

            // Speaker name badge (top-left)
            Positioned(
              top: 12,
              left: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.black87,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.mic,
                      color: Colors.green,
                      size: 16,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      speaker.displayName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),

            // Status indicators (top-right)
            Positioned(
              top: 12,
              right: 12,
              child: Row(
                children: [
                  // Mute badge
                  if (!speaker.hasAudio)
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.red[700],
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.mic_off,
                        color: Colors.white,
                        size: 16,
                      ),
                    ),
                  const SizedBox(width: 6),

                  // Video off badge
                  if (!speaker.hasVideo)
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.grey[700],
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.videocam_off,
                        color: Colors.white,
                        size: 16,
                      ),
                    ),
                ],
              ),
            ),

            // Speaking animation (pulse border)
            if (speaker.isSpeaking)
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: Colors.green.withValues(alpha: 0.5),
                      width: 2,
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// Empty spotlight (no speaker assigned)
  Widget _buildEmptySpotlight() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[900],
        border: Border.all(
          color: Colors.grey[700] ?? Colors.grey,
          width: 2,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.mic,
              color: Colors.grey[600],
              size: 48,
            ),
            const SizedBox(height: 12),
            Text(
              'Waiting for speaker...',
              style: TextStyle(
                color: Colors.grey[500],
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 3-column grid of listener thumbnails
  Widget _buildThumbnailGrid(List<AgoraParticipant> listeners) {
    return GridView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 1.0,
        crossAxisSpacing: 4,
        mainAxisSpacing: 4,
      ),
      itemCount: listeners.length,
      itemBuilder: (context, index) {
        final listener = listeners[index];
        return _buildThumbnailTile(listener);
      },
    );
  }

  /// Individual thumbnail tile
  Widget _buildThumbnailTile(AgoraParticipant listener) {
    return GestureDetector(
      onTap: () => widget.onTileTapped(listener.uid),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.grey[900],
          border: Border.all(
            color: Colors.grey[800] ?? Colors.grey,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Stack(
          children: [
            // Avatar
            Center(
              child: Text(
                listener.displayName.isNotEmpty ? listener.displayName[0].toUpperCase() : '?',
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

            // Listener name (bottom)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                decoration: const BoxDecoration(
                  color: Colors.black87,
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(8),
                    bottomRight: Radius.circular(8),
                  ),
                ),
                child: Text(
                  listener.displayName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
              ),
            ),

            // Mute badge (top-right)
            if (!listener.hasAudio)
              Positioned(
                top: 4,
                right: 4,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.red[700],
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.mic_off,
                    color: Colors.white,
                    size: 10,
                  ),
                ),
              ),

            // Video off badge (top-left)
            if (!listener.hasVideo)
              Positioned(
                top: 4,
                left: 4,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.grey[700],
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.videocam_off,
                    color: Colors.white,
                    size: 10,
                  ),
                ),
              ),

            // Speaking indicator (green border)
            if (listener.isSpeaking)
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: Colors.green,
                      width: 1.5,
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
