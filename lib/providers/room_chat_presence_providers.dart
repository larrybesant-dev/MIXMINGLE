import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart' show debugPrint, kIsWeb, defaultTargetPlatform, TargetPlatform;
import 'dart:async';

import '../shared/models/room_message.dart';
import '../shared/models/room_member.dart';
import 'auth_providers.dart';

// ============================================================================
// ROOM MESSAGES PROVIDER - Paginated Chat with Backward Loading
// ============================================================================

/// Model to hold paginated message state
class RoomMessagesState {
  final List<RoomMessage> messages;
  final bool hasMore;
  final DocumentSnapshot? lastDoc;
  final bool isLoading;
  final String? error;

  RoomMessagesState({
    this.messages = const [],
    this.hasMore = true,
    this.lastDoc,
    this.isLoading = false,
    this.error,
  });

  RoomMessagesState copyWith({
    List<RoomMessage>? messages,
    bool? hasMore,
    DocumentSnapshot? lastDoc,
    bool? isLoading,
    String? error,
  }) {
    return RoomMessagesState(
      messages: messages ?? this.messages,
      hasMore: hasMore ?? this.hasMore,
      lastDoc: lastDoc ?? this.lastDoc,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

/// Paginated messages provider - streams newest messages + supports pagination
final roomMessagesProvider = NotifierProvider.autoDispose.family<
    RoomMessagesNotifier,
    RoomMessagesState,
    String>((roomId) {
  return RoomMessagesNotifier()..roomId = roomId;
});

class RoomMessagesNotifier extends Notifier<RoomMessagesState> {
  late String roomId;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  StreamSubscription? _subscription;

  RoomMessagesNotifier();

  @override
  RoomMessagesState build() {
    // This is called when the provider is first created
    state = RoomMessagesState();
    _initializeMessages();

    // Cleanup on dispose
    ref.onDispose(() {
      _subscription?.cancel();
      debugPrint('[ROOM_CHAT] Messages notifier disposed');
    });

    return state;
  }

  void _initializeMessages() {
    debugPrint('[ROOM_CHAT] Initializing messages for room: $roomId');

    // Stream latest messages (ordered by createdAt descending, limit 25)
    _subscription = _firestore
        .collection('rooms')
        .doc(roomId)
        .collection('messages')
        .orderBy('createdAt', descending: true)
        .limit(25)
        .snapshots()
        .listen(
          (snapshot) {
            debugPrint('[ROOM_CHAT] Received ${snapshot.docs.length} messages');
            final messages = snapshot.docs
                .map((doc) => RoomMessage.fromFirestore(doc))
                .toList()
                .reversed
                .toList(); // Reverse to show oldest first (ascending)

            state = state.copyWith(
              messages: messages,
              hasMore: snapshot.docs.length >= 25,
              lastDoc: snapshot.docs.isNotEmpty ? snapshot.docs.first : null,
              isLoading: false,
              error: null,
            );
          },
          onError: (error) {
            debugPrint('[ROOM_CHAT] Error loading messages: $error');
            state = state.copyWith(
              isLoading: false,
              error: error.toString(),
            );
          },
        );
  }

  /// Load previous messages (pagination backward)
  Future<void> loadPreviousMessages() async {
    if (!state.hasMore || state.isLoading || state.lastDoc == null) {
      return;
    }

    state = state.copyWith(isLoading: true);

    try {
      debugPrint('[ROOM_CHAT] Loading previous messages before: ${state.lastDoc?.id}');

      final snapshot = await _firestore
          .collection('rooms')
          .doc(roomId)
          .collection('messages')
          .orderBy('createdAt', descending: true)
          .startAfter([state.lastDoc!['createdAt']])
          .limit(25)
          .get();

      if (snapshot.docs.isEmpty) {
        state = state.copyWith(
          isLoading: false,
          hasMore: false,
        );
        return;
      }

      final previousMessages = snapshot.docs
          .map((doc) => RoomMessage.fromFirestore(doc))
          .toList()
          .reversed
          .toList();

      state = state.copyWith(
        messages: [...previousMessages, ...state.messages],
        hasMore: snapshot.docs.length >= 25,
        lastDoc: snapshot.docs.isNotEmpty ? snapshot.docs.first : state.lastDoc,
        isLoading: false,
        error: null,
      );

      debugPrint('[ROOM_CHAT] Loaded ${previousMessages.length} previous messages');
    } catch (error) {
      debugPrint('[ROOM_CHAT] Error loading previous messages: $error');
      state = state.copyWith(
        isLoading: false,
        error: error.toString(),
      );
    }
  }

  /// Send a new message
  Future<void> sendMessage(String text, String senderName, String senderId) async {
    if (text.trim().isEmpty) return;

    try {
      debugPrint('[ROOM_CHAT] Sending message to room: $roomId');

      await _firestore
          .collection('rooms')
          .doc(roomId)
          .collection('messages')
          .add({
        'text': text.trim(),
        'senderId': senderId,
        'senderName': senderName,
        'createdAt': FieldValue.serverTimestamp(),
        'type': 'text',
        'deleted': false,
      });

      debugPrint('[ROOM_CHAT] Message sent successfully');
    } catch (error) {
      debugPrint('[ROOM_CHAT] Error sending message: $error');
      state = state.copyWith(error: error.toString());
    }
  }
}

// ============================================================================
// ROOM MEMBERS PROVIDER - Live Presence
// ============================================================================

/// Stream all members in a room (presence status)
final roomMembersProvider = StreamProvider.family<List<RoomMember>, String>((ref, roomId) {
  debugPrint('[PRESENCE] Listening to members in room: $roomId');

  return FirebaseFirestore.instance
      .collection('rooms')
      .doc(roomId)
      .collection('members')
      .snapshots()
      .map((snapshot) {
    final members = snapshot.docs.map((doc) => RoomMember.fromFirestore(doc)).toList();
    debugPrint('[PRESENCE] Members count: ${members.length}');
    return members;
  }).handleError((error) {
    debugPrint('[PRESENCE] Error loading members: $error');
    return <RoomMember>[];
  });
});

/// Get specific member presence status
final roomMemberProvider =
    StreamProvider.family<RoomMember?, (String, String)>((ref, params) {
  final (roomId, userId) = params;
  debugPrint('[PRESENCE] Listening to member: $userId in room: $roomId');

  return FirebaseFirestore.instance
      .collection('rooms')
      .doc(roomId)
      .collection('members')
      .doc(userId)
      .snapshots()
      .map((snapshot) {
    if (!snapshot.exists) {
      debugPrint('[PRESENCE] Member not found: $userId');
      return null;
    }
    return RoomMember.fromFirestore(snapshot);
  }).handleError((error) {
    debugPrint('[PRESENCE] Error loading member: $error');
    return null;
  });
});

// ============================================================================
// LOCAL USER PRESENCE PROVIDER - Write-Only Notifier
// ============================================================================

/// Model to track local user's presence state
class LocalPresenceState {
  final bool online;
  final bool typing;
  final DateTime? lastSeen;
  final bool isUpdating;
  final String? error;

  LocalPresenceState({
    this.online = false,
    this.typing = false,
    this.lastSeen,
    this.isUpdating = false,
    this.error,
  });

  LocalPresenceState copyWith({
    bool? online,
    bool? typing,
    DateTime? lastSeen,
    bool? isUpdating,
    String? error,
  }) {
    return LocalPresenceState(
      online: online ?? this.online,
      typing: typing ?? this.typing,
      lastSeen: lastSeen ?? this.lastSeen,
      isUpdating: isUpdating ?? this.isUpdating,
      error: error ?? this.error,
    );
  }
}

/// Local user presence notifier - manages current user's online/typing status
final localUserPresenceProvider = NotifierProvider.family<
    LocalPresenceNotifier,
    LocalPresenceState,
    String>((roomId) {
  return LocalPresenceNotifier()..roomId = roomId;
});

class LocalPresenceNotifier extends Notifier<LocalPresenceState> {
  late String roomId;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  Timer? _typingResetTimer;

  @override
  LocalPresenceState build() {
    state = LocalPresenceState();

    // Cleanup on dispose
    ref.onDispose(() {
      _typingResetTimer?.cancel();
      debugPrint('[PRESENCE] Presence notifier disposed');
    });

    return state;
  }

  String? get _userId => ref.watch(authStateProvider).maybeWhen(
        data: (user) => user?.uid,
        orElse: () => null,
      );

  /// Mark user as online
  Future<void> setOnline() async {
    if (_userId == null) return;

    state = state.copyWith(isUpdating: true);

    try {
      debugPrint('[PRESENCE] Setting user online in room: $roomId');

      await _firestore
          .collection('rooms')
          .doc(roomId)
          .collection('members')
          .doc(_userId!)
          .set({
        'userId': _userId!,
        'online': true,
        'typing': false,
        'lastSeen': FieldValue.serverTimestamp(),
        'platform': _getPlatform(),
        'role': 'member',
        'joinedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      state = state.copyWith(
        online: true,
        isUpdating: false,
        error: null,
      );

      debugPrint('[PRESENCE] User marked online');
    } catch (error) {
      debugPrint('[PRESENCE] Error setting online: $error');
      state = state.copyWith(
        isUpdating: false,
        error: error.toString(),
      );
    }
  }

  /// Mark user as offline
  Future<void> setOffline() async {
    if (_userId == null) return;

    state = state.copyWith(isUpdating: true);

    try {
      debugPrint('[PRESENCE] Setting user offline in room: $roomId');

      await _firestore
          .collection('rooms')
          .doc(roomId)
          .collection('members')
          .doc(_userId!)
          .update({
        'online': false,
        'typing': false,
        'lastSeen': FieldValue.serverTimestamp(),
      });

      state = state.copyWith(
        online: false,
        typing: false,
        isUpdating: false,
        error: null,
      );

      debugPrint('[PRESENCE] User marked offline');
    } catch (error) {
      debugPrint('[PRESENCE] Error setting offline: $error');
      state = state.copyWith(
        isUpdating: false,
        error: error.toString(),
      );
    }
  }

  /// Mark user as typing (auto-resets after 5 seconds)
  Future<void> setTyping(bool typing) async {
    if (_userId == null) return;

    // Cancel pending reset timer
    _typingResetTimer?.cancel();

    try {
      debugPrint('[PRESENCE] Setting typing: $typing for user: $_userId');

      await _firestore
          .collection('rooms')
          .doc(roomId)
          .collection('members')
          .doc(_userId!)
          .update({
        'typing': typing,
        'lastSeen': FieldValue.serverTimestamp(),
      });

      state = state.copyWith(
        typing: typing,
        error: null,
      );

      // Auto-reset typing after 5 seconds
      if (typing) {
        _typingResetTimer = Timer(const Duration(seconds: 5), () async {
          debugPrint('[PRESENCE] Auto-resetting typing status');
          await setTyping(false);
        });
      }
    } catch (error) {
      debugPrint('[PRESENCE] Error setting typing: $error');
      state = state.copyWith(error: error.toString());
    }
  }

  /// Update lastSeen timestamp (call on message send or activity)
  Future<void> updateLastSeen() async {
    if (_userId == null) return;

    try {
      await _firestore
          .collection('rooms')
          .doc(roomId)
          .collection('members')
          .doc(_userId!)
          .update({
        'lastSeen': FieldValue.serverTimestamp(),
      });
    } catch (error) {
      debugPrint('[PRESENCE] Error updating lastSeen: $error');
    }
  }

  String _getPlatform() {
    if (kIsWeb) return 'web';
    if (defaultTargetPlatform == TargetPlatform.android) return 'android';
    if (defaultTargetPlatform == TargetPlatform.iOS) return 'ios';
    return 'unknown';
  }
}
