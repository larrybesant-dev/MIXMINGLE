// lib/core/web/web_window_service.dart
//
// Yahoo Messenger / Paltalk-style pop-out window system.
//
// Usage (web only — no-ops on mobile/desktop):
//   WebWindowService.openBuddyList();
//   WebWindowService.openProfile(uid: 'abc123');
//   WebWindowService.openChat(chatId: 'xyz');
//   WebWindowService.openRoom(roomId: 'room1', roomName: 'Vybe Nation');
//
// State (isOpen, position, size) is persisted in Firestore so windows
// reopen automatically on next login:
//   /users/{uid}/settings/windowState
// ─────────────────────────────────────────────────────────────────────────

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

// Web-only imports via conditional compilation
import 'web_window_service_web.dart'
    if (dart.library.io) 'web_window_service_stub.dart' as impl;

/// Public API — safe to call on all platforms.
class WebWindowService {
  WebWindowService._();

  // ── Buddy List ──────────────────────────────────────────────────────────

  /// Opens (or focuses) the standalone Buddy List window.
  static void openBuddyList() {
    impl.WebWindowBridge.open(
      url: '/buddy-list',
      name: 'buddyListWindow',
      width: 350,
      height: 620,
      left: 80,
      top: 80,
    );
    _persistWindowOpen('buddyList');
  }

  // ── Profile ─────────────────────────────────────────────────────────────

  /// Opens a user profile in a floating window.
  static void openProfile({required String uid}) {
    impl.WebWindowBridge.open(
      url: '/buddy-profile?uid=$uid',
      name: 'profileWindow_$uid',
      width: 460,
      height: 720,
      left: 200,
      top: 100,
    );
  }

  // ── Chat ─────────────────────────────────────────────────────────────────

  /// Opens a direct-message chat in a floating window.
  static void openChat({required String chatId, String? peerName}) {
    final label = peerName != null ? Uri.encodeComponent(peerName) : '';
    impl.WebWindowBridge.open(
      url: '/buddy-chat?chatId=$chatId&name=$label',
      name: 'chatWindow_$chatId',
      width: 400,
      height: 560,
      left: 300,
      top: 120,
    );
  }

  // ── Room / Video ─────────────────────────────────────────────────────────

  /// Opens a live room in a floating window.
  static void openRoom({required String roomId, String roomName = ''}) {
    final label = Uri.encodeComponent(roomName);
    impl.WebWindowBridge.open(
      url: '/room?roomId=$roomId&name=$label',
      name: 'roomWindow_$roomId',
      width: 1100,
      height: 700,
      left: 120,
      top: 60,
    );
  }

  /// Opens a user's video feed in a small floating window.
  /// Pass [channelId] and [agoraUid] so the pop-out window can independently
  /// join Agora and render the live video track.
  static void openVideoWindow({
    required String uid,
    String displayName = '',
    String? channelId,
    int? agoraUid,
  }) {
    final label = Uri.encodeComponent(displayName);
    final channelParam = channelId != null ? '&channelId=$channelId' : '';
    final uidParam = agoraUid != null ? '&agoraUid=$agoraUid' : '';
    impl.WebWindowBridge.open(
      url: '/video-window?uid=$uid&name=$label$channelParam$uidParam',
      name: 'videoWindow_$uid',
      width: 320,
      height: 260,
      left: 600,
      top: 80,
    );
  }

  // ── Firestore persistence ─────────────────────────────────────────────────

  /// Save `isOpen=true` for a named window.
  static void _persistWindowOpen(String windowKey) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null || !kIsWeb) return;
    FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('settings')
        .doc('windowState')
        .set(
          {'${windowKey}_isOpen': true, 'updatedAt': FieldValue.serverTimestamp()},
          SetOptions(merge: true),
        )
        .catchError((_) {});
  }

  /// Save `isOpen=false` for a named window (called when user manually closes).
  static void persistWindowClosed(String windowKey) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null || !kIsWeb) return;
    FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('settings')
        .doc('windowState')
        .set(
          {'${windowKey}_isOpen': false, 'updatedAt': FieldValue.serverTimestamp()},
          SetOptions(merge: true),
        )
        .catchError((_) {});
  }

  /// On login, check Firestore and reopen any windows that were open last time.
  static Future<void> restoreWindowsOnLogin() async {
    if (!kIsWeb) return;
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('settings')
          .doc('windowState')
          .get();
      if (!doc.exists) return;
      final data = doc.data() ?? {};
      if (data['buddyList_isOpen'] == true) openBuddyList();
    } catch (_) {}
  }
}
