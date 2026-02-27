// lib/features/video_room/screens/video_window_screen.dart
//
// Pop-out video window — opened via WebWindowService.openVideoWindow(uid).
// Shows a single user's live video feed in a small floating browser window.
//
// On web with channelId + agoraUid supplied: independently joins the Agora
// channel as audience-subscriber so it can render the remote video track.
// Falls back to an avatar/name placeholder when Agora params are missing or
// on native platforms.
// ─────────────────────────────────────────────────────────────────────────

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../core/design_system/design_constants.dart';
import '../../../core/platform/web_platform_view_helper.dart';
import '../../../services/agora/agora_service.dart';
import '../../../services/infra/token_service.dart';

class VideoWindowScreen extends StatefulWidget {
  final String uid;
  final String displayName;

  /// Agora channel ID — required for live video rendering on web.
  final String? channelId;

  /// Agora numeric UID of the remote user to display. When provided together
  /// with [channelId], the widget joins Agora and renders the remote video.
  final int? agoraUid;

  const VideoWindowScreen({
    super.key,
    required this.uid,
    this.displayName = '',
    this.channelId,
    this.agoraUid,
  });

  @override
  State<VideoWindowScreen> createState() => _VideoWindowScreenState();
}

class _VideoWindowScreenState extends State<VideoWindowScreen> {
  final AgoraService _agora = AgoraService();
  bool _agoraJoined = false;
  bool _agoraError = false;
  String? _resolvedName;

  // Element IDs for HtmlElementView (web only)
  String get _remoteViewId => 'video-window-remote-${widget.agoraUid ?? widget.uid}';

  @override
  void initState() {
    super.initState();
    if (kIsWeb && widget.channelId != null && widget.agoraUid != null) {
      _initAgora();
    }
  }

  Future<void> _initAgora() async {
    if (!kIsWeb) return;
    final channelId = widget.channelId!;
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      // 1. Fetch token from Cloud Functions
      final tokenData = await TokenService().generateAgoraTokenData(
        channelName: channelId,
        userId: user.uid,
      );

      // 2. Register the platform view factory for HtmlElementView
      registerVideoViewFactory(_remoteViewId, _remoteViewId);

      // 3. Initialise web bridge
      await _agora.init(tokenData.appId);

      // 4. Join as audience (UID=0 → server-assigned)
      final joined = await _agora.joinChannel(
        token: tokenData.token,
        channelId: channelId,
        uid: '0',
      );
      if (!joined) {
        if (mounted) setState(() => _agoraError = true);
        return;
      }

      // 5. Route the remote user's video into our element div
      await _agora.subscribeRemoteVideoTo(_remoteViewId);

      if (mounted) setState(() => _agoraJoined = true);
    } catch (e) {
      debugPrint('[VideoWindow] _initAgora error: $e');
      if (mounted) setState(() => _agoraError = true);
    }
  }

  @override
  Future<void> dispose() async {
    if (_agoraJoined) {
      try {
        await _agora.leaveChannel();
      } catch (_) {}
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        title: FutureBuilder<DocumentSnapshot>(
          future: FirebaseFirestore.instance.collection('users').doc(widget.uid).get(),
          builder: (_, snap) {
            String name = widget.displayName;
            if (snap.hasData && snap.data!.exists) {
              final data = snap.data!.data() as Map<String, dynamic>?;
              name = (data?['displayName'] as String?) ?? widget.displayName;
              _resolvedName = name;
            }
            return Text(
              name.isNotEmpty ? name : 'Video',
              style: const TextStyle(
                color: DesignColors.white,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            );
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.close, color: DesignColors.textGray, size: 20),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          // ── Primary: live Agora video (web only, when channelId + agoraUid provided) ──
          if (kIsWeb && _agoraJoined)
            HtmlElementView(viewType: _remoteViewId)
          else
            _buildAvatarFallback(),
        ],
      ),
    );
  }

  Widget _buildAvatarFallback() {
    return Container(
      color: const Color(0xFF0D0D1A),
      child: Center(
        child: FutureBuilder<DocumentSnapshot>(
          future: FirebaseFirestore.instance.collection('users').doc(widget.uid).get(),
          builder: (_, snap) {
            final data = snap.hasData ? snap.data!.data() as Map<String, dynamic>? : null;
            final avatar = data?['photoUrl'] ?? data?['avatarUrl'] ?? '';
            final name = data?['displayName'] ?? _resolvedName ?? widget.displayName;

            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircleAvatar(
                  radius: 48,
                  backgroundColor: DesignColors.accent.withValues(alpha: 0.2),
                  backgroundImage: avatar.isNotEmpty ? NetworkImage(avatar) : null,
                  child: avatar.isEmpty
                      ? Text(
                          name.isNotEmpty ? name[0].toUpperCase() : '?',
                          style: const TextStyle(
                            color: DesignColors.accent,
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                          ),
                        )
                      : null,
                ),
                const SizedBox(height: 12),
                Text(
                  name,
                  style: const TextStyle(
                    color: DesignColors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _agoraError
                        ? Colors.orange.withValues(alpha: 0.15)
                        : Colors.red.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _agoraError ? Icons.error_outline : Icons.videocam_outlined,
                        color: _agoraError ? Colors.orange : Colors.red,
                        size: 14,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _agoraError ? 'Video unavailable' : 'Live Camera',
                        style: TextStyle(
                          color: _agoraError ? Colors.orange : Colors.red,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
