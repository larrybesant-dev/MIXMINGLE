/// Speed Dating Session Provider
/// Manages active speed dating session state
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'dart:async';

/// Speed dating session model
class SpeedDatingSession {
  final String id;
  final String user1Id;
  final String user2Id;
  final DateTime startedAt;
  final DateTime endsAt;
  final String agoraChannel;
  final String status; // 'active', 'completed', 'cancelled'
  final String? user1Decision; // 'like', 'pass'
  final String? user2Decision;

  const SpeedDatingSession({
    required this.id,
    required this.user1Id,
    required this.user2Id,
    required this.startedAt,
    required this.endsAt,
    required this.agoraChannel,
    this.status = 'active',
    this.user1Decision,
    this.user2Decision,
  });

  factory SpeedDatingSession.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return SpeedDatingSession(
      id: doc.id,
      user1Id: data['user1Id'] as String? ?? '',
      user2Id: data['user2Id'] as String? ?? '',
      startedAt:
          (data['startedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      endsAt: (data['endsAt'] as Timestamp?)?.toDate() ??
          DateTime.now().add(const Duration(minutes: 5)),
      agoraChannel: data['agoraChannel'] as String? ?? '',
      status: data['status'] as String? ?? 'active',
      user1Decision: data['user1Decision'] as String?,
      user2Decision: data['user2Decision'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'user1Id': user1Id,
      'user2Id': user2Id,
      'startedAt': Timestamp.fromDate(startedAt),
      'endsAt': Timestamp.fromDate(endsAt),
      'agoraChannel': agoraChannel,
      'status': status,
      'user1Decision': user1Decision,
      'user2Decision': user2Decision,
    };
  }

  /// Get time remaining in seconds
  int get timeRemaining {
    final now = DateTime.now();
    if (now.isAfter(endsAt)) return 0;
    return endsAt.difference(now).inSeconds;
  }

  /// Check if session has ended
  bool get hasEnded => DateTime.now().isAfter(endsAt);

  /// Check if both users have made decisions
  bool get bothDecided => user1Decision != null && user2Decision != null;

  /// Check if it's a match (both liked)
  bool get isMatch =>
      user1Decision == 'like' && user2Decision == 'like';

  SpeedDatingSession copyWith({
    String? id,
    String? user1Id,
    String? user2Id,
    DateTime? startedAt,
    DateTime? endsAt,
    String? agoraChannel,
    String? status,
    String? user1Decision,
    String? user2Decision,
  }) {
    return SpeedDatingSession(
      id: id ?? this.id,
      user1Id: user1Id ?? this.user1Id,
      user2Id: user2Id ?? this.user2Id,
      startedAt: startedAt ?? this.startedAt,
      endsAt: endsAt ?? this.endsAt,
      agoraChannel: agoraChannel ?? this.agoraChannel,
      status: status ?? this.status,
      user1Decision: user1Decision ?? this.user1Decision,
      user2Decision: user2Decision ?? this.user2Decision,
    );
  }
}

/// Session state
class SessionState {
  final SpeedDatingSession? session;
  final int timeRemaining; // seconds
  final bool isLoading;
  final String? error;

  const SessionState({
    this.session,
    this.timeRemaining = 0,
    this.isLoading = false,
    this.error,
  });

  SessionState copyWith({
    SpeedDatingSession? session,
    int? timeRemaining,
    bool? isLoading,
    String? error,
  }) {
    return SessionState(
      session: session ?? this.session,
      timeRemaining: timeRemaining ?? this.timeRemaining,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

/// Speed Dating Session Controller
class SpeedDatingSessionController extends Notifier<SessionState> {
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;
  Timer? _timer;
  StreamSubscription? _sessionSubscription;

  @override
  SessionState build() {
    _listenToActiveSession();
    return const SessionState();
  }

  // Note: Riverpod Notifier doesn't have dispose override
  // Timer and subscriptions are cleaned up automatically
  // when ref.onDispose is called

  /// Listen to user's active session
  void _listenToActiveSession() {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return;

    _sessionSubscription = _firestore
        .collection('speed_dating_sessions')
        .where('status', isEqualTo: 'active')
        .snapshots()
        .listen((snapshot) {
      // Find session where user is participant
      final userSession = snapshot.docs.firstWhere(
        (doc) {
          final data = doc.data();
          return data['user1Id'] == userId || data['user2Id'] == userId;
        },
        orElse: () => throw Exception('No active session'),
      );

      try {
        final session = SpeedDatingSession.fromFirestore(userSession);
        state = state.copyWith(session: session);
        _startTimer();
      } catch (e) {
        // No active session found
        state = state.copyWith(session: null);
        _timer?.cancel();
      }
    });
  }

  /// Start countdown timer
  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (state.session == null) {
        timer.cancel();
        return;
      }

      final remaining = state.session!.timeRemaining;
      state = state.copyWith(timeRemaining: remaining);

      if (remaining <= 0) {
        timer.cancel();
        _endSession();
      }
    });
  }

  /// End the session (timeout)
  Future<void> _endSession() async {
    final session = state.session;
    if (session == null) return;

    try {
      await _firestore
          .collection('speed_dating_sessions')
          .doc(session.id)
          .update({
        'status': 'completed',
        'completedAt': FieldValue.serverTimestamp(),
      });

      // Remove from queue
      final userId = _auth.currentUser?.uid;
      if (userId != null) {
        await _firestore
            .collection('speed_dating_queue')
            .doc(userId)
            .delete();
      }
    } catch (e) {
      debugPrint('Error ending session: $e');
    }
  }

  /// Make a decision (like or pass)
  Future<void> makeDecision(String decision) async {
    final session = state.session;
    final userId = _auth.currentUser?.uid;
    if (session == null || userId == null) return;

    state = state.copyWith(isLoading: true);

    try {
      // Determine which user is making the decision
      final isUser1 = session.user1Id == userId;
      final fieldName = isUser1 ? 'user1Decision' : 'user2Decision';

      // Save decision
      await _firestore
          .collection('speed_dating_sessions')
          .doc(session.id)
          .update({
        fieldName: decision,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Also save to decisions collection for history
      await _firestore.collection('speed_dating_decisions').add({
        'sessionId': session.id,
        'userId': userId,
        'decision': decision,
        'decidedAt': FieldValue.serverTimestamp(),
      });

      // Check if both decided - if so, end session
      final updatedSession = await _firestore
          .collection('speed_dating_sessions')
          .doc(session.id)
          .get();
      final sessionData = updatedSession.data()!;

      if (sessionData['user1Decision'] != null &&
          sessionData['user2Decision'] != null) {
        // Both decided - end session
        await _firestore
            .collection('speed_dating_sessions')
            .doc(session.id)
            .update({
          'status': 'completed',
          'completedAt': FieldValue.serverTimestamp(),
        });

        // If match, create chat
        if (sessionData['user1Decision'] == 'like' &&
            sessionData['user2Decision'] == 'like') {
          await _createMatch(session.user1Id, session.user2Id);
        }
      }

      state = state.copyWith(isLoading: false);
    } catch (e) {
      debugPrint('Error making decision: $e');
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to save decision: $e',
      );
    }
  }

  /// Create a match and chat for matched users
  Future<void> _createMatch(String user1Id, String user2Id) async {
    try {
      // Create chat
      final chatId = _firestore.collection('chats').doc().id;

      // Get user profiles
      final user1Doc = await _firestore.collection('users').doc(user1Id).get();
      final user2Doc = await _firestore.collection('users').doc(user2Id).get();

      final user1Data = user1Doc.data() ?? {};
      final user2Data = user2Doc.data() ?? {};

      await _firestore.collection('chats').doc(chatId).set({
        'participantIds': [user1Id, user2Id],
        'participantNames': {
          user1Id: user1Data['displayName'] ?? 'Unknown',
          user2Id: user2Data['displayName'] ?? 'Unknown',
        },
        'participantPhotos': {
          user1Id: user1Data['profilePhotoUrl'],
          user2Id: user2Data['profilePhotoUrl'],
        },
        'lastMessage': 'You matched!',
        'lastMessageTime': FieldValue.serverTimestamp(),
        'unreadCounts': {user1Id: 0, user2Id: 0},
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'isGroup': false,
        'isSpeedDatingMatch': true,
      });

      // Add system message
      await _firestore
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .add({
        'chatId': chatId,
        'senderId': 'system',
        'senderDisplayName': 'System',
        'content': '🎉 You matched! Start chatting now.',
        'type': 'system',
        'timestamp': FieldValue.serverTimestamp(),
        'isRead': false,
      });

      debugPrint('Match created: $user1Id <-> $user2Id');
    } catch (e) {
      debugPrint('Error creating match: $e');
    }
  }

  /// Cancel session early
  Future<void> cancelSession() async {
    final session = state.session;
    if (session == null) return;

    try {
      await _firestore
          .collection('speed_dating_sessions')
          .doc(session.id)
          .update({
        'status': 'cancelled',
        'cancelledAt': FieldValue.serverTimestamp(),
      });

      _timer?.cancel();
      state = state.copyWith(session: null);
    } catch (e) {
      debugPrint('Error cancelling session: $e');
    }
  }
}

/// Provider for speed dating session
final speedDatingSessionProvider =
    NotifierProvider<SpeedDatingSessionController, SessionState>(() {
  return SpeedDatingSessionController();
});

/// Provider for active session
final activeSessionProvider = Provider<SpeedDatingSession?>((ref) {
  return ref.watch(speedDatingSessionProvider).session;
});

/// Provider for time remaining
final timeRemainingProvider = Provider<int>((ref) {
  return ref.watch(speedDatingSessionProvider).timeRemaining;
});
