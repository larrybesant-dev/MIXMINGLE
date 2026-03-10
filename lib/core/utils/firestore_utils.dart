import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'app_logger.dart';

/// Safe Firestore operations with retry logic and error handling
class SafeFirestore {
  static const int _maxRetries = 3;
  static const Duration _initialDelay = Duration(milliseconds: 500);

  /// Safely write to Firestore with retry
  static Future<void> safeSet({
    required DocumentReference ref,
    required Map<String, dynamic> data,
    SetOptions? options,
    int retryCount = 0,
  }) async {
    try {
      await ref.set(data, options ?? SetOptions(merge: true));
      if (retryCount > 0) {
        AppLogger.info('Firestore set succeeded after $retryCount retries');
      }
    } catch (e, stackTrace) {
      if (retryCount < _maxRetries) {
        final delay = _calculateBackoff(retryCount);
        AppLogger.warning(
            'Firestore set failed, retrying in ${delay.inMilliseconds}ms (attempt ${retryCount + 1}/$_maxRetries)');
        await Future.delayed(delay);
        return safeSet(
          ref: ref,
          data: data,
          options: options,
          retryCount: retryCount + 1,
        );
      } else {
        AppLogger.firestoreError('set', e, stackTrace);
        rethrow;
      }
    }
  }

  /// Safely update Firestore document with retry
  static Future<void> safeUpdate({
    required DocumentReference ref,
    required Map<String, dynamic> data,
    int retryCount = 0,
  }) async {
    try {
      await ref.update(data);
      if (retryCount > 0) {
        AppLogger.info('Firestore update succeeded after $retryCount retries');
      }
    } catch (e, stackTrace) {
      if (retryCount < _maxRetries) {
        final delay = _calculateBackoff(retryCount);
        AppLogger.warning(
            'Firestore update failed, retrying in ${delay.inMilliseconds}ms (attempt ${retryCount + 1}/$_maxRetries)');
        await Future.delayed(delay);
        return safeUpdate(
          ref: ref,
          data: data,
          retryCount: retryCount + 1,
        );
      } else {
        AppLogger.firestoreError('update', e, stackTrace);
        rethrow;
      }
    }
  }

  /// Safely delete Firestore document with retry
  static Future<void> safeDelete({
    required DocumentReference ref,
    int retryCount = 0,
  }) async {
    try {
      await ref.delete();
      if (retryCount > 0) {
        AppLogger.info('Firestore delete succeeded after $retryCount retries');
      }
    } catch (e, stackTrace) {
      if (retryCount < _maxRetries) {
        final delay = _calculateBackoff(retryCount);
        AppLogger.warning(
            'Firestore delete failed, retrying in ${delay.inMilliseconds}ms (attempt ${retryCount + 1}/$_maxRetries)');
        await Future.delayed(delay);
        return safeDelete(
          ref: ref,
          retryCount: retryCount + 1,
        );
      } else {
        AppLogger.firestoreError('delete', e, stackTrace);
        rethrow;
      }
    }
  }

  /// Safely get document with retry
  static Future<DocumentSnapshot?> safeGet({
    required DocumentReference ref,
    int retryCount = 0,
  }) async {
    try {
      final snapshot = await ref.get();
      if (retryCount > 0) {
        AppLogger.info('Firestore get succeeded after $retryCount retries');
      }
      return snapshot;
    } catch (e, stackTrace) {
      if (retryCount < _maxRetries) {
        final delay = _calculateBackoff(retryCount);
        AppLogger.warning(
            'Firestore get failed, retrying in ${delay.inMilliseconds}ms (attempt ${retryCount + 1}/$_maxRetries)');
        await Future.delayed(delay);
        return safeGet(
          ref: ref,
          retryCount: retryCount + 1,
        );
      } else {
        AppLogger.firestoreError('get', e, stackTrace);
        return null;
      }
    }
  }

  /// Safely execute query with retry
  static Future<QuerySnapshot?> safeQuery({
    required Query query,
    int retryCount = 0,
  }) async {
    try {
      final snapshot = await query.get();
      if (retryCount > 0) {
        AppLogger.info('Firestore query succeeded after $retryCount retries');
      }
      return snapshot;
    } catch (e, stackTrace) {
      if (retryCount < _maxRetries) {
        final delay = _calculateBackoff(retryCount);
        AppLogger.warning(
            'Firestore query failed, retrying in ${delay.inMilliseconds}ms (attempt ${retryCount + 1}/$_maxRetries)');
        await Future.delayed(delay);
        return safeQuery(
          query: query,
          retryCount: retryCount + 1,
        );
      } else {
        AppLogger.firestoreError('query', e, stackTrace);
        return null;
      }
    }
  }

  /// Calculate exponential backoff delay
  static Duration _calculateBackoff(int retryCount) {
    final multiplier = (1 << retryCount); // 2^retryCount
    return _initialDelay * multiplier;
  }

  /// Get value from map with safe default
  static T getValueOrDefault<T>(
    Map<String, dynamic> data,
    String key,
    T defaultValue,
  ) {
    try {
      if (!data.containsKey(key)) {
        AppLogger.nullWarning(key, 'Firestore document');
        return defaultValue;
      }

      final value = data[key];
      if (value == null) {
        AppLogger.nullWarning(key, 'Firestore document (null value)');
        return defaultValue;
      }

      if (value is T) {
        return value;
      } else {
        AppLogger.warning('Type mismatch for $key: expected $T, got ${value.runtimeType}');
        return defaultValue;
      }
    } catch (e) {
      AppLogger.error('Error getting value for $key', e);
      return defaultValue;
    }
  }

  /// Get nullable value from map with type safety
  static T? getNullableValue<T>(
    Map<String, dynamic> data,
    String key,
  ) {
    try {
      if (!data.containsKey(key)) {
        return null;
      }

      final value = data[key];
      if (value == null) {
        return null;
      }

      if (value is T) {
        return value;
      } else {
        AppLogger.warning('Type mismatch for $key: expected $T, got ${value.runtimeType}');
        return null;
      }
    } catch (e) {
      AppLogger.error('Error getting nullable value for $key', e);
      return null;
    }
  }
}


