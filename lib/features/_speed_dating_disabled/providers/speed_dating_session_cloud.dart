library;
import 'dart:js_util' as js_util;
import 'package:mixmingle/helpers/helpers.dart';
/// Speed Dating Session Provider - CLOUD FUNCTION VERSION
/// Gets Agora tokens from backend for security

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'dart:async';

/// Speed dating session model
class SpeedDatingSession {
  final String id;
  final String user1Id;
  final String user2Id;
  final String? user1Name;
  final String? user2Name;
  final String? user1Photo;
  final String? user2Photo;
  final DateTime startedAt;
  final DateTime endsAt;
  final String agoraChannel;
  final String status; // 'active', 'completed', 'cancelled', 'expired'
  final Map<String, String> decisions;

  const SpeedDatingSession({
    required this.id,
    required this.user1Id,
    required this.user2Id,
    this.user1Name,
    this.user2Name,
    this.user1Photo,
    this.user2Photo,
    required this.startedAt,
    required this.endsAt,
    required this.agoraChannel,
    this.status = 'active',
    this.decisions = const {},
  });

  factory SpeedDatingSession.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return SpeedDatingSession(
      id: doc.id,
      user1Id: data['user1Id'] as String? ?? '',
      user2Id: data['user2Id'] as String? ?? '',
      user1Name: data['user1Name'] as String?,
      user2Name: data['user2Name'] as String?,
      user1Photo: data['user1Photo'] as String?,
      user2Photo: data['user2Photo'] as String?,
      startedAt: (data['startedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      endsAt: (data['endsAt'] as Timestamp?)?.toDate() ??
          DateTime.now().add(const Duration(minutes: 5)),
      agoraChannel: data['agoraChannel'] as String? ?? '',
      status: data['status'] as String? ?? 'active',
      decisions: Map<String, String>.from(data['decisions'] as Map? ?? {}),
    );
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
  bool get bothDecided => decisions.length >= 2;

  /// Check if it's a match (both liked)
  bool get isMatch =>
      decisions[user1Id] == 'like' && decisions[user2Id] == 'like';

  /// Get current user's decision
  String? currentUserDecision(String userId) => decisions[userId];

  /// Get other user's info
  Map<String, String?> otherUserInfo(String currentUserId) {
    if (currentUserId == user1Id) {
      return {
        'id': user2Id,
        'name': user2Name,
        'photo': user2Photo,
      };
    } else {
      return {
        'id': user1Id,
        'name': user1Name,
        'photo': user1Photo,
      };
    }
  }
}

/// Session state
class SessionState {
  final SpeedDatingSession? session;
  final int timeRemaining;
  final bool isLoading;
  final String? error;
  final String? agoraToken;
  final int? agoraUid;

  const SessionState({
    this.session,
    this.timeRemaining = 300,
    this.isLoading = false,
    this.error,
    this.agoraToken,
    this.agoraUid,
  });

  SessionState copyWith({
    SpeedDatingSession? session,
    int? timeRemaining,
    bool? isLoading,
    String? error,
    String? agoraToken,
    int? agoraUid,
  }) {
    return SessionState(
      session: session ?? this.session,
      timeRemaining: timeRemaining ?? this.timeRemaining,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      agoraToken: agoraToken ?? this.agoraToken,
      agoraUid: agoraUid ?? this.agoraUid,
    );
  }
}

/// Speed Dating Session Controller - Cloud Function Version
class SpeedDatingSessionController extends Notifier<SessionState> {
  final _firestore = FirebaseFirestore.instance;
  final _functions = FirebaseFunctions.instance;
  final _auth = FirebaseAuth.instance;
  StreamSubscription? _sessionSubscription;
  Timer? _timer;

  @override
  SessionState build() {
    return const SessionState();
  }

  @override
  void dispose() {
    _sessionSubscription?.cancel();
    _timer?.cancel();
    super.dispose();
  }

  /// Load and listen to session
  Future<void> loadSession(String sessionId) async {
    try {
      state = state.copyWith(isLoading: true, error: null);

      _sessionSubscription = _firestore
          .collection('speed_dating_sessions')
          .doc(sessionId)
          .snapshots()
          .listen((doc) {
        if (!doc.exists) {
          state = state.copyWith(
            isLoading: false,
            error: 'Session not found',
          );
          return;
        }

        final session = SpeedDatingSession.fromFirestore(doc);
        state = state.copyWith(
          session: session,
          isLoading: false,
        );

        // Start timer
        _startTimer();
      }, onError: (error) {
        debugPrint('âŒ [Session] Error loading session: $error');
        state = state.copyWith(
          isLoading: false,
          error: error.toString(),
        );
      });

      // Get Agora token from Cloud Function
      await _getAgoraToken(sessionId);
    } catch (e) {
      debugPrint('âŒ [Session] Error loading session: $e');
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  /// Get Agora token from Cloud Function
  Future<void> _getAgoraToken(String sessionId) async {
    try {
      // Generate random UID (0 means Agora assigns one)
      final uid = DateTime.now().millisecondsSinceEpoch % 1000000;

      final callable = _functions.httpsCallable('generateSpeedDatingToken');
      final result = await callable.call({
        'sessionId': sessionId,
        'uid': uid,
      });

      final data = result.data as Map<String, dynamic>;
      state = state.copyWith(
        agoraToken: data['token'] as String,
        agoraUid: uid,
      );

      debugPrint('âœ… [Session] Got Agora token');
    } on FirebaseFunctionsException catch (e) {
      debugPrint('âŒ [Session] Token error: ${e.code} - ${e.message}');
      state = state.copyWith(error: e.message);
    } catch (e) {
      debugPrint('âŒ [Session] Error getting token: $e');
      state = state.copyWith(error: e.toString());
    }
  }

  /// Start countdown timer
  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (state.session != null) {
        final remaining = state.session!.timeRemaining;
        state = state.copyWith(timeRemaining: remaining);

        if (remaining <= 0) {
          timer.cancel();
          debugPrint('â° [Session] Time expired');
        }
      }
    });
  }

  /// Make decision (like/pass) via Cloud Function
  Future<void> makeDecision(String sessionId, String decision) async {
    if (decision != 'like' && decision != 'pass') {
      state = state.copyWith(error: 'Invalid decision');
      return;
    }

    try {
      final callable = _functions.httpsCallable('submitSpeedDatingDecision');
      await callable.call({
        'sessionId': sessionId,
        'decision': decision,
      });

      debugPrint('âœ… [Session] Decision submitted: $decision');
    } on FirebaseFunctionsException catch (e) {
      debugPrint('âŒ [Session] Decision error: ${e.code} - ${e.message}');
      state = state.copyWith(error: e.message);
      rethrow;
    } catch (e) {
      debugPrint('âŒ [Session] Error submitting decision: $e');
      state = state.copyWith(error: e.toString());
      rethrow;
    }
  }

  /// Leave session (cancel early) via Cloud Function
  Future<void> leaveSession(String sessionId) async {
    try {
      final callable = _functions.httpsCallable('leaveSpeedDatingSession');
      await callable.call({
        'sessionId': sessionId,
      });

      _timer?.cancel();
      _sessionSubscription?.cancel();

      debugPrint('âœ… [Session] Left session');
    } on FirebaseFunctionsException catch (e) {
      debugPrint('âŒ [Session] Leave error: ${e.code} - ${e.message}');
      state = state.copyWith(error: e.message);
    } catch (e) {
      debugPrint('âŒ [Session] Error leaving session: $e');
      state = state.copyWith(error: e.toString());
    }
  }
}

/// Provider for speed dating session
final speedDatingSessionProvider =
    NotifierProvider<SpeedDatingSessionController, SessionState>(
  SpeedDatingSessionController.new,
);

/// Provider for active session (auto-loads from user's activeSpeedDatingSession)
final activeSessionProvider = StreamProvider<SpeedDatingSession?>((ref) {
  final userId = FirebaseAuth.instance.currentUser?.uid;
  if (userId == null) {
    return Stream.value(null);
  }

  return FirebaseFirestore.instance
      .collection('users')
      .doc(userId)
      .snapshots()
      .asyncMap((userDoc) async {
    final activeSessionId = userDoc.data()?['activeSpeedDatingSession'] as String?;
    if (activeSessionId == null) return null;

    final sessionDoc = await FirebaseFirestore.instance
        .collection('speed_dating_sessions')
        .doc(activeSessionId)
        .get();

    if (!sessionDoc.exists) return null;
    return SpeedDatingSession.fromFirestore(sessionDoc);
  });
});

/// Provider for time remaining
final timeRemainingProvider = Provider<int>((ref) {
  return ref.watch(speedDatingSessionProvider).timeRemaining;
});
