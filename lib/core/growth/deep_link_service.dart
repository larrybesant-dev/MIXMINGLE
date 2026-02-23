/// Deep Link Service
///
/// Handles incoming deep links for room invites, referrals,
/// profiles, and events with auto-join functionality.
library;

import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/analytics/analytics_service.dart';
import 'referral_service.dart';

/// Service for handling deep links
class DeepLinkService {
  static DeepLinkService? _instance;
  static DeepLinkService get instance => _instance ??= DeepLinkService._();

  DeepLinkService._();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final AnalyticsService _analytics = AnalyticsService.instance;
  final ReferralService _referral = ReferralService.instance;

  // Deep link prefixes
  static const String roomPrefix = '/r/';
  static const String profilePrefix = '/u/';
  static const String eventPrefix = '/e/';
  static const String referralPrefix = '/ref/';
  static const String clipPrefix = '/clip/';

  // Pending deep link (when user is not logged in)
  DeepLinkData? _pendingDeepLink;

  /// Get pending deep link
  DeepLinkData? get pendingDeepLink => _pendingDeepLink;

  /// Clear pending deep link
  void clearPendingDeepLink() {
    _pendingDeepLink = null;
  }

  // ============================================================
  // DEEP LINK PARSING
  // ============================================================

  /// Parse a deep link URL
  DeepLinkData? parseDeepLink(Uri uri) {
    try {
      final path = uri.path;
      final queryParams = uri.queryParameters;

      debugPrint('ðŸ“± [DeepLink] Parsing: $uri');

      // Room invite link
      if (path.startsWith(roomPrefix)) {
        final roomId = path.substring(roomPrefix.length);
        return DeepLinkData(
          type: DeepLinkType.room,
          id: roomId,
          source: queryParams['src'],
        );
      }

      // Profile link
      if (path.startsWith(profilePrefix)) {
        final userId = path.substring(profilePrefix.length);
        return DeepLinkData(
          type: DeepLinkType.profile,
          id: userId,
          source: queryParams['src'],
        );
      }

      // Event link
      if (path.startsWith(eventPrefix)) {
        final eventId = path.substring(eventPrefix.length);
        return DeepLinkData(
          type: DeepLinkType.event,
          id: eventId,
          source: queryParams['src'],
        );
      }

      // Referral link
      if (path.startsWith(referralPrefix)) {
        final code = path.substring(referralPrefix.length);
        return DeepLinkData(
          type: DeepLinkType.referral,
          id: code,
          source: queryParams['src'],
        );
      }

      // Spotlight clip link
      if (path.startsWith(clipPrefix)) {
        final clipId = path.substring(clipPrefix.length);
        return DeepLinkData(
          type: DeepLinkType.clip,
          id: clipId,
          source: queryParams['src'],
        );
      }

      return null;
    } catch (e) {
      debugPrint('âŒ [DeepLink] Failed to parse: $e');
      return null;
    }
  }

  // ============================================================
  // DEEP LINK HANDLING
  // ============================================================

  /// Handle a deep link
  /// Returns the route to navigate to
  Future<DeepLinkResult> handleDeepLink(
    DeepLinkData deepLink, {
    String? currentUserId,
  }) async {
    try {
      await _analytics.logEvent(
        name: 'deep_link_opened',
        parameters: {
          'type': deepLink.type.name,
          'id': deepLink.id,
          'source': deepLink.source ?? 'direct',
        },
      );

      switch (deepLink.type) {
        case DeepLinkType.room:
          return await _handleRoomLink(deepLink, currentUserId);
        case DeepLinkType.profile:
          return _handleProfileLink(deepLink);
        case DeepLinkType.event:
          return _handleEventLink(deepLink);
        case DeepLinkType.referral:
          return await _handleReferralLink(deepLink, currentUserId);
        case DeepLinkType.clip:
          return _handleClipLink(deepLink);
      }
    } catch (e) {
      debugPrint('âŒ [DeepLink] Failed to handle: $e');
      return DeepLinkResult(
        success: false,
        error: 'Failed to process link',
      );
    }
  }

  /// Handle room invite link
  Future<DeepLinkResult> _handleRoomLink(
    DeepLinkData deepLink,
    String? currentUserId,
  ) async {
    final roomId = deepLink.id;

    // Check if room exists and is active
    final roomDoc = await _firestore.collection('rooms').doc(roomId).get();

    if (!roomDoc.exists) {
      return DeepLinkResult(
        success: false,
        error: 'Room not found',
      );
    }

    final roomData = roomDoc.data()!;
    final isActive = roomData['isActive'] ?? false;
    final status = roomData['status'] ?? 'closed';

    if (!isActive || status != 'live') {
      return DeepLinkResult(
        success: false,
        error: 'This room is no longer active',
        route: '/discover',
      );
    }

    // Check if user is logged in
    if (currentUserId == null) {
      // Store pending link for after login
      _pendingDeepLink = deepLink;
      return DeepLinkResult(
        success: true,
        requiresAuth: true,
        route: '/login',
        message: 'Please sign in to join this room',
      );
    }

    // Check if user is banned from room
    final bannedUsers = List<String>.from(roomData['bannedUsers'] ?? []);
    if (bannedUsers.contains(currentUserId)) {
      return DeepLinkResult(
        success: false,
        error: 'You cannot join this room',
      );
    }

    // Track room join from deep link
    await _firestore.collection('rooms').doc(roomId).update({
      'deepLinkJoins': FieldValue.increment(1),
    });

    return DeepLinkResult(
      success: true,
      route: '/room/$roomId',
      autoAction: DeepLinkAction.joinRoom,
      data: {'roomId': roomId},
    );
  }

  /// Handle profile link
  DeepLinkResult _handleProfileLink(DeepLinkData deepLink) {
    return DeepLinkResult(
      success: true,
      route: '/profile/${deepLink.id}',
      data: {'userId': deepLink.id},
    );
  }

  /// Handle event link
  DeepLinkResult _handleEventLink(DeepLinkData deepLink) {
    return DeepLinkResult(
      success: true,
      route: '/event/${deepLink.id}',
      data: {'eventId': deepLink.id},
    );
  }

  /// Handle referral link
  Future<DeepLinkResult> _handleReferralLink(
    DeepLinkData deepLink,
    String? currentUserId,
  ) async {
    final referralCode = deepLink.id;

    // If user is logged in, try to redeem
    if (currentUserId != null) {
      final result = await _referral.redeemReferralCode(
        currentUserId,
        referralCode,
      );

      if (result.success) {
        return DeepLinkResult(
          success: true,
          route: '/home',
          message: result.message,
          autoAction: DeepLinkAction.showReward,
          data: {'coinsEarned': result.refereeReward},
        );
      } else {
        return DeepLinkResult(
          success: false,
          error: result.message,
          route: '/home',
        );
      }
    }

    // Store for after signup
    _pendingDeepLink = deepLink;
    return DeepLinkResult(
      success: true,
      requiresAuth: true,
      route: '/signup',
      message: 'Sign up to claim your bonus coins!',
      data: {'referralCode': referralCode},
    );
  }

  /// Handle clip link
  DeepLinkResult _handleClipLink(DeepLinkData deepLink) {
    return DeepLinkResult(
      success: true,
      route: '/spotlight/${deepLink.id}',
      data: {'clipId': deepLink.id},
    );
  }

  // ============================================================
  // AUTO-JOIN FUNCTIONALITY
  // ============================================================

  /// Handle invite link and auto-join room
  Future<AutoJoinResult> handleInviteLink(
    String roomId,
    String userId,
    String userName,
  ) async {
    try {
      // Check room exists and is joinable
      final roomDoc = await _firestore.collection('rooms').doc(roomId).get();

      if (!roomDoc.exists) {
        return AutoJoinResult(
          success: false,
          error: 'Room not found',
        );
      }

      final roomData = roomDoc.data()!;

      // Validate room status
      if (roomData['isActive'] != true || roomData['status'] != 'live') {
        return AutoJoinResult(
          success: false,
          error: 'Room is no longer active',
        );
      }

      // Check if banned
      final bannedUsers = List<String>.from(roomData['bannedUsers'] ?? []);
      if (bannedUsers.contains(userId)) {
        return AutoJoinResult(
          success: false,
          error: 'You are not allowed in this room',
        );
      }

      // Check capacity
      final participantIds = List<String>.from(roomData['participantIds'] ?? []);
      final maxParticipants = roomData['maxParticipants'] ?? 100;
      if (participantIds.length >= maxParticipants) {
        return AutoJoinResult(
          success: false,
          error: 'Room is full',
        );
      }

      // Auto-join the room
      await _firestore.collection('rooms').doc(roomId).update({
        'participantIds': FieldValue.arrayUnion([userId]),
        'listeners': FieldValue.arrayUnion([userId]),
        'viewerCount': FieldValue.increment(1),
        'updatedAt': FieldValue.serverTimestamp(),
        'deepLinkJoins': FieldValue.increment(1),
      });

      // Track analytics
      await _analytics.logEvent(
        name: 'room_auto_joined',
        parameters: {
          'room_id': roomId,
          'user_id': userId,
          'source': 'deep_link',
        },
      );

      debugPrint('âœ… [DeepLink] Auto-joined room: $roomId');

      return AutoJoinResult(
        success: true,
        roomId: roomId,
        roomTitle: roomData['title'] ?? roomData['name'],
      );
    } catch (e) {
      debugPrint('âŒ [DeepLink] Auto-join failed: $e');
      return AutoJoinResult(
        success: false,
        error: 'Failed to join room',
      );
    }
  }

  /// Process pending deep link after authentication
  Future<DeepLinkResult?> processPendingDeepLink(String userId) async {
    if (_pendingDeepLink == null) {
      return null;
    }

    final deepLink = _pendingDeepLink!;
    _pendingDeepLink = null;

    return await handleDeepLink(deepLink, currentUserId: userId);
  }
}

// ============================================================
// ENUMS
// ============================================================

enum DeepLinkType {
  room,
  profile,
  event,
  referral,
  clip,
}

enum DeepLinkAction {
  joinRoom,
  showReward,
  viewProfile,
  viewEvent,
  viewClip,
}

// ============================================================
// DATA CLASSES
// ============================================================

class DeepLinkData {
  final DeepLinkType type;
  final String id;
  final String? source;
  final Map<String, String>? extraParams;

  const DeepLinkData({
    required this.type,
    required this.id,
    this.source,
    this.extraParams,
  });
}

class DeepLinkResult {
  final bool success;
  final String? route;
  final String? error;
  final String? message;
  final bool requiresAuth;
  final DeepLinkAction? autoAction;
  final Map<String, dynamic>? data;

  const DeepLinkResult({
    required this.success,
    this.route,
    this.error,
    this.message,
    this.requiresAuth = false,
    this.autoAction,
    this.data,
  });
}

class AutoJoinResult {
  final bool success;
  final String? roomId;
  final String? roomTitle;
  final String? error;

  const AutoJoinResult({
    required this.success,
    this.roomId,
    this.roomTitle,
    this.error,
  });
}
