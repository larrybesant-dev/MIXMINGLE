import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../shared/models/typing_indicator.dart';

/// Service for managing typing indicators in chats
/// Phase 2 Enhanced: Error handling, retry guards, stream stability
class TypingService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final Map<String, Timer?> _typingTimers = {};

  // Retry guards
  static const int _maxRetries = 3;
  static const Duration _retryDelay = Duration(seconds: 2);
  final Map<String, int> _retryCounters = {};
  final Map<String, StreamController<List<TypingIndicator>>> _streamControllers = {};

  /// Start typing in a chat
  Future<void> startTyping(String chatId, String userId, String userName) async {
    try {
      // Cancel existing timer
      _typingTimers[chatId]?.cancel();

      // Set typing indicator
      await _firestore.collection('typing').doc('${chatId}_$userId').set({
        'userId': userId,
        'userName': userName,
        'chatId': chatId,
        'startedAt': FieldValue.serverTimestamp(),
      });

      // Auto-stop after 3 seconds
      _typingTimers[chatId] = Timer(
        const Duration(seconds: 3),
        () => stopTyping(chatId, userId),
      );
    } catch (e) {
      debugPrint('Error starting typing: $e');
    }
  }

  /// Stop typing in a chat
  Future<void> stopTyping(String chatId, String userId) async {
    try {
      _typingTimers[chatId]?.cancel();
      _typingTimers.remove(chatId);

      await _firestore.collection('typing').doc('${chatId}_$userId').delete();
    } catch (e) {
      debugPrint('Error stopping typing: $e');
    }
  }

  /// Get typing indicators for a chat with error handling and retry guards
  Stream<List<TypingIndicator>> getTypingIndicators(String chatId, String currentUserId) {
    final retryKey = 'getTypingIndicators_$chatId';

    // Prevent infinite retry loops
    if (_retryCounters[retryKey] != null && _retryCounters[retryKey]! >= _maxRetries) {
      debugPrint('âš ï¸ Max retries reached for getTypingIndicators($chatId)');
      return Stream.value([]);
    }

    // Reuse existing stream controller if available
    if (_streamControllers.containsKey(chatId)) {
      return _streamControllers[chatId]!.stream;
    }

    // Create new stream controller with error handling
    final controller = StreamController<List<TypingIndicator>>.broadcast(
      onCancel: () {
        debugPrint('ðŸ”Œ Typing indicators stream cancelled for chat: $chatId');
        _cleanupStream(chatId);
      },
    );

    _streamControllers[chatId] = controller;

    // Start listening with error recovery
    _startTypingListener(chatId, currentUserId, controller, retryKey);

    return controller.stream;
  }

  /// Internal listener with retry logic
  void _startTypingListener(
    String chatId,
    String currentUserId,
    StreamController<List<TypingIndicator>> controller,
    String retryKey,
  ) {
    StreamSubscription<QuerySnapshot>? subscription;

    final fiveSecondsAgo = DateTime.now().subtract(const Duration(seconds: 5));

    subscription = _firestore
        .collection('typing')
        .where('chatId', isEqualTo: chatId)
        .where('startedAt', isGreaterThan: Timestamp.fromDate(fiveSecondsAgo))
        .snapshots()
        .listen(
      (snapshot) {
        try {
          // Reset retry counter on success
          _retryCounters[retryKey] = 0;

          final indicators = snapshot.docs
              .map((doc) {
                try {
                  return TypingIndicator.fromMap(doc.data());
                } catch (e) {
                  debugPrint('âš ï¸ Failed to parse typing indicator: $e');
                  return null;
                }
              })
              .whereType<TypingIndicator>()
              .where((indicator) => indicator.userId != currentUserId) // Exclude self
              .where((indicator) => indicator.isValid) // Only valid indicators
              .toList();

          if (!controller.isClosed) {
            controller.add(indicators);
          }
        } catch (e, stackTrace) {
          debugPrint('âŒ Error processing typing indicators: $e');
          debugPrint('Stack trace: $stackTrace');
          if (!controller.isClosed) {
            controller.add([]); // Emit empty list instead of error
          }
        }
      },
      onError: (error, stackTrace) {
        debugPrint('âŒ Typing indicators stream error for $chatId: $error');
        debugPrint('Stack trace: $stackTrace');

        // Increment retry counter
        _retryCounters[retryKey] = (_retryCounters[retryKey] ?? 0) + 1;

        // Emit empty list
        if (!controller.isClosed) {
          controller.add([]);
        }

        // Retry with exponential backoff if under max retries
        if (_retryCounters[retryKey]! < _maxRetries) {
          final delay = _retryDelay * _retryCounters[retryKey]!;
          debugPrint('ðŸ”„ Retrying typing listener in ${delay.inSeconds}s...');

          Future.delayed(delay, () {
            if (!controller.isClosed) {
              subscription?.cancel();
              _startTypingListener(chatId, currentUserId, controller, retryKey);
            }
          });
        } else {
          debugPrint('â›” Max retries reached for typing listener: $chatId');
          _cleanupStream(chatId);
        }
      },
      cancelOnError: false, // Don't auto-cancel on error
    );

    // Store subscription for cleanup
    controller.onCancel = () {
      subscription?.cancel();
      _cleanupStream(chatId);
    };
  }

  /// Cleanup stream resources
  void _cleanupStream(String chatId) {
    _streamControllers[chatId]?.close();
    _streamControllers.remove(chatId);
    _retryCounters.remove('getTypingIndicators_$chatId');
  }

  /// Cleanup old typing indicators (called periodically)
  Future<void> cleanupOldIndicators() async {
    try {
      final fiveSecondsAgo = DateTime.now().subtract(const Duration(seconds: 5));

      final snapshot = await _firestore
          .collection('typing')
          .where('startedAt', isLessThan: Timestamp.fromDate(fiveSecondsAgo))
          .get();

      final batch = _firestore.batch();
      for (var doc in snapshot.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
    } catch (e) {
      debugPrint('Error cleaning up typing indicators: $e');
    }
  }

  /// Dispose with proper resource cleanup
  void dispose() {
    debugPrint('ðŸ§¹ Disposing TypingService...');

    for (var timer in _typingTimers.values) {
      timer?.cancel();
    }
    _typingTimers.clear();

    // Close all stream controllers
    for (var controller in _streamControllers.values) {
      controller.close();
    }
    _streamControllers.clear();
    _retryCounters.clear();
  }
}
