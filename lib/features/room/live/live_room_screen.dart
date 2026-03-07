// lib/features/room/live/live_room_screen.dart
//
// Main room screen for the cost-optimized multi-user video room architecture.
//
// This screen:
//   • Mounts the controller via liveRoomControllerProvider
//   • Handles app lifecycle (background/foreground) via WidgetsBindingObserver
//   • Renders the tile grid, audience row, chat input, and controls
//   • Enforces leave-on-pop (calls leaveRoom before Navigator.pop)
// ───────────────────────────────────────────────────────────────────────────

import 'dart:async';
import 'dart:developer' show log;

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/providers/auth_providers.dart';
import '../../../shared/providers/messaging_providers.dart';
import '../../../services/chat/messaging_service.dart';
import '../../../utils/window_manager.dart';
import '../../../utils/window_sync_service.dart';
import '../../../shared/models/message.dart';
import '../../start_conversation.dart';
import 'live_room_schema.dart';
import 'live_room_state.dart';
import 'live_room_controller.dart';
import 'live_tile_grid.dart';
import '../widgets/reaction_bar.dart';

class LiveRoomScreen extends ConsumerStatefulWidget {
  const LiveRoomScreen({
    super.key,
    required this.roomId,
    required this.displayName,
    this.avatarUrl,
  });

  final String  roomId;
  final String  displayName;
  final String? avatarUrl;

  @override
  ConsumerState<LiveRoomScreen> createState() => _LiveRoomScreenState();
}

class _LiveRoomScreenState extends ConsumerState<LiveRoomScreen>
    with WidgetsBindingObserver {
  static const double _desktopBreakpoint = 1100;
  static const double _desktopChatMinWidth = 300;
  static const double _desktopChatMaxWidth = 380;
  static const double _desktopPeopleMinWidth = 220;
  static const double _desktopPeopleMaxWidth = 300;
  static const double _desktopStageMinWidth = 520;

  late final LiveRoomArgs   _args;
  final _chatScroll     = ScrollController();
  StreamSubscription<WindowSyncEvent>? _windowSyncSub;

  @override
  void initState() {
    super.initState();
    _args = LiveRoomArgs(
      roomId:      widget.roomId,
      displayName: widget.displayName,
      avatarUrl:   widget.avatarUrl,
    );
    WidgetsBinding.instance.addObserver(this);
    // Defer enterRoom so the provider is fully mounted
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(liveRoomControllerProvider.notifier).enterRoom(_args);
    });

    _windowSyncSub = WindowSyncService.events.listen((event) {
      if (!mounted) return;
      final payload = event.data;
      if (payload is! Map) return;

      final roomId = payload['roomId'];
      if (roomId != widget.roomId) return;

      if (event.name == 'room.messageSent') {
        final senderId = payload['senderId'];
        if (senderId == null) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('New room activity from another window'),
            duration: Duration(milliseconds: 1200),
          ),
        );
      }
    });
  }

  @override
  void dispose() {
    final roomState = ref.read(liveRoomControllerProvider);
    if (!roomState.isLeft && !roomState.isLeaving) {
      // Best-effort cleanup for abrupt widget disposal paths.
      ref.read(liveRoomControllerProvider.notifier).leaveRoom().catchError((e) {
        log('[LIVE_ROOM_SCREEN] dispose leaveRoom error: $e');
      });
    }

    WidgetsBinding.instance.removeObserver(this);
    _windowSyncSub?.cancel();
    _chatScroll.dispose();
    super.dispose();
  }

  // ── Lifecycle observer ────────────────────────────────────────────────────

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final ctrl = ref.read(liveRoomControllerProvider.notifier);
    switch (state) {
      case AppLifecycleState.paused:
      case AppLifecycleState.hidden:
      case AppLifecycleState.detached:
        ctrl.onSuspended();
        break;
      case AppLifecycleState.resumed:
        ctrl.onResumed();
        break;
      case AppLifecycleState.inactive:
        break;
    }
  }

  // ── Leave handling ────────────────────────────────────────────────────────

  Future<bool> _onWillPop() async {
    final ctrl  = ref.read(liveRoomControllerProvider.notifier);
    final state = ref.read(liveRoomControllerProvider);
    if (!state.isLeft && !state.isLeaving) {
      await ctrl.leaveRoom();
    }
    return true;
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final roomState = ref.watch(liveRoomControllerProvider);

    // Listen for forced-exit events (room deleted / closed)
    ref.listen<LiveRoomState>(liveRoomControllerProvider, (prev, next) {
      if (!mounted) return;
      // When we reach "left" and there's an error message, surface it as a banner
      if (next.isLeft && next.error != null && (prev == null || !prev.isLeft)) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.error!),
            backgroundColor: const Color(0xFFCC4400),
            duration: const Duration(seconds: 4),
          ),
        );
      }

      // When local role changes from broadcaster → audience (demoted by host)
      if (prev != null &&
          prev.isBroadcaster &&
          !next.isBroadcaster &&
          next.isActive) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('You have been removed from the stage.'),
            backgroundColor: Color(0xFF663300),
            duration: Duration(seconds: 3),
          ),
        );
      }
    });

    // Auto-pop once we have fully left
    if (roomState.isLeft) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && Navigator.canPop(context)) Navigator.of(context).pop();
      });
    }

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (!didPop) {
          final nav = Navigator.of(context);
          if (await _onWillPop()) nav.pop();
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFF0A0A18),
        appBar: _buildAppBar(roomState),
        body: _buildBody(roomState),
      ),
    );
  }

  // ── App bar ───────────────────────────────────────────────────────────────

  PreferredSizeWidget _buildAppBar(LiveRoomState s) {
    return AppBar(
      backgroundColor: const Color(0xFF12082A),
      toolbarHeight: 68,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios, color: Colors.white70, size: 18),
        onPressed: () async {
          if (await _onWillPop() && mounted) Navigator.of(context).pop();
        },
      ),
      title: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            s.roomMeta?.name ?? widget.roomId,
            style: const TextStyle(
              color: Color(0xFFFFD700),
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            '${s.viewerCount} in room  •  ${s.onCamCount} on cam',
            style: const TextStyle(color: Colors.white54, fontSize: 11),
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.open_in_new, color: Colors.white70),
          tooltip: 'Pop Out Room',
          onPressed: () {
            WindowSyncService.send('room.popoutRequested', {
              'roomId': widget.roomId,
            });
            WindowManager.openRoom(widget.roomId);
          },
        ),
        if (s.isActive || s.isSuspended)
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Chip(
              backgroundColor: s.isSuspended
                  ? const Color(0xFF444444)
                  : const Color(0xFF1A8A4A),
              label: Text(
                s.isSuspended ? 'PAUSED' : 'LIVE',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
      ],
    );
  }

  // ── Body ──────────────────────────────────────────────────────────────────

  Widget _buildBody(LiveRoomState s) {
    final ctrl = ref.read(liveRoomControllerProvider.notifier);

    if (s.isJoining) return _buildLoadingView(s.statusMessage ?? 'Loading…');
    if (s.hasError)  return _buildErrorView(s.error ?? 'Unknown error');

    return LayoutBuilder(
      builder: (context, constraints) {
      final totalWidth = constraints.maxWidth;
      final isDesktop = totalWidth >= _desktopBreakpoint;
      final chatWidth =
        (totalWidth * 0.28).clamp(_desktopChatMinWidth, _desktopChatMaxWidth).toDouble();
      final peopleWidth =
        (totalWidth * 0.22).clamp(_desktopPeopleMinWidth, _desktopPeopleMaxWidth).toDouble();
      final stageMinWidth =
        (totalWidth - chatWidth - peopleWidth - 32).clamp(_desktopStageMinWidth, totalWidth)
          .toDouble();

        if (!isDesktop) {
          return Column(
            children: [
              // ── Tile grid ─────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.all(8),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(context).size.height * 0.42,
                    minHeight: 180,
                  ),
                  child: LiveTileGrid(args: _args),
                ),
              ),

              // ── Audience row ──────────────────────────────────────────
              if (s.audienceParticipants.isNotEmpty)
                _AudienceRow(participants: s.audienceParticipants),

              // ── Controls ──────────────────────────────────────────────
              _ControlBar(args: _args, state: s),

              // ── Reaction bar ──────────────────────────────────────────
              ReactionBarWidget(onReact: _sendReaction),

              // ── Host: pending cam requests ────────────────────────────
              if (s.isHost && s.pendingRequests.isNotEmpty)
                _PendingRequestsPanel(pendingRequests: s.pendingRequests),

              const Divider(color: Color(0xFF2A1A3E), height: 1),

              // ── Chat ──────────────────────────────────────────────────
              Expanded(
                child: _ChatArea(
                  scrollController: _chatScroll,
                  roomId: widget.roomId,
                ),
              ),

              // ── Chat input ────────────────────────────────────────────
              _ChatInputBar(
                controller: ctrl.chatTextController,
                onSend: (text) => ctrl.sendMessage(text, roomId: widget.roomId),
              ),
            ],
          );
        }

        return Column(
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Left: video stage
                    Flexible(
                      fit: FlexFit.tight,
                      child: ConstrainedBox(
                        constraints: BoxConstraints(minWidth: stageMinWidth),
                        child: Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFF0D0D1A),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFF2A1A3E)),
                        ),
                        padding: const EdgeInsets.all(8),
                        child: LiveTileGrid(args: _args),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),

                    // Middle: chat panel
                    SizedBox(
                      width: chatWidth,
                      child: _DesktopChatPanel(
                        roomId: widget.roomId,
                        scrollController: _chatScroll,
                        chatController: ctrl.chatTextController,
                        onSend: (text) => ctrl.sendMessage(text, roomId: widget.roomId),
                      ),
                    ),
                    const SizedBox(width: 8),

                    // Right: people/status panel
                    SizedBox(
                      width: peopleWidth,
                      child: _PeopleStatusPanel(state: s),
                    ),
                  ],
                ),
              ),
            ),
            ReactionBarWidget(onReact: _sendReaction),
            SizedBox(height: 92, child: _ControlBar(args: _args, state: s)),
          ],
        );
      },
    );
  }

  // ── Reaction helper ─────────────────────────────────────────────────────────

  Future<void> _sendReaction(String emoji) async {
    try {
      final user = ref.read(currentUserProvider).value;
      if (user == null) return;
      await ref.read(messagingServiceProvider).sendRoomMessage(
        senderId:        user.id,
        senderName:      user.displayName ?? user.username,
        senderAvatarUrl: user.avatarUrl,
        roomId:          widget.roomId,
        content:         emoji,
      );
    } catch (e) {
      debugPrint('[ROOM_SCREEN] reaction error: $e');
    }
  }

  Widget _buildLoadingView(String message) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(color: Color(0xFFFF4C4C)),
            const SizedBox(height: 16),
            Text(message, style: const TextStyle(color: Colors.white70)),
          ],
        ),
      );

  Widget _buildErrorView(String error) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, color: Color(0xFFFF4C4C), size: 48),
              const SizedBox(height: 12),
              Text(
                error,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white70),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF4C4C),
                ),
                child: const Text('Go back'),
              ),
            ],
          ),
        ),
      );
}

// ── Audience row ───────────────────────────────────────────────────────────

class _AudienceRow extends StatelessWidget {
  const _AudienceRow({required this.participants});
  final List<RoomParticipant> participants;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 52,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      color: const Color(0xFF0D0D1A),
      child: Row(
        children: [
          const Icon(Icons.people, color: Colors.white38, size: 16),
          const SizedBox(width: 6),
          Text(
            '${participants.length} watching',
            style: const TextStyle(color: Colors.white38, fontSize: 12),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: participants.length.clamp(0, 12),
              itemBuilder: (ctx, i) {
                final p       = participants[i];
                final pending = p.camRequestPending;
                return Padding(
                  padding: const EdgeInsets.only(right: 4),
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      CircleAvatar(
                        radius: 14,
                        backgroundColor: pending
                            ? const Color(0xFF7A5200)
                            : const Color(0xFF3A1A5E),
                        backgroundImage: p.avatarUrl != null
                            ? NetworkImage(p.avatarUrl!)
                            : null,
                        child: p.avatarUrl == null
                            ? Text(
                                p.displayName.isNotEmpty
                                    ? p.displayName[0].toUpperCase()
                                    : '?',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                ),
                              )
                            : null,
                      ),
                      // Raised-hand badge for pending requests
                      if (pending)
                        const Positioned(
                          right: -2,
                          bottom: -2,
                          child: Icon(
                            Icons.front_hand,
                            size: 11,
                            color: Color(0xFFFFD700),
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ── Control bar ────────────────────────────────────────────────────────────

class _ControlBar extends ConsumerWidget {
  const _ControlBar({required this.args, required this.state});
  final LiveRoomArgs  args;
  final LiveRoomState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ctrl = ref.read(liveRoomControllerProvider.notifier);

    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF12082A),
          border: Border(top: BorderSide(color: Color(0xFF2A1A3E))),
        boxShadow: [
          BoxShadow(
            color: Color(0x55000000),
            blurRadius: 8,
            offset: Offset(0, -2),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // Cam toggle for everyone (self-cam control is user-local).
          _ControlButton(
            icon: state.isCamOn ? Icons.videocam : Icons.videocam_off,
            label: state.isCamOn ? 'Cam on' : 'Cam off',
            active: state.isCamOn,
            onTap: () async {
              final err = await ctrl.toggleCam();
              if (err != null && context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(err),
                    backgroundColor: const Color(0xFFFF4C4C),
                  ),
                );
              }
            },
          ),

          // Mic toggle
          _ControlButton(
            icon: state.isMicOn ? Icons.mic : Icons.mic_off,
            label: state.isMicOn ? 'Mic on' : 'Mic off',
            active: state.isMicOn,
            onTap: () async {
              final err = await ctrl.toggleMic();
              if (err != null && context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(err),
                    backgroundColor: const Color(0xFFFF4C4C),
                  ),
                );
              }
            },
          ),

          // Mic count badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFF1E0E3A),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFF5A3A7E)),
            ),
            child: Text(
              '${state.activeMicCount}/${state.maxActiveMics} mics',
              style: const TextStyle(color: Colors.white70, fontSize: 11),
            ),
          ),

          // Leave button
          _ControlButton(
            icon: Icons.call_end,
            label: 'Leave',
            active: false,
            activeColor: const Color(0xFFFF1744),
            onTap: () async {
              await ctrl.leaveRoom();
            },
          ),
        ],
      ),
    );
  }
}

class _ControlButton extends StatelessWidget {
  const _ControlButton({
    required this.icon,
    required this.label,
    required this.active,
    required this.onTap,
    this.activeColor,
  });

  final IconData    icon;
  final String      label;
  final bool        active;
  final VoidCallback onTap;
  final Color?      activeColor;

  @override
  Widget build(BuildContext context) {
    final color = active
        ? (activeColor ?? const Color(0xFF00FF88))
        : (activeColor ?? Colors.white38);

    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: active
                  ? color.withAlpha(30)
                  : const Color(0xFF1E0E3A),
              shape: BoxShape.circle,
              border: Border.all(color: color.withAlpha(120)),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 4),
          Text(label,
              style: TextStyle(color: color, fontSize: 10)),
        ],
      ),
    );
  }
}

// ── Chat area ──────────────────────────────────────────────────────────────

class _ChatArea extends ConsumerStatefulWidget {
  const _ChatArea({required this.scrollController, required this.roomId});
  final ScrollController scrollController;
  final String           roomId;

  @override
  ConsumerState<_ChatArea> createState() => _ChatAreaState();
}

class _ChatAreaState extends ConsumerState<_ChatArea> {
  static const double _nearBottomThreshold = 120;
  int _lastCount = 0;
  int _unseenCount = 0;
  int? _firstUnseenIndex;
  bool _isNearBottom = true;

  @override
  void initState() {
    super.initState();
    widget.scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    widget.scrollController.removeListener(_onScroll);
    super.dispose();
  }

  void _onScroll() {
    if (!widget.scrollController.hasClients) return;
    final pos = widget.scrollController.position;
    final nearBottom = pos.maxScrollExtent - pos.pixels <= _nearBottomThreshold;
    if (nearBottom != _isNearBottom) {
      setState(() {
        _isNearBottom = nearBottom;
        if (nearBottom) {
          _unseenCount = 0;
          _firstUnseenIndex = null;
        }
      });
    }
  }

  Future<void> _scrollToBottom() async {
    if (!widget.scrollController.hasClients) return;
    await widget.scrollController.animateTo(
      widget.scrollController.position.maxScrollExtent,
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final messagesAsync = ref.watch(roomMessagesProvider(widget.roomId));

    return messagesAsync.when(
      loading: () => const Center(
        child: CircularProgressIndicator(color: Color(0xFF5A3A7E), strokeWidth: 2),
      ),
      error: (e, _) => const Center(
        child: Text(
          'Chat unavailable',
          style: TextStyle(color: Colors.white38, fontSize: 12),
        ),
      ),
      data: (messages) {
        if (_firstUnseenIndex != null && _firstUnseenIndex! >= messages.length) {
          _firstUnseenIndex = null;
        }

        final delta = messages.length - _lastCount;
        if (delta > 0) {
          WidgetsBinding.instance.addPostFrameCallback((_) async {
            if (!mounted) return;
            if (_isNearBottom) {
              await _scrollToBottom();
              if (mounted && (_unseenCount != 0 || _firstUnseenIndex != null)) {
                setState(() {
                  _unseenCount = 0;
                  _firstUnseenIndex = null;
                });
              }
            } else {
              setState(() {
                _firstUnseenIndex ??= _lastCount;
                _unseenCount += delta;
              });
            }
          });
        }
        _lastCount = messages.length;

        final showUnreadDivider =
            _unseenCount > 0 &&
            !_isNearBottom &&
            _firstUnseenIndex != null &&
            _firstUnseenIndex! < messages.length;
        final unreadDividerIndex = showUnreadDivider ? _firstUnseenIndex! : -1;

        if (messages.isEmpty) {
          return const Center(
            child: Text(
              'Be the first to say something!',
              style: TextStyle(color: Colors.white24, fontSize: 12),
            ),
          );
        }

        return Stack(
          children: [
            ListView.builder(
              controller: widget.scrollController,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              itemCount: messages.length + (showUnreadDivider ? 1 : 0),
              itemBuilder: (ctx, i) {
                if (showUnreadDivider && i == unreadDividerIndex) {
                  return _UnreadDivider(count: _unseenCount);
                }
                final messageIndex =
                    showUnreadDivider && i > unreadDividerIndex ? i - 1 : i;
                return _ChatBubble(message: messages[messageIndex]);
              },
            ),
            if (_unseenCount > 0)
              Positioned(
                right: 12,
                bottom: 10,
                child: GestureDetector(
                  onTap: () async {
                    await _scrollToBottom();
                    if (mounted) {
                      setState(() {
                        _unseenCount = 0;
                        _firstUnseenIndex = null;
                        _isNearBottom = true;
                      });
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF5A3A7E),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFF8B5FC0)),
                    ),
                    child: Text(
                      '$_unseenCount new message${_unseenCount == 1 ? '' : 's'}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _UnreadDivider extends StatelessWidget {
  const _UnreadDivider({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          const Expanded(child: Divider(color: Color(0xFF5A3A7E), height: 1)),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 8),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: const Color(0xFF2D1A4A),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFF6E4C96)),
            ),
            child: Text(
              '$count new',
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const Expanded(child: Divider(color: Color(0xFF5A3A7E), height: 1)),
        ],
      ),
    );
  }
}

class _ChatBubble extends StatelessWidget {
  const _ChatBubble({required this.message});
  final Message message;

  String _timeLabel(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 12,
            backgroundColor: const Color(0xFF3A1A5E),
            backgroundImage: message.senderAvatarUrl.isNotEmpty
                ? NetworkImage(message.senderAvatarUrl)
                : null,
            child: message.senderAvatarUrl.isEmpty
                ? Text(
                    message.senderName.isNotEmpty
                        ? message.senderName[0].toUpperCase()
                        : '?',
                    style: const TextStyle(color: Colors.white, fontSize: 10),
                  )
                : null,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        message.senderName,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFFFFD700),
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      _timeLabel(message.timestamp),
                      style: const TextStyle(
                        color: Colors.white38,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 1),
                Text(
                  message.content,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DesktopChatPanel extends StatelessWidget {
  const _DesktopChatPanel({
    required this.roomId,
    required this.scrollController,
    required this.chatController,
    required this.onSend,
  });

  final String roomId;
  final ScrollController scrollController;
  final TextEditingController chatController;
  final Future<void> Function(String) onSend;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF12082A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF2A1A3E)),
      ),
      child: Column(
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(12, 10, 12, 8),
            child: Row(
              children: [
                Icon(Icons.forum, color: Color(0xFFFFD700), size: 14),
                SizedBox(width: 6),
                Text(
                  'Room Chat',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const Divider(color: Color(0xFF2A1A3E), height: 1),
          Expanded(
            child: _ChatArea(
              scrollController: scrollController,
              roomId: roomId,
            ),
          ),
          _ChatInputBar(
            controller: chatController,
            onSend: onSend,
          ),
        ],
      ),
    );
  }
}

class _PeopleStatusPanel extends ConsumerWidget {
  const _PeopleStatusPanel({required this.state});
  final LiveRoomState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ctrl = ref.read(liveRoomControllerProvider.notifier);
    final talkingNow = state.participants.where((p) => p.isMicActive).toList();
    final onCam = state.participants.where((p) => p.isOnCam).toList();
    final watching = state.participants.where((p) => !p.isOnCam && !p.isMicActive).toList();
    final me = state.participants
        .where((p) => p.userId == state.localUserId)
        .cast<RoomParticipant?>()
        .firstOrNull;
    final hasPendingRequest = me?.camRequestPending ?? false;
    final canJoinQueue =
        state.isActive && !state.isHost && !state.isBroadcaster && !state.isCamOn;

    final activeSpeaker = state.participants
        .where((p) => p.agoraUid != null && p.agoraUid == state.activeSpeakerUid)
        .cast<RoomParticipant?>()
        .firstOrNull;

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF12082A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF2A1A3E)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(12, 10, 12, 8),
            child: Text(
              'People',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.only(top: 2, bottom: 8),
              children: [
                _PeopleSection(
                  title: 'Talking Now',
                  icon: Icons.mic,
                  participants: talkingNow,
                  highlightedUserId: activeSpeaker?.userId,
                  onTapParticipant: (p) {
                    if (p.userId == state.localUserId) return;
                    startConversation(context, ref, p.userId);
                  },
                ),
                const Divider(color: Color(0xFF2A1A3E), height: 1),
                _MicQueueSection(
                  queueCount: state.pendingRequests.length,
                  isHost: state.isHost,
                  isOnCam: state.isCamOn,
                  isPending: hasPendingRequest,
                  canJoinQueue: canJoinQueue,
                  onToggleQueueRequest: canJoinQueue || hasPendingRequest
                      ? () async {
                          if (hasPendingRequest) {
                            await ctrl.cancelCamRequest();
                            return;
                          }
                          final err = await ctrl.requestCam();
                          if (!context.mounted || err == null) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(err)),
                          );
                        }
                      : null,
                ),
                const Divider(color: Color(0xFF2A1A3E), height: 1),
                _PeopleSection(
                  title: 'On Cam',
                  icon: Icons.videocam,
                  participants: onCam,
                  onTapParticipant: (p) {
                    if (p.userId == state.localUserId) return;
                    startConversation(context, ref, p.userId);
                  },
                ),
                const Divider(color: Color(0xFF2A1A3E), height: 1),
                _PeopleSection(
                  title: 'Chatting',
                  icon: Icons.chat_bubble,
                  participants: watching,
                  onTapParticipant: (p) {
                    if (p.userId == state.localUserId) return;
                    startConversation(context, ref, p.userId);
                  },
                ),
              ],
            ),
          ),
          if (state.isHost && state.pendingRequests.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 6, 8, 8),
              child: _PendingRequestsPanel(pendingRequests: state.pendingRequests),
            ),
        ],
      ),
    );
  }
}

class _PeopleSection extends StatelessWidget {
  const _PeopleSection({
    required this.title,
    required this.icon,
    required this.participants,
    this.highlightedUserId,
    this.onTapParticipant,
  });

  final String title;
  final IconData icon;
  final List<RoomParticipant> participants;
  final String? highlightedUserId;
  final void Function(RoomParticipant)? onTapParticipant;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 4, 10, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: const Color(0xFFFFD700), size: 12),
              const SizedBox(width: 6),
              Text(
                '$title (${participants.length})',
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          if (participants.isEmpty)
            const Text(
              'No one yet',
              style: TextStyle(color: Colors.white30, fontSize: 11),
            )
          else
            ...participants.take(12).map(
              (p) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: GestureDetector(
                  onTap: onTapParticipant != null ? () => onTapParticipant!(p) : null,
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 9,
                        backgroundColor: const Color(0xFF3A1A5E),
                        backgroundImage: p.avatarUrl != null ? NetworkImage(p.avatarUrl!) : null,
                        child: p.avatarUrl == null
                            ? Text(
                                p.displayName.isNotEmpty ? p.displayName[0].toUpperCase() : '?',
                                style: const TextStyle(color: Colors.white, fontSize: 9),
                              )
                            : null,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: p.userId == highlightedUserId
                                ? const Color(0x3300FF88)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            p.displayName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: p.userId == highlightedUserId
                                  ? const Color(0xFF9DFFCB)
                                  : Colors.white60,
                              fontSize: 11,
                              fontWeight: p.userId == highlightedUserId
                                  ? FontWeight.w700
                                  : FontWeight.w400,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _MicQueueSection extends StatefulWidget {
  const _MicQueueSection({
    required this.queueCount,
    required this.isHost,
    required this.isOnCam,
    required this.isPending,
    required this.canJoinQueue,
    this.onToggleQueueRequest,
  });

  final int queueCount;
  final bool isHost;
  final bool isOnCam;
  final bool isPending;
  final bool canJoinQueue;
  final Future<void> Function()? onToggleQueueRequest;

  @override
  State<_MicQueueSection> createState() => _MicQueueSectionState();
}

class _MicQueueSectionState extends State<_MicQueueSection> {
  bool _isBusy = false;

  @override
  Widget build(BuildContext context) {
    final isInteractive = widget.onToggleQueueRequest != null && !_isBusy;
    final label = _isBusy
        ? 'Working...'
        : widget.isHost
        ? 'Host'
        : widget.isOnCam
            ? 'On Cam'
            : widget.isPending
                ? 'Cancel'
                : 'Join Queue';

    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
      child: Row(
        children: [
          const Icon(Icons.queue_music, color: Color(0xFFFFD700), size: 12),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              'Mic Queue (${widget.queueCount})',
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          GestureDetector(
            onTap: isInteractive
                ? () async {
                    setState(() => _isBusy = true);
                    try {
                      await widget.onToggleQueueRequest?.call();
                    } finally {
                      if (mounted) setState(() => _isBusy = false);
                    }
                  }
                : null,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: widget.isPending
                    ? const Color(0xFF3B1E54)
                    : isInteractive
                        ? const Color(0xFF2A1A3E)
                        : const Color(0xFF20162E),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: widget.isPending
                      ? const Color(0xFFFFD700)
                      : isInteractive
                          ? const Color(0xFF5A3A7E)
                          : const Color(0xFF3A2A5A),
                ),
              ),
              child: Text(
                label,
                style: TextStyle(
                  color: widget.isPending
                      ? const Color(0xFFFFD700)
                      : widget.canJoinQueue
                          ? Colors.white70
                          : Colors.white38,
                  fontSize: 10,
                  fontWeight: widget.isPending ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Pending cam requests panel (host only) ────────────────────────────────

class _PendingRequestsPanel extends ConsumerWidget {
  const _PendingRequestsPanel({required this.pendingRequests});
  final List<RoomParticipant> pendingRequests;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ctrl = ref.read(liveRoomControllerProvider.notifier);

    return Container(
      margin: const EdgeInsets.fromLTRB(8, 4, 8, 4),
      decoration: BoxDecoration(
        color: const Color(0xFF1A0E30),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFFD700).withAlpha(80)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
            child: Row(
              children: [
                const Icon(Icons.live_tv, color: Color(0xFFFFD700), size: 14),
                const SizedBox(width: 6),
                Text(
                  '${pendingRequests.length} cam request${pendingRequests.length > 1 ? 's' : ''}',
                  style: const TextStyle(
                    color: Color(0xFFFFD700),
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const Divider(color: Color(0xFF3A2A5E), height: 1),
          ...pendingRequests.map(
            (p) => _PendingRequestRow(
              participant: p,
              onApprove: () async {
                final err = await ctrl.approveRequest(p.userId);
                if (err != null && context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(err),
                      backgroundColor: const Color(0xFFFF4C4C),
                    ),
                  );
                }
              },
              onDeny: () => ctrl.denyRequest(p.userId),
            ),
          ),
        ],
      ),
    );
  }
}

class _PendingRequestRow extends StatelessWidget {
  const _PendingRequestRow({
    required this.participant,
    required this.onApprove,
    required this.onDeny,
  });
  final RoomParticipant participant;
  final VoidCallback    onApprove;
  final VoidCallback    onDeny;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      child: Row(
        children: [
          CircleAvatar(
            radius: 14,
            backgroundColor: const Color(0xFF3A1A5E),
            backgroundImage: participant.avatarUrl != null
                ? NetworkImage(participant.avatarUrl!)
                : null,
            child: participant.avatarUrl == null
                ? Text(
                    participant.displayName.isNotEmpty
                        ? participant.displayName[0].toUpperCase()
                        : '?',
                    style: const TextStyle(color: Colors.white, fontSize: 11),
                  )
                : null,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              participant.displayName,
              style: const TextStyle(color: Colors.white, fontSize: 13),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          GestureDetector(
            onTap: onApprove,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: const Color(0xFF1A8A4A),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Text(
                'Let in',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 6),
          GestureDetector(
            onTap: onDeny,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: const Color(0xFF3A1A5E),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Text(
                'Deny',
                style: TextStyle(color: Colors.white54, fontSize: 11),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Chat input bar ─────────────────────────────────────────────────────────

class _ChatInputBar extends StatefulWidget {
  const _ChatInputBar({required this.controller, required this.onSend});
  final TextEditingController controller;
  final Future<void> Function(String) onSend;

  @override
  State<_ChatInputBar> createState() => _ChatInputBarState();
}

class _ChatInputBarState extends State<_ChatInputBar> {
  bool _isSending = false;

  Future<void> _handleSend() async {
    if (_isSending) return;
    final text = widget.controller.text.trim();
    if (text.isEmpty) return;

    setState(() => _isSending = true);
    try {
      await widget.onSend(text);
      if (mounted) {
        widget.controller.clear();
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Message failed to send: $e'),
          backgroundColor: const Color(0xFFFF4C4C),
        ),
      );
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF12082A),
      padding: const EdgeInsets.fromLTRB(12, 6, 8, 12),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: widget.controller,
              style: const TextStyle(color: Colors.white, fontSize: 14),
              textInputAction: TextInputAction.send,
              decoration: InputDecoration(
                hintText: 'Say something…',
                hintStyle: const TextStyle(color: Colors.white38),
                filled: true,
                fillColor: const Color(0xFF1A0A2A),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide.none,
                ),
              ),
              onSubmitted: (_) => _handleSend(),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            width: 38,
            height: 38,
            decoration: const BoxDecoration(
              color: Color(0xFFFF4C4C),
              shape: BoxShape.circle,
            ),
            child: Material(
              color: Colors.transparent,
              child: IconButton(
                padding: EdgeInsets.zero,
                splashRadius: 20,
                onPressed: _isSending ? null : _handleSend,
                icon: _isSending
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.send, color: Colors.white, size: 18),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
