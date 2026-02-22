import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

/// Configuration for optimized Firestore listeners
/// Improves web performance by reducing query overhead
class FirestoreListenerConfig {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Initialize Firestore for optimal web performance
  static void initialize() {
    if (kIsWeb) {
      // Set persistence for better offline support
      _firestore.settings = const Settings(
        persistenceEnabled: true,
        cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
      );

      debugPrint('[Firestore] Configured for web: Persistence enabled');
    }
  }

  /// Get optimized settings for room listeners
  static Settings getRoomListenerSettings() {
    return const Settings(
      persistenceEnabled: true,
      cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
    );
  }

  /// Create a batched query to reduce network overhead
  static Future<List<DocumentSnapshot>> batchedRead(
    List<String> docPaths, {
    required String collection,
  }) async {
    final firestore = FirebaseFirestore.instance;
    final batch = <DocumentSnapshot>[];

    // Read in chunks of 10 to avoid overwhelming the connection
    for (int i = 0; i < docPaths.length; i += 10) {
      final end = (i + 10 < docPaths.length) ? i + 10 : docPaths.length;
      final chunk = docPaths.sublist(i, end);

      final futures = chunk.map(
        (path) => firestore.collection(collection).doc(path).get(),
      );

      final results = await Future.wait(futures);
      batch.addAll(results);
    }

    return batch;
  }
}
