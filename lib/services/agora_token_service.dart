import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart';
import '../core/utils/agora_token_cache.dart';

/// Service for fetching Agora tokens from Cloud Functions using callable API
/// Implements caching and request coalescing to minimize function calls
class AgoraTokenService {
  final FirebaseAuth _auth;
  final FirebaseFunctions _functions;
  final AgoraTokenCache _cache = AgoraTokenCache();

  AgoraTokenService({
    FirebaseAuth? auth,
  })  : _auth = auth ?? FirebaseAuth.instance,
        _functions = FirebaseFunctions.instanceFor(region: 'us-central1');

  /// Fetch Agora token for a room using Cloud Functions callable API
  /// Implements caching and request coalescing to prevent duplicate calls
  ///
  /// [channelName] - Room ID
  /// [uid] - Numeric user ID (use user's UID hashCode or 0)
  /// [role] - 'broadcaster' for host/speaker, 'audience' for listener
  Future<AgoraTokenResponse> getToken({
    required String channelName,
    required int uid,
    required String role,
  }) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      throw Exception('User not authenticated');
    }

    // Check cache first
    final cachedToken = _cache.getCachedToken(channelName, currentUser.uid);
    if (cachedToken != null) {
      if (kDebugMode) {
        debugPrint('[AgoraTokenService] Using cached token (${cachedToken.secondsRemaining}s remaining)');
      }
      return AgoraTokenResponse(
        token: cachedToken.token,
        appId: '',
        channelName: channelName,
        uid: cachedToken.uid,
        role: 0,
        expiresAt: cachedToken.expiresAtMs,
      );
    }

    // Check for in-flight request (coalescing)
    final inFlight = _cache.coalescer.getInFlightRequest(channelName, currentUser.uid);
    if (inFlight != null) {
      if (kDebugMode) {
        debugPrint('[AgoraTokenService] Reusing in-flight request for $channelName:${currentUser.uid}');
      }
      final cachedResult = await inFlight;
      return AgoraTokenResponse(
        token: cachedResult.token,
        appId: '',
        channelName: channelName,
        uid: cachedResult.uid,
        role: 0,
        expiresAt: cachedResult.expiresAtMs,
      );
    }

    // Make new request with coalescing
    final requestFuture = _fetchNewToken(channelName, currentUser);
    _cache.coalescer.registerRequest(channelName, currentUser.uid, requestFuture);

    try {
      final cachedToken = await requestFuture;
      _cache.cacheToken(cachedToken);

      return AgoraTokenResponse(
        token: cachedToken.token,
        appId: '',
        channelName: channelName,
        uid: cachedToken.uid,
        role: 0,
        expiresAt: cachedToken.expiresAtMs,
      );
    } catch (e) {
      throw Exception('Error fetching Agora token: $e');
    }
  }

  /// Actual token fetch (separated for clarity)
  Future<CachedAgoraToken> _fetchNewToken(
    String channelName,
    User currentUser,
  ) async {
    // CRITICAL FIX: Refresh ID token FIRST to ensure callable auth context is valid
    await currentUser.getIdToken(true);

    // Use callable API - auth context is automatically included by Firebase SDK
    final callable = _functions.httpsCallable('generateAgoraToken');
    final result = await callable.call({
      'roomId': channelName,
      'userId': currentUser.uid,
    });

    final data = result.data as Map<String, dynamic>;
    final expiresAt =
        data['expiresAt'] as int? ?? (DateTime.now().millisecondsSinceEpoch + (24 * 60 * 60 * 1000)); // Default 24h

    return CachedAgoraToken(
      token: data['token'] as String,
      roomId: channelName,
      userId: currentUser.uid,
      uid: data['uid'] as int? ?? 0,
      expiresAtMs: expiresAt,
      createdAt: DateTime.now(),
    );
  }

  /// Generate numeric UID from string (for Agora)
  static int uidFromString(String uid) {
    return uid.hashCode.abs() % 2147483647; // Max int32
  }
}

/// Response from Agora token endpoint
class AgoraTokenResponse {
  final String token;
  final String appId;
  final String channelName;
  final int uid;
  final int role;
  final int expiresAt;

  AgoraTokenResponse({
    required this.token,
    required this.appId,
    required this.channelName,
    required this.uid,
    required this.role,
    required this.expiresAt,
  });

  factory AgoraTokenResponse.fromJson(Map<String, dynamic> json) {
    return AgoraTokenResponse(
      token: json['token'] as String,
      appId: json['appId'] as String,
      channelName: json['channelName'] as String,
      uid: json['uid'] as int,
      role: json['role'] as int,
      expiresAt: json['expiresAt'] as int,
    );
  }

  bool get isExpired => DateTime.now().millisecondsSinceEpoch > expiresAt;
}
