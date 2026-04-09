import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/room_participant_model.dart';
import '../providers/participant_providers.dart';

/// Compact panel shown above the chat that lists everyone currently on the mic
/// (roles: host, cohost, stage). Visible to all room participants.
/// Disappears when only the host is on mic alone (nothing extra to show).
class OnMicPanel extends ConsumerWidget {
  const OnMicPanel({
    super.key,
    required this.roomId,
    required this.currentUserId,
    required this.displayNameById,
  });

  final String roomId;
  final String currentUserId;

  /// Display-name lookup keyed by userId (same map used by UserListPanel).
  final Map<String, String> displayNameById;

  static const _npSurfaceContainer = Color(0xFF161A21);
  static const _npSurfaceHigh = Color(0xFF241820);
  static const _npSecondary = Color(0xFFC45E7A);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final onMicAsync = ref.watch(onMicParticipantsProvider(roomId));

    return onMicAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (err, st) => const SizedBox.shrink(),
      data: (participants) {
        // Hide the panel when there's no one beyond the default host-only state.
        if (participants.isEmpty) return const SizedBox.shrink();

        return Container(
          decoration: const BoxDecoration(
            color: _npSurfaceContainer,
            border: Border(
              top: BorderSide(color: Color(0x14FFFFFF)),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header ──────────────────────────────────────────────────
              Container(
                height: 28,
                color: _npSurfaceHigh,
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Row(
                  children: [
                    const _PulsingMicIcon(),
                    const SizedBox(width: 6),
                    Text(
                      'On Mic  •  ${participants.length}',
                      style: const TextStyle(
                        color: _npSecondary,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ],
                ),
              ),
              // ── Participant list (max 4 visible, scrollable) ─────────
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 128),
                child: ListView.builder(
                  padding: EdgeInsets.zero,
                  shrinkWrap: true,
                  physics: const ClampingScrollPhysics(),
                  itemCount: participants.length,
                  itemBuilder: (context, index) {
                    final p = participants[index];
                    final name = displayNameById[p.userId] ?? p.userId;
                    final isMe = p.userId == currentUserId;
                    return _OnMicRow(
                      participant: p,
                      name: isMe ? '$name (you)' : name,
                      isMe: isMe,
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _OnMicRow extends StatefulWidget {
  const _OnMicRow({
    required this.participant,
    required this.name,
    required this.isMe,
  });

  final RoomParticipantModel participant;
  final String name;
  final bool isMe;

  @override
  State<_OnMicRow> createState() => _OnMicRowState();
}

class _OnMicRowState extends State<_OnMicRow> {
  Timer? _tickTimer;
  int _secondsLeft = 0; // 0 = no timer / expired

  static const _npPrimary = Color(0xFFD4A853);
  static const _npSecondary = Color(0xFFC45E7A);
  static const _npOnVariant = Color(0xFFB09080);
  static const _npStage = Color(0xFFFFA040);

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  @override
  void didUpdateWidget(_OnMicRow old) {
    super.didUpdateWidget(old);
    if (old.participant.micExpiresAt != widget.participant.micExpiresAt) {
      _tickTimer?.cancel();
      _startTimer();
    }
  }

  @override
  void dispose() {
    _tickTimer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    final exp = widget.participant.micExpiresAt;
    if (exp == null || widget.participant.role != 'stage') {
      _secondsLeft = 0;
      return;
    }
    _updateSecondsLeft(exp);
    if (_secondsLeft > 0) {
      _tickTimer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (!mounted) return;
        _updateSecondsLeft(exp);
        if (_secondsLeft <= 0) _tickTimer?.cancel();
      });
    }
  }

  void _updateSecondsLeft(DateTime exp) {
    final remaining = exp.difference(DateTime.now()).inSeconds;
    setState(() => _secondsLeft = remaining < 0 ? 0 : remaining);
  }

  Color get _roleColor {
    switch (widget.participant.role) {
      case 'host':
      case 'owner':
        return _npPrimary;
      case 'cohost':
        return _npSecondary;
      case 'stage':
        return _npStage;
      default:
        return _npOnVariant;
    }
  }

  String get _roleLabel {
    switch (widget.participant.role) {
      case 'host':
      case 'owner':
        return 'HOST';
      case 'cohost':
        return 'CO-HOST';
      case 'stage':
        return 'MIC';
      default:
        return '';
    }
  }

  IconData get _roleIcon {
    switch (widget.participant.role) {
      case 'host':
      case 'owner':
        return Icons.workspace_premium_outlined;
      case 'cohost':
        return Icons.star_outline_rounded;
      case 'stage':
        return Icons.record_voice_over_outlined;
      default:
        return Icons.mic_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMuted = widget.participant.isMuted || !widget.participant.micOn;
    final showTimer = widget.participant.role == 'stage' &&
        widget.participant.micExpiresAt != null;

    // Timer badge color: green → orange → red as time runs low
    Color timerColor = const Color(0xFF4CAF50);
    if (_secondsLeft <= 10) {
      timerColor = const Color(0xFFFF5252);
    } else if (_secondsLeft <= 20) {
      timerColor = const Color(0xFFFF9800);
    }

    return Container(
      height: 32,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: widget.isMe ? _npPrimary.withValues(alpha: 0.07) : Colors.transparent,
        border: const Border(
          bottom: BorderSide(color: Color(0x0DFFFFFF)),
        ),
      ),
      child: Row(
        children: [
          // Role icon
          Icon(_roleIcon, color: _roleColor, size: 13),
          const SizedBox(width: 6),
          // Name
          Expanded(
            child: Text(
              widget.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: widget.isMe ? _npPrimary : Colors.white,
                fontSize: 12,
                fontWeight: widget.isMe ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ),
          // Countdown badge (stage users with a timer)
          if (showTimer) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
              decoration: BoxDecoration(
                color: timerColor.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.timer_outlined, size: 9, color: timerColor),
                  const SizedBox(width: 2),
                  Text(
                    _secondsLeft > 0
                        ? '${_secondsLeft ~/ 60}:${(_secondsLeft % 60).toString().padLeft(2, '0')}'
                        : '0:00',
                    style: TextStyle(
                      color: timerColor,
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 4),
          ],
          // Role badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
            decoration: BoxDecoration(
              color: _roleColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              _roleLabel,
              style: TextStyle(
                color: _roleColor,
                fontSize: 9,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
              ),
            ),
          ),
          const SizedBox(width: 6),
          // Mic state
          Icon(
            isMuted ? Icons.mic_off : Icons.mic,
            size: 13,
            color: isMuted ? const Color(0xFFFF6E84) : _npSecondary,
          ),
        ],
      ),
    );
  }
}

/// Pulsing mic icon to draw attention to the "On Mic" header.
class _PulsingMicIcon extends StatefulWidget {
  const _PulsingMicIcon();

  @override
  State<_PulsingMicIcon> createState() => _PulsingMicIconState();
}

class _PulsingMicIconState extends State<_PulsingMicIcon>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _opacity = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacity,
      child: const Icon(Icons.mic, color: Color(0xFFC45E7A), size: 14),
    );
  }
}
