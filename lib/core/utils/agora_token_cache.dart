import 'dart:async';
import 'package:flutter/foundation.dart';

/// Cached Agora token with expiration
class CachedAgoraToken {
  final String token;
  final String roomId;
  final String userId;
  final int uid;
  final int expiresAtMs;
  final DateTime createdAt;

  CachedAgoraToken({
    required this.token,
    required this.roomId,
    required this.userId,
    required this.uid,
    required this.expiresAtMs,
    required this.createdAt,
  });

  /// Check if token is still valid (with 2 minute buffer)
  bool get isValid {
    const bufferMs = 2 * 60 * 1000; // 2 minute buffer before expiry
    return DateTime.now().millisecondsSinceEpoch < (expiresAtMs - bufferMs);
  }

  /// Check if token is expired
  bool get isExpired => !isValid;

  /// Time remaining in seconds
  int get secondsRemaining {
    final remaining = expiresAtMs - DateTime.now().millisecondsSinceEpoch;
    return (remaining / 1000).ceil();
  }
}

/// Implements request coalescing for Agora token generation
/// Prevents duplicate token requests while one is in flight
class AgoraTokenCoalescer {
  static final AgoraTokenCoalescer _instance = AgoraTokenCoalescer._internal();
  factory AgoraTokenCoalescer() => _instance;
  AgoraTokenCoalescer._internal();

  // In-flight requests: key = "roomId:userId"
  final Map<String, Future<CachedAgoraToken>> _inFlightRequests = {};

  /// Get request key
  static String _getKey(String roomId, String userId) => '$roomId:$userId';

  /// Coalesce multiple requests for the same token
  /// Returns existing in-flight request or starts new one
  Future<CachedAgoraToken>? getInFlightRequest(String roomId, String userId) {
    final key = _getKey(roomId, userId);
    return _inFlightRequests[key];
  }

  /// Register an in-flight request
  void registerRequest(
    String roomId,
    String userId,
    Future<CachedAgoraToken> request,
  ) {
    final key = _getKey(roomId, userId);
    _inFlightRequests[key] = request;

    // Auto-cleanup when request completes
    request.whenComplete(() {
      _inFlightRequests.remove(key);
      if (kDebugMode) {
        debugPrint('[AgoraTokenCoalescer] Request cleared: $key');
      }
    });
  }

  /// Get pending request count
  int get pendingRequests => _inFlightRequests.length;

  /// Clear all requests
  void clear() {
    _inFlightRequests.clear();
  }

  /// Debug info
  String get debugInfo => 'Pending: ${_inFlightRequests.length} requests';
}

/// Caches Agora tokens to reduce function calls
class AgoraTokenCache {
  static final AgoraTokenCache _instance = AgoraTokenCache._internal();
  factory AgoraTokenCache() => _instance;
  AgoraTokenCache._internal();

  // Cache: key = "roomId:userId"
  final Map<String, CachedAgoraToken> _cache = {};
  final AgoraTokenCoalescer _coalescer = AgoraTokenCoalescer();

  /// Get cached token if valid, otherwise null
  CachedAgoraToken? getCachedToken(String roomId, String userId) {
    final key = '$roomId:$userId';
    final cached = _cache[key];

    if (cached != null && cached.isValid) {
      if (kDebugMode) {
        debugPrint(
            '[AgoraTokenCache] Cache HIT: $key (${cached.secondsRemaining}s remaining)');
      }
      return cached;
    }

    if (kDebugMode) {
      debugPrint('[AgoraTokenCache] Cache MISS: $key');
    }
    _cache.remove(key);
    return null;
  }

  /// Cache a token
  void cacheToken(CachedAgoraToken token) {
    final key = '${token.roomId}:${token.userId}';
    _cache[key] = token;
    if (kDebugMode) {
      debugPrint(
          '[AgoraTokenCache] Cached token: $key (${token.secondsRemaining}s TTL)');
    }
  }

  /// Get coalescer for request deduplication
  AgoraTokenCoalescer get coalescer => _coalescer;

  /// Get cache stats
  Map<String, dynamic> getStats() {
    return {
      'cachedTokens': _cache.length,
      'validTokens': _cache.values.where((t) => t.isValid).length,
      'expiredTokens': _cache.values.where((t) => t.isExpired).length,
      'pendingRequests': _coalescer.pendingRequests,
    };
  }

  /// Clear expired tokens
  void clearExpired() {
    final before = _cache.length;
    _cache.removeWhere((_, token) => token.isExpired);
    final after = _cache.length;
    if (before != after) {
      debugPrint(
          '[AgoraTokenCache] Cleaned: Removed ${before - after} expired tokens');
    }
  }

  /// Clear all cache
  void clear() {
    _cache.clear();
    _coalescer.clear();
  }
}
