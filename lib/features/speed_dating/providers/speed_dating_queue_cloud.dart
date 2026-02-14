/// Speed Dating Queue Provider - CLOUD FUNCTION VERSION
/// Uses backend matching for production-ready system
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import '../../../shared/models/speed_dating_preferences.dart';

/// Speed dating queue entry
class QueueEntry {
  final String userId;
  final String displayName;
  final String? photoUrl;
  final int age;
  final String gender;
  final SpeedDatingPreferences preferences;
  final DateTime joinedAt;
  final String status; // 'waiting', 'matched', 'in-session'

  const QueueEntry({
    required this.userId,
    required this.displayName,
    this.photoUrl,
    required this.age,
    required this.gender,
    required this.preferences,
    required this.joinedAt,
    this.status = 'waiting',
  });

  factory QueueEntry.fromMap(Map<String, dynamic> map, String id) {
    return QueueEntry(
      userId: id,
      displayName: map['displayName'] as String? ?? 'Unknown',
      photoUrl: map['photoUrl'] as String?,
      age: map['age'] as int? ?? 18,
      gender: map['gender'] as String? ?? 'Unknown',
      preferences: SpeedDatingPreferences.fromMap(
        map['preferences'] as Map<String, dynamic>? ?? {},
      ),
      joinedAt: (map['joinedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      status: map['status'] as String? ?? 'waiting',
    );
  }
}

/// Speed dating queue state
class QueueState {
  final List<QueueEntry> queue;
  final bool isInQueue;
  final String? currentMatchId;
  final bool isLoading;
  final String? error;

  const QueueState({
    this.queue = const [],
    this.isInQueue = false,
    this.currentMatchId,
    this.isLoading = false,
    this.error,
  });

  QueueState copyWith({
    List<QueueEntry>? queue,
    bool? isInQueue,
    String? currentMatchId,
    bool? isLoading,
    String? error,
  }) {
    return QueueState(
      queue: queue ?? this.queue,
      isInQueue: isInQueue ?? this.isInQueue,
      currentMatchId: currentMatchId ?? this.currentMatchId,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

/// Speed Dating Queue Controller - Cloud Function Version
class SpeedDatingQueueController extends Notifier<QueueState> {
  final _firestore = FirebaseFirestore.instance;
  final _functions = FirebaseFunctions.instance;
  final _auth = FirebaseAuth.instance;
  StreamSubscription? _queueSubscription;
  StreamSubscription? _userSubscription;

  @override
  QueueState build() {
    _listenForActiveSession();
    _listenToQueueCount();
    return const QueueState();
  }

  @override
  void dispose() {
    _queueSubscription?.cancel();
    _userSubscription?.cancel();
    super.dispose();
  }

  /// Listen for active session (assigned by Cloud Function matcher)
  void _listenForActiveSession() {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return;

    _userSubscription = _firestore
        .collection('users')
        .doc(userId)
        .snapshots()
        .listen((userDoc) {
      if (!userDoc.exists) return;

      final userData = userDoc.data();
      final activeSession = userData?['activeSpeedDatingSession'] as String?;

      if (activeSession != null) {
        debugPrint('✅ [Queue] Active session found: $activeSession');
        state = state.copyWith(
          isInQueue: false,
          currentMatchId: activeSession,
        );
      }
    });
  }

  /// Listen to queue count
  void _listenToQueueCount() {
    _queueSubscription = _firestore
        .collection('speed_dating_queue')
        .where('status', isEqualTo: 'waiting')
        .snapshots()
        .listen((snapshot) {
      final queue = snapshot.docs
          .map((doc) => QueueEntry.fromMap(doc.data(), doc.id))
          .toList();

      state = state.copyWith(queue: queue);
    });
  }

  /// Join queue via Cloud Function
  /// Cloud Function handles validation + matching
  Future<void> joinQueue(SpeedDatingPreferences preferences) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) {
      state = state.copyWith(error: 'Not authenticated');
      return;
    }

    try {
      state = state.copyWith(isLoading: true, error: null);

      // Call Cloud Function to join queue
      final callable = _functions.httpsCallable('joinSpeedDatingQueue');
      final result = await callable.call({
        'preferences': preferences.toMap(),
      });

      if (result.data['success'] == true) {
        state = state.copyWith(
          isInQueue: true,
          isLoading: false,
        );
        debugPrint('✅ [Queue] Joined queue, waiting for match...');
      } else {
        throw Exception('Failed to join queue');
      }
    } on FirebaseFunctionsException catch (e) {
      debugPrint('❌ [Queue] Cloud Function error: ${e.code} - ${e.message}');
      state = state.copyWith(
        isLoading: false,
        error: e.message ?? 'Failed to join queue',
      );
    } catch (e) {
      debugPrint('❌ [Queue] Error joining queue: $e');
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  /// Leave queue via Cloud Function
  Future<void> leaveQueue() async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return;

    try {
      state = state.copyWith(isLoading: true);

      final callable = _functions.httpsCallable('leaveSpeedDatingQueue');
      await callable.call();

      state = state.copyWith(
        isInQueue: false,
        currentMatchId: null,
        isLoading: false,
      );

      debugPrint('✅ [Queue] Left queue');
    } on FirebaseFunctionsException catch (e) {
      debugPrint('❌ [Queue] Error leaving queue: ${e.code} - ${e.message}');
      state = state.copyWith(
        isLoading: false,
        error: e.message,
      );
    } catch (e) {
      debugPrint('❌ [Queue] Error leaving queue: $e');
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }
}

/// Provider for speed dating queue
final speedDatingQueueProvider =
    NotifierProvider<SpeedDatingQueueController, QueueState>(
  SpeedDatingQueueController.new,
);

/// Provider to check if user is in queue
final isInQueueProvider = Provider<bool>((ref) {
  return ref.watch(speedDatingQueueProvider).isInQueue;
});

/// Provider for queue count
final queueCountProvider = Provider<int>((ref) {
  return ref.watch(speedDatingQueueProvider).queue.length;
});

/// Provider for current match ID
final currentMatchIdProvider = Provider<String?>((ref) {
  return ref.watch(speedDatingQueueProvider).currentMatchId;
});
