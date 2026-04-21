import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

import '../providers/message_providers.dart';
import '../providers/room_live_state_provider.dart';
import '../../../dev/room_inspector_panel.dart';

// Wide-screen cap — prevents the chat from stretching across a 1440px monitor.
const double _kMaxBodyWidth = 720;

// ─────────────────────────────────────────────────────────────────────────────
// ROOT SCREEN
// Owns the Riverpod watch and routes to one of three scaffold variants.
//
// Reconnect rule:
//   If we have a previous emission (valueOrNull != null), always show the room
//   — never go blank because of a transient stream error or refresh.
// ─────────────────────────────────────────────────────────────────────────────

class LiveRoomScreen extends ConsumerStatefulWidget {
  final String roomId;
  const LiveRoomScreen({super.key, required this.roomId});

  @override
  ConsumerState<LiveRoomScreen> createState() => _LiveRoomScreenState();
}

class _LiveRoomScreenState extends ConsumerState<LiveRoomScreen> {
  @override
  void dispose() {
    // Reset the diff tracker so the next room starts with a clean baseline.
    RoomContractGuard.reset();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final snapshot = ref.watch(roomLiveStateProvider(widget.roomId));
    final liveState = snapshot.valueOrNull;

    // Previous data exists → show room; reconnecting banner if stream is
    // currently loading (provider refresh) or has errored (connection drop).
    if (liveState != null) {
      return _RoomScaffold(
        roomId: widget.roomId,
        roomState: liveState,
        reconnecting: snapshot.isLoading || snapshot.hasError,
      );
    }

    // No previous data yet — pure initial states.
    return snapshot.when(
      loading: () => _LoadingScaffold(roomId: widget.roomId),
      error: (e, _) => _ErrorScaffold(
        error: e,
        onBack: () => Navigator.of(context).maybePop(),
      ),
      data: (_) => _LoadingScaffold(roomId: widget.roomId), // unreachable
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// LOADING SCAFFOLD
// Shown only on first load before the first stream emission arrives.
// ─────────────────────────────────────────────────────────────────────────────

class _LoadingScaffold extends StatelessWidget {
  final String roomId;
  const _LoadingScaffold({required this.roomId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: const BackButton(),
        title: const Text('Loading room…'),
      ),
      body: const Center(child: CircularProgressIndicator()),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// ERROR SCAFFOLD
// Shown only when the stream errors with no previous emission.
// Distinguishes schema failures (bad data) from connection failures.
// Debug mode shows the raw error detail; release shows a clean message.
// ─────────────────────────────────────────────────────────────────────────────

class _ErrorScaffold extends StatelessWidget {
  final Object error;
  final VoidCallback onBack;
  const _ErrorScaffold({required this.error, required this.onBack});

  @override
  Widget build(BuildContext context) {
    final isSchema = error is RoomSchemaException;
    final heading = isSchema ? 'Room data error' : 'Unable to load room';
    final icon =
        isSchema ? Icons.warning_amber_rounded : Icons.wifi_off_rounded;

    return Scaffold(
      appBar: AppBar(
        leading: BackButton(onPressed: onBack),
        title: Text(heading),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  size: 48,
                  color: Theme.of(context).colorScheme.error,
                ),
                const SizedBox(height: 16),
                Text(
                  heading,
                  style: Theme.of(context).textTheme.titleMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  isSchema
                      ? 'This room has an unexpected data format. '
                          'Please try again or contact support.'
                      : 'Check your connection and try again.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                if (kDebugMode) ...[
                  const SizedBox(height: 12),
                  Text(
                    error.toString(),
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.error,
                        ),
                  ),
                ],
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: onBack,
                  child: const Text('Go back'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// ROOM SCAFFOLD
// The live view. Width-constrained for large screens.
// Shows a reconnecting banner at the top when the stream is temporarily
// unavailable but we still have the last known state.
// ─────────────────────────────────────────────────────────────────────────────

class _RoomScaffold extends StatelessWidget {
  final String roomId;
  final RoomLiveState roomState;
  final bool reconnecting;

  const _RoomScaffold({
    required this.roomId,
    required this.roomState,
    required this.reconnecting,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: const BackButton(),
        title: Text(roomState.title.isEmpty ? 'Room' : roomState.title),
        actions: [
          // Inspector button is a no-op in release builds — gated inside
          // RoomInspectorButton by kEnableVisibilityDiagnostics.
          RoomInspectorButton(roomId: roomId),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: _kMaxBodyWidth),
          child: Column(
            children: [
              if (reconnecting) const _ReconnectingBanner(),
              Expanded(
                child: _MessageList(messages: roomState.messages),
              ),
              _TypingIndicator(
                typingUsers: roomState.typingUsers.keys.toList(),
              ),
              const _RoomActionBar(),
              _MessageInput(roomId: roomId),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// RECONNECTING BANNER
// Shown at the top of the room when the stream is loading/erroring but we
// still have a previous state to display. Never blank, always informative.
// ─────────────────────────────────────────────────────────────────────────────

class _ReconnectingBanner extends StatelessWidget {
  const _ReconnectingBanner();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return ColoredBox(
      color: cs.errorContainer,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 12,
              height: 12,
              child: CircularProgressIndicator(
                strokeWidth: 1.5,
                valueColor: AlwaysStoppedAnimation(cs.onErrorContainer),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'Reconnecting…',
              style: TextStyle(fontSize: 12, color: cs.onErrorContainer),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// MESSAGE LIST
// Shows an empty-state prompt when there are no messages yet — never blank.
// ─────────────────────────────────────────────────────────────────────────────

class _MessageList extends StatelessWidget {
  final List messages;
  const _MessageList({required this.messages});

  @override
  Widget build(BuildContext context) {
    if (messages.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'No messages yet.\nBe the first to say something!',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey),
          ),
        ),
      );
    }

    return ListView.builder(
      reverse: true,
      itemCount: messages.length,
      itemBuilder: (_, i) {
        final msg = messages[i];
        return ListTile(
          title: Text(msg.content),
          subtitle: Text(msg.senderId),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// TYPING INDICATOR
// ─────────────────────────────────────────────────────────────────────────────

class _TypingIndicator extends StatelessWidget {
  final List<String> typingUsers;
  const _TypingIndicator({required this.typingUsers});

  @override
  Widget build(BuildContext context) {
    if (typingUsers.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Text(
        '${typingUsers.join(", ")} typing…',
        style: const TextStyle(fontStyle: FontStyle.italic, fontSize: 12),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// MESSAGE INPUT
// OutlineInputBorder for clear tap target. Responds to keyboard Enter/Done.
// Controller is disposed in dispose() to prevent memory leaks.
// ─────────────────────────────────────────────────────────────────────────────

class _MessageInput extends ConsumerStatefulWidget {
  final String roomId;
  const _MessageInput({required this.roomId});

  @override
  ConsumerState<_MessageInput> createState() => _MessageInputState();
}

class _MessageInputState extends ConsumerState<_MessageInput> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _controller,
                decoration: const InputDecoration(
                  hintText: 'Send a message…',
                  border: OutlineInputBorder(),
                  isDense: true,
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                ),
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _send(),
              ),
            ),
            const SizedBox(width: 4),
            IconButton(
              icon: const Icon(Icons.send),
              onPressed: _send,
            ),
          ],
        ),
      ),
    );
  }

  void _send() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    _controller.clear();
    ref.read(sendMessageProvider(widget.roomId))(text).catchError((_) {});
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// ROOM ACTION BAR
//
// Current state: pure UI scaffolding — no RTC or audio implementation.
//
// INTENDED RTC INTEGRATION (do not implement here yet):
//
//   MIC:
//     • getUserMedia({ audio: true }) via RtcRoomService.setBroadcaster()
//     • _micActive → replace setState with ref.read(rtcMicProvider.notifier)
//     • Mute path → RtcRoomService.mute(true/false)
//
//   SCREEN / AUDIO SHARE:
//     • getDisplayMedia({ video: true, audio: true }) — web only
//     • _audioShareAvailable → replace with ref.watch(roomCapabilityProvider)
//       which checks kIsWeb && navigator.mediaDevices.getDisplayMedia support
//     • _sharingAudio → replace setState with ref.read(audioShareProvider.notifier)
//     • _startScreenShare / _stopScreenShare wired to RtcRoomService
//
//   STREAM LIFECYCLE:
//     • Tracks cleaned up in provider dispose(), not here
//     • This widget becomes ConsumerStatefulWidget at integration time
//
// DOES NOT touch sendMessageProvider or messaging pipeline.
// ─────────────────────────────────────────────────────────────────────────────

class _RoomActionBar extends StatefulWidget {
  const _RoomActionBar();

  @override
  State<_RoomActionBar> createState() => _RoomActionBarState();
}

class _RoomActionBarState extends State<_RoomActionBar> {
  // ── Audio UI state block ────────────────────────────────────────────────────
  // All three fields below are UI-only. They move to provider watchers together
  // during RTC integration — do not scatter them across the widget.

  /// true = mic is live/publishing; false = muted.
  /// Initial value: false — mic starts off until user explicitly enables it.
  bool _micActive = false;

  /// Active microphone [MediaStream] acquired via getUserMedia.
  /// Null when mic is off or not yet requested.
  MediaStream? _micStream;

  /// Capability gate: whether getDisplayMedia is available for this session.
  /// TODO(rtc): replace with `kIsWeb && _checkGetDisplayMediaSupport()` once
  /// RTC integration lands. Keep false until then so the button stays disabled.
  bool get _audioShareAvailable => false;

  /// true = screen/system audio share is currently active.
  /// Override via audioShareProvider.notifier on wiring.
  bool _sharingAudio = false;

  // ── RTC lifecycle ────────────────────────────────────────────────────────────

  /// Acquires or releases the microphone via getUserMedia.
  /// Mic state (_micActive) is only updated AFTER the async operation resolves
  /// so the UI never shows an optimistic state that getUserMedia then denies.
  Future<void> _toggleMic() async {
    if (!_micActive) {
      // ── Enable mic ────────────────────────────────────────────────────────
      // Reuse an existing stream if one is already open (prevents double-capture).
      if (_micStream != null) {
        if (!mounted) return;
        setState(() => _micActive = true);
        return;
      }
      try {
        final stream = await navigator.mediaDevices.getUserMedia({
          'audio': true,
          'video': false,
        });
        if (!mounted) {
          // Widget was disposed while awaiting — clean up immediately.
          for (final track in stream.getAudioTracks()) {
            await track.stop();
          }
          return;
        }
        setState(() {
          _micStream = stream;
          _micActive = true;
        });
      } catch (e) {
        developer.log('_toggleMic: getUserMedia failed — $e',
            name: 'LiveRoomScreen');
        // Permission denied or hardware error — revert to off, no crash.
        if (!mounted) return;
        setState(() {
          _micActive = false;
          _micStream = null;
        });
      }
    } else {
      // ── Disable mic ───────────────────────────────────────────────────────
      _stopMicStream();
      if (!mounted) return;
      setState(() => _micActive = false);
    }
  }

  /// Stops all audio tracks and clears the stream reference.
  void _stopMicStream() {
    final stream = _micStream;
    if (stream == null) return;
    for (final track in stream.getAudioTracks()) {
      track.stop();
    }
    _micStream = null;
  }

  /// TODO(rtc): call getDisplayMedia({ video: true, audio: true }),
  /// attach resulting stream to RtcRoomService, then update _sharingAudio.
  Future<void> _startScreenShare() async { // ignore: unused_element
    // No-op until RTC integration.
    if (!mounted) return;
    setState(() => _sharingAudio = true);
  }

  /// TODO(rtc): stop getDisplayMedia tracks, detach from RtcRoomService,
  /// then update _sharingAudio.
  Future<void> _stopScreenShare() async {
    // No-op until RTC integration.
    if (!mounted) return;
    setState(() => _sharingAudio = false);
  }

  // ── Lifecycle ────────────────────────────────────────────────────────────────

  @override
  void dispose() {
    _stopMicStream();
    super.dispose();
  }

  // ── Build ───────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: cs.outlineVariant, width: 0.5),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        child: Row(
          children: [
            // ── Mic ──────────────────────────────────────────────────────
            // Active (publishing):   mic_rounded,    default tonal
            // Muted:                 mic_off_rounded, errorContainer tint
            IconButton.filledTonal(
              tooltip: _micActive ? 'Mute mic' : 'Unmute mic',
              onPressed: () => _toggleMic(),  // async — fire and forget
              style: !_micActive
                  ? IconButton.styleFrom(
                      backgroundColor: cs.errorContainer,
                      foregroundColor: cs.onErrorContainer,
                    )
                  : null,
              icon: Icon(
                _micActive ? Icons.mic_rounded : Icons.mic_off_rounded,
              ),
            ),
            const SizedBox(width: 4),
            // ── Audio share ──────────────────────────────────────────────
            // Disabled (capability absent):
            //   onPressed null → Flutter filledTonal auto-greys icon + bg
            //   tooltip explains reason
            // Inactive (available, not sharing):
            //   screen_share_outlined, default tonal
            // Active (sharing):
            //   graphic_eq ("turntable"), primaryContainer tint
            IconButton.filledTonal(
              tooltip: !_audioShareAvailable
                  ? 'Screen sharing unavailable (web permission required)'
                  : _sharingAudio
                      ? 'Stop audio share'
                      : 'Share audio',
              onPressed: !_audioShareAvailable
                  ? null
                  : () async {
                      if (_sharingAudio) {
                        await _stopScreenShare();
                      } else {
                        await _startScreenShare();
                      }
                    },
              style: _audioShareAvailable && _sharingAudio
                  ? IconButton.styleFrom(
                      backgroundColor: cs.primaryContainer,
                      foregroundColor: cs.onPrimaryContainer,
                    )
                  : null,
              icon: Icon(
                _audioShareAvailable && _sharingAudio
                    ? Icons.graphic_eq
                    : Icons.screen_share_outlined,
              ),
            ),
            // Spacer keeps buttons left-anchored; future action slots go here.
            const Spacer(),
          ],
        ),
      ),
    );
  }
}