import 'package:flutter/material.dart';

bool shouldTrackMicLevel({
  required bool isCallReady,
  required bool hasRtcService,
  required bool isMicMuted,
}) {
  return isCallReady && hasRtcService && !isMicMuted;
}

class LiveRoomMediaActionStrip extends StatelessWidget {
  const LiveRoomMediaActionStrip({
    super.key,
    required this.isCallReady,
    required this.hasRtcService,
    required this.isMicMuted,
    required this.isVideoEnabled,
    required this.isSharingSystemAudio,
    required this.isMicActionInFlight,
    required this.isVideoActionInFlight,
    required this.isSystemAudioActionInFlight,
    required this.localAudioLevel,
    required this.onToggleMic,
    required this.onToggleVideo,
    this.onLongPressVideo,
    this.onToggleSystemAudio,
    this.showSystemAudioButton = false,
    this.showMicLevel = true,
    this.iconColor = Colors.white,
    this.mutedColor = const Color(0xFFFF6E84),
    this.activeSystemAudioColor = const Color(0xFF7C5FFF),
  });

  final bool isCallReady;
  final bool hasRtcService;
  final bool isMicMuted;
  final bool isVideoEnabled;
  final bool isSharingSystemAudio;
  final bool isMicActionInFlight;
  final bool isVideoActionInFlight;
  final bool isSystemAudioActionInFlight;
  final double localAudioLevel;
  final VoidCallback? onToggleMic;
  final Future<void> Function() onToggleVideo;
  final VoidCallback? onLongPressVideo;
  final VoidCallback? onToggleSystemAudio;
  final bool showSystemAudioButton;
  final bool showMicLevel;
  final Color iconColor;
  final Color mutedColor;
  final Color activeSystemAudioColor;

  bool get _disableMic => !isCallReady || !hasRtcService || isMicActionInFlight;
  bool get _disableVideo =>
      !isCallReady || !hasRtcService || isVideoActionInFlight;
  bool get _disableSystemAudio =>
      !isCallReady || !hasRtcService || isSystemAudioActionInFlight;

  @override
  Widget build(BuildContext context) {
    final micButton = IconButton(
      tooltip: isMicMuted ? 'Unmute microphone' : 'Mute microphone',
      icon: Icon(
        isMicMuted ? Icons.mic_off : Icons.mic,
        color: isMicMuted ? mutedColor : iconColor,
      ),
      onPressed: _disableMic ? null : onToggleMic,
    );

    final videoButton = IconButton(
      tooltip: isVideoEnabled ? 'Turn camera off' : 'Turn camera on',
      icon: Icon(
        isVideoEnabled ? Icons.videocam : Icons.videocam_off,
        color: isVideoEnabled ? iconColor : mutedColor,
      ),
      onPressed: _disableVideo
          ? null
          : () {
              onToggleVideo();
            },
    );

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        micButton,
        if (showMicLevel &&
            shouldTrackMicLevel(
              isCallReady: isCallReady,
              hasRtcService: hasRtcService,
              isMicMuted: isMicMuted,
            ))
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Center(
              child: _MicLevelBar(level: localAudioLevel),
            ),
          ),
        Tooltip(
          message: isVideoEnabled
              ? 'Turn camera off (long-press to manage viewers)'
              : 'Turn camera on (long-press to manage viewers)',
          child: GestureDetector(
            onLongPress: onLongPressVideo,
            child: videoButton,
          ),
        ),
        if (showSystemAudioButton)
          IconButton(
            tooltip: isSharingSystemAudio
                ? 'Stop sharing computer audio'
                : 'Share computer audio',
            icon: Icon(
              isSharingSystemAudio ? Icons.headset : Icons.headset_off,
              color: isSharingSystemAudio
                  ? activeSystemAudioColor
                  : Colors.white70,
            ),
            onPressed: _disableSystemAudio ? null : onToggleSystemAudio,
          ),
      ],
    );
  }
}

class _MicLevelBar extends StatelessWidget {
  const _MicLevelBar({required this.level});

  final double level;

  @override
  Widget build(BuildContext context) {
    final clamped = level.clamp(0.0, 1.0);
    return SizedBox(
      width: 28,
      height: 12,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(999),
          color: Colors.white12,
        ),
        child: Align(
          alignment: Alignment.centerLeft,
          child: FractionallySizedBox(
            widthFactor: clamped,
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(999),
                color: clamped > 0.7
                    ? const Color(0xFFFF6E84)
                    : const Color(0xFF37D67A),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
