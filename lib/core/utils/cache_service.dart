import 'dart:async';
import 'package:flutter/foundation.dart';

/// Generic in-memory cache with TTL (Time To Live)
class CacheService<K, V> {
  final Duration ttl;
  final int maxSize;
  final Map<K, _CacheEntry<V>> _cache = {};
  final List<K> _accessOrder = [];

  CacheService({
    this.ttl = const Duration(minutes: 5),
    this.maxSize = 100,
  });

  /// Get a value from cache
  V? get(K key) {
    final entry = _cache[key];
    if (entry == null) return null;

    // Check if expired
    if (entry.isExpired) {
      _cache.remove(key);
      _accessOrder.remove(key);
      return null;
    }

    // Update access order (LRU)
    _accessOrder.remove(key);
    _accessOrder.add(key);

    return entry.value;
  }

  /// Put a value in cache
  void put(K key, V value) {
    // Remove if already exists
    if (_cache.containsKey(key)) {
      _accessOrder.remove(key);
    }

    // Evict oldest if at capacity
    if (_cache.length >= maxSize) {
      final oldestKey = _accessOrder.first;
      _cache.remove(oldestKey);
      _accessOrder.removeAt(0);
    }

    // Add new entry
    _cache[key] = _CacheEntry(value, DateTime.now().add(ttl));
    _accessOrder.add(key);
  }

  /// Remove a value from cache
  void remove(K key) {
    _cache.remove(key);
    _accessOrder.remove(key);
  }

  /// Clear all cache
  void clear() {
    _cache.clear();
    _accessOrder.clear();
  }

  /// Get cache size
  int get size => _cache.length;

  /// Check if key exists and is not expired
  bool contains(K key) {
    final entry = _cache[key];
    if (entry == null) return false;
    if (entry.isExpired) {
      _cache.remove(key);
      _accessOrder.remove(key);
      return false;
    }
    return true;
  }

  /// Get or compute value
  Future<V> getOrCompute(K key, Future<V> Function() compute) async {
    final cached = get(key);
    if (cached != null) return cached;

    final value = await compute();
    put(key, value);
    return value;
  }

  /// Clean up expired entries
  void cleanupExpired() {
    final now = DateTime.now();
    final expiredKeys = <K>[];

    for (final entry in _cache.entries) {
      if (entry.value.expiresAt.isBefore(now)) {
        expiredKeys.add(entry.key);
      }
    }

    for (final key in expiredKeys) {
      _cache.remove(key);
      _accessOrder.remove(key);
    }

    if (expiredKeys.isNotEmpty) {
      debugPrint('Cleaned up ${expiredKeys.length} expired cache entries');
    }
  }
}

class _CacheEntry<V> {
  final V value;
  final DateTime expiresAt;

  _CacheEntry(this.value, this.expiresAt);

  bool get isExpired => DateTime.now().isAfter(expiresAt);
}

/// Global cache instances
class AppCaches {
  static final userProfiles = CacheService<String, dynamic>(
    ttl: const Duration(minutes: 10),
    maxSize: 200,
  );

  static final eventDetails = CacheService<String, dynamic>(
    ttl: const Duration(minutes: 5),
    maxSize: 100,
  );

  static final roomDetails = CacheService<String, dynamic>(
    ttl: const Duration(minutes: 3),
    maxSize: 50,
  );

  /// Clear all caches
  static void clearAll() {
    userProfiles.clear();
    eventDetails.clear();
    roomDetails.clear();
  }

  /// Cleanup expired entries in all caches
  static void cleanupAll() {
    userProfiles.cleanupExpired();
    eventDetails.cleanupExpired();
    roomDetails.cleanupExpired();
  }
}
