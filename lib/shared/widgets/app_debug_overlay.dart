import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/telemetry/app_telemetry.dart';

class AppDebugOverlay extends StatefulWidget {
  const AppDebugOverlay({super.key, required this.child});

  final Widget child;

  @override
  State<AppDebugOverlay> createState() => _AppDebugOverlayState();
}

class _AppDebugOverlayState extends State<AppDebugOverlay> {
  bool _isVisible = false;
  int _secretTapCount = 0;
  Timer? _secretTapTimer;

  @override
  void dispose() {
    _secretTapTimer?.cancel();
    super.dispose();
  }

  void _toggleOverlay() {
    setState(() => _isVisible = !_isVisible);
  }

  void _registerSecretTap() {
    _secretTapCount += 1;
    _secretTapTimer?.cancel();
    _secretTapTimer = Timer(const Duration(seconds: 2), () {
      _secretTapCount = 0;
    });
    if (_secretTapCount >= 5) {
      _secretTapCount = 0;
      _toggleOverlay();
    }
  }

  @override
  Widget build(BuildContext context) {
    final topInset = MediaQuery.of(context).padding.top;
    return Stack(
      fit: StackFit.expand,
      children: [
        widget.child,
        Positioned(
          right: 12,
          bottom: 12,
          child: GestureDetector(
            onLongPress: _toggleOverlay,
            onTap: _registerSecretTap,
            behavior: HitTestBehavior.opaque,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                color: _isVisible
                    ? const Color(0xFFD4AF37).withValues(alpha: 0.88)
                    : const Color(0xFFD4AF37).withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(
                  color: const Color(0xFFF7EDE2).withValues(alpha: 0.35),
                ),
              ),
              child: const Icon(
                Icons.bug_report_outlined,
                size: 12,
                color: Color(0xFFF7EDE2),
              ),
            ),
          ),
        ),
        if (_isVisible)
          Positioned(
            top: topInset + 12,
            right: 12,
            child: SafeArea(
              child: Material(
                elevation: 14,
                color: const Color(0xF00B0B0B),
                borderRadius: BorderRadius.circular(18),
                child: Container(
                  width: 360,
                  constraints: const BoxConstraints(maxHeight: 520),
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: const Color(0xFFD4AF37).withValues(alpha: 0.55),
                    ),
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xF01A1114), Color(0xF00B0B0B)],
                    ),
                  ),
                  child: ValueListenableBuilder<AppTelemetryState>(
                    valueListenable: AppTelemetry.notifier,
                    builder: (context, state, _) {
                      final duplicateListeners = state.duplicateListenerKeys;
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            children: [
                              const Expanded(
                                child: Text(
                                  'Live Debug',
                                  style: TextStyle(
                                    color: Color(0xFFF7EDE2),
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                              IconButton(
                                onPressed: _toggleOverlay,
                                icon: const Icon(Icons.close, size: 18),
                                color: const Color(0xFFF7EDE2),
                                splashRadius: 18,
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          _DebugLine(label: 'Auth', value: state.authUserId ?? 'anonymous'),
                          _DebugLine(
                            label: 'Auth load',
                            value: state.authLoading ? 'loading' : 'idle',
                          ),
                          _DebugLine(label: 'Room', value: state.roomId ?? '-'),
                          _DebugLine(label: 'Phase', value: state.roomPhase ?? '-'),
                          _DebugLine(
                            label: 'Participants',
                            value: state.participantCount.toString(),
                          ),
                          _DebugLine(
                            label: 'Camera',
                            value: state.videoEnabled ? 'on' : 'off',
                          ),
                          _DebugLine(
                            label: 'Mic',
                            value: state.micMuted ? 'muted' : 'live',
                          ),
                          _DebugLine(
                            label: 'Presence',
                            value: state.presenceStatus ?? state.roomPresenceStatus ?? '-',
                          ),
                          _DebugLine(label: 'In room', value: state.inRoom ?? '-'),
                          _DebugLine(
                            label: 'Listeners',
                            value: state.activeListenerCount.toString(),
                          ),
                          _DebugLine(
                            label: 'Reads/Writes/Snaps',
                            value:
                                '${state.firestoreReadCount}/${state.firestoreWriteCount}/${state.firestoreSnapshotCount}',
                          ),
                          if (state.cameraStatus != null && state.cameraStatus!.isNotEmpty)
                            _DebugLine(label: 'Camera status', value: state.cameraStatus!),
                          if (state.callError != null && state.callError!.isNotEmpty)
                            _DebugLine(label: 'Call error', value: state.callError!),
                          if (state.authError != null && state.authError!.isNotEmpty)
                            _DebugLine(label: 'Auth error', value: state.authError!),
                          if (state.roomError != null && state.roomError!.isNotEmpty)
                            _DebugLine(label: 'Room error', value: state.roomError!),
                          if (state.cameraMismatch)
                            const _AlertLine(text: 'Camera mismatch: UI on, Firestore off'),
                          if (state.presenceMismatch)
                            const _AlertLine(text: 'Presence mismatch: offline or wrong room'),
                          if (state.staleParticipantIds.isNotEmpty)
                            _AlertLine(
                              text:
                                  'Stale users: ${state.staleParticipantIds.join(', ')}',
                            ),
                          if (duplicateListeners.isNotEmpty)
                            _AlertLine(
                              text:
                                  'Duplicate listeners: ${duplicateListeners.join(', ')}',
                            ),
                          const SizedBox(height: 10),
                          const Text(
                            'Recent Events',
                            style: TextStyle(
                              color: Color(0xFFD4AF37),
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Flexible(
                            child: ListView.builder(
                              shrinkWrap: true,
                              itemCount: state.recentEvents.length,
                              itemBuilder: (context, index) {
                                final event = state.recentEvents[index];
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 8),
                                  child: Text(
                                    '${event.timestamp.toIso8601String().substring(11, 19)} '
                                    '[${event.level.toUpperCase()}] '
                                    '${event.domain}/${event.action} '
                                    '${event.result ?? ''} '
                                    '${event.message}',
                                    style: const TextStyle(
                                      color: Color(0xFFF7EDE2),
                                      fontSize: 11,
                                      height: 1.3,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _DebugLine extends StatelessWidget {
  const _DebugLine({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: RichText(
        text: TextSpan(
          children: [
            TextSpan(
              text: '$label: ',
              style: const TextStyle(
                color: Color(0xFFD4AF37),
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            TextSpan(
              text: value,
              style: const TextStyle(
                color: Color(0xFFF7EDE2),
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AlertLine extends StatelessWidget {
  const _AlertLine({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 6),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF781E2B).withValues(alpha: 0.28),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFF9B2535).withValues(alpha: 0.7),
        ),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Color(0xFFF7EDE2),
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}