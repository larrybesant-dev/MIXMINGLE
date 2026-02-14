import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show debugPrint;
import '../core/utils/app_logger.dart';

/// Service to seed Firestore collections with initial data
class FirestoreSeedingService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseFunctions _functions = FirebaseFunctions.instance;

  /// Call seedFirestore Cloud Function to initialize required collections
  static Future<bool> seedCollections() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        AppLogger.warning('🌱 Cannot seed: user not authenticated');
        debugPrint('[SEEDING] User not authenticated');
        return false;
      }

      debugPrint('[SEEDING] Calling seedFirestore for user ${user.uid}');
      AppLogger.info('🌱 Initializing Firestore collections...');

      final response = await _functions
          .httpsCallable('seedFirestore')
          .call()
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () {
              throw Exception('Seeding timeout');
            },
          );

      final data = response.data as Map<dynamic, dynamic>?;

      if (data?['success'] == true) {
        debugPrint('[SEEDING] ✅ Collections initialized');
        AppLogger.info('✅ Firestore collections ready: messages, notifications, tips');
        return true;
      } else {
        debugPrint('[SEEDING] ❌ Seeding returned false');
        return false;
      }
    } catch (e) {
      debugPrint('[SEEDING] Error: $e');
      AppLogger.error('❌ Firestore seeding failed: $e');
      return false;
    }
  }
}


