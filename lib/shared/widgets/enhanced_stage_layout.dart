import 'package:flutter/material.dart';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import '../models/agora_participant.dart';

/// Enhanced Stage Layout with Real Agora Video Tiles
/// Professional video room experience with:
/// - Large spotlight for featured speaker
/// - Scrollable gallery of participants below
/// - Smooth transitions when speaker changes
/// - Speaking indicators and status badges
/// - Integrated chat overlay support
class EnhancedStageLayout extends StatefulWidget {
  final int? speakerId; // Agora UID of current speaker
  final Map<int, AgoraParticipant> allParticipants;
  final Function(int) onTileTapped;
  final int? localUid; // Local user's Agora UID
  final RtcEngine? rtcEngine;
  final String? channelId;
  final bool isCurrentUserSpeaker;
  final Widget? chatOverlay; // Optional chat overlay to layer on top
  final VoidCallback? onSpeakerTimeExpiring; // Turn-based timer warning

  const EnhancedStageLayout({
    super.key,
    required this.speakerId,
    required this.allParticipants,
    required this.onTileTapped,
    this.localUid,
    this.rtcEngine,
    this.channelId,
    this.isCurrentUserSpeaker = false,
    this.chatOverlay,
    this.onSpeakerTimeExpiring,
  });

  @override
  State<EnhancedStageLayout> createState() => _EnhancedStageLayoutState();
}

class _EnhancedStageLayoutState extends State<EnhancedStageLayout>
    with SingleTickerProviderStateMixin {
  late AnimationController _transitionController;
  late Animation<double> _spotlightFadeAnimation;
  late Animation<double> _spotlightScaleAnimation;

  @override
  void initState() {
    super.initState();
    _transitionController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _spotlightFadeAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _transitionController, curve: Curves.easeInOut),
    );

    _spotlightScaleAnimation = Tween<double>(begin: 0.95, end: 1.0).animate(
      CurvedAnimation(
          parent: _transitionController, curve: Curves.easeOutCubic),
    );

    _transitionController.forward();
  }

  @override
  void didUpdateWidget(EnhancedStageLayout oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Smooth transition when speaker changes
    if (oldWidget.speakerId != widget.speakerId) {
      _transitionController.reset();
      _transitionController.forward();
    }
  }

  @override
  void dispose() {
    _transitionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final speaker = widget.speakerId != null
        ? widget.allParticipants[widget.speakerId]
        : null;

    final listeners = widget.allParticipants.entries
        .where((entry) => entry.key != widget.speakerId)
        .map((entry) => MapEntry(entry.key, entry.value))
        .toList();

    return Stack(
      fit: StackFit.expand,
      children: [
        // Main layout
        Column(
          children: [
            // Spotlight section (65% of height)
            Expanded(
              flex: 65,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: speaker != null
                    ? _buildSpotlight(speaker)
                    : _buildEmptySpotlight(),
              ),
            ),

            // Separator
            Container(height: 1, color: Colors.grey[800]),

            // Gallery section (35% of height)
            Expanded(
              flex: 35,
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
                  : _buildGalleryGrid(listeners),
            ),
          ],
        ),

        // Optional chat overlay
        if (widget.chatOverlay != null)
          Positioned(
            bottom: 16,
            right: 16,
            width: 320,
            height: 400,
            child: widget.chatOverlay!,
          ),
      ],
    );
  }

  /// Large spotlight video tile for featured speaker
  Widget _buildSpotlight(AgoraParticipant speaker) {
    final isLocalUser = speaker.uid == widget.localUid;

    return ScaleTransition(
      scale: _spotlightScaleAnimation,
      child: FadeTransition(
        opacity: _spotlightFadeAnimation,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.black,
              border: Border.all(
                color: speaker.isSpeaking
                    ? Colors.greenAccent
                    : Colors.amber.shade700,
                width: 3,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: speaker.isSpeaking
                  ? [
                      BoxShadow(
                        color: Colors.greenAccent.withValues(alpha: 0.3),
                        blurRadius: 20,
                        spreadRadius: 4,
                      )
                    ]
                  : null,
            ),
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Video stream
                if (widget.rtcEngine != null)
                  AgoraVideoView(
                    controller: isLocalUser
                        ? VideoViewController(
                            rtcEngine: widget.rtcEngine!,
                            canvas: const VideoCanvas(uid: 0),
                          )
                        : VideoViewController.remote(
                            rtcEngine: widget.rtcEngine!,
                            canvas: VideoCanvas(uid: speaker.uid),
                            connection: RtcConnection(
                              channelId: widget.channelId ?? '',
                            ),
                          ),
                  )
                else
                  Container(
                    color: Colors.grey[900],
                    child: Center(
                      child: Text(
                        speaker.displayName.isNotEmpty
                            ? speaker.displayName[0].toUpperCase()
                            : '?',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 64,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),

                // Gradient overlay for UI readability
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  height: 120,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [
                          Colors.black.withValues(alpha: 0.8),
                          Colors.black.withValues(alpha: 0.4),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),

                // Speaker badge (top-left)
                Positioned(
                  top: 16,
                  left: 16,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.7),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.amber, width: 1.5),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: speaker.isSpeaking
                                ? Colors.greenAccent
                                : Colors.grey,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'ðŸŽ¤ On Stage',
                          style: TextStyle(
                            color: Colors.amber[300],
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Name tag (bottom-left)
                Positioned(
                  bottom: 16,
                  left: 16,
                  right: 16,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        isLocalUser ? 'You (Live)' : speaker.displayName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          if (!speaker.hasAudio)
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: Colors.red[700],
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.mic_off,
                                color: Colors.white,
                                size: 14,
                              ),
                            ),
                          if (!speaker.hasAudio && !speaker.hasVideo)
                            const SizedBox(width: 8),
                          if (!speaker.hasVideo)
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: Colors.grey[700],
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.videocam_off,
                                color: Colors.white,
                                size: 14,
                              ),
                            ),
                          if (speaker.isSpeaking) ...[
                            const SizedBox(width: 8),
                            const Icon(
                              Icons.graphic_eq,
                              color: Colors.greenAccent,
                              size: 16,
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),

                // Status indicators (top-right)
                Positioned(
                  top: 16,
                  right: 16,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (widget.isCurrentUserSpeaker)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.pinkAccent.withValues(alpha: 0.2),
                            border: Border.all(
                              color: Colors.pinkAccent,
                              width: 1.5,
                            ),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            'ðŸŽ¯ Your Turn',
                            style: TextStyle(
                              color: Colors.pinkAccent,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Empty spotlight placeholder
  Widget _buildEmptySpotlight() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[900],
        border: Border.all(
          color: Colors.grey[700] ?? Colors.grey,
          width: 2,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.mic,
              color: Colors.grey[600],
              size: 56,
            ),
            const SizedBox(height: 16),
            Text(
              'Waiting for speaker...',
              style: TextStyle(
                color: Colors.grey[500],
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Next speaker will be assigned soon',
              style: TextStyle(
                color: Colors.grey[700],
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Gallery grid of participant thumbnails
  Widget _buildGalleryGrid(List<MapEntry<int, AgoraParticipant>> listeners) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Row(
        children: [
          for (final entry in listeners)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: _buildGalleryTile(entry.key, entry.value),
            ),
        ],
      ),
    );
  }

  /// Individual gallery tile with video
  Widget _buildGalleryTile(int uid, AgoraParticipant participant) {
    final isLocalUser = uid == widget.localUid;

    return GestureDetector(
      onTap: () => widget.onTileTapped(uid),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 120,
        height: 160,
        decoration: BoxDecoration(
          color: Colors.grey[900],
          border: Border.all(
            color: participant.isSpeaking
                ? Colors.greenAccent
                : Colors.grey[800] ?? Colors.grey,
            width: participant.isSpeaking ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
          boxShadow: participant.isSpeaking
              ? [
                  BoxShadow(
                    color: Colors.greenAccent.withValues(alpha: 0.2),
                    blurRadius: 8,
                    spreadRadius: 1,
                  )
                ]
              : null,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Video stream
              if (widget.rtcEngine != null)
                AgoraVideoView(
                  controller: isLocalUser
                      ? VideoViewController(
                          rtcEngine: widget.rtcEngine!,
                          canvas: const VideoCanvas(uid: 0),
                        )
                      : VideoViewController.remote(
                          rtcEngine: widget.rtcEngine!,
                          canvas: VideoCanvas(uid: uid),
                          connection: RtcConnection(
                            channelId: widget.channelId ?? '',
                          ),
                        ),
                )
              else
                Container(
                  color: Colors.grey[800],
                  child: Center(
                    child: Text(
                      participant.displayName.isNotEmpty
                          ? participant.displayName[0].toUpperCase()
                          : '?',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),

              // Gradient overlay
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                height: 60,
                child: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [
                        Colors.black87,
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),

              // Name tag (bottom)
              Positioned(
                bottom: 6,
                left: 6,
                right: 6,
                child: Text(
                  isLocalUser ? 'You' : participant.displayName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
              ),

              // Status badges (top-right)
              Positioned(
                top: 4,
                right: 4,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (!participant.hasAudio)
                      Container(
                        padding: const EdgeInsets.all(3),
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
                    if (!participant.hasVideo && participant.hasAudio)
                      Container(
                        padding: const EdgeInsets.all(3),
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
                  ],
                ),
              ),

              // Speaking indicator
              if (participant.isSpeaking)
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: Colors.greenAccent,
                        width: 2,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
