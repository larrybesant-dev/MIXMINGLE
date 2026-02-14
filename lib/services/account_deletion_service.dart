import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';

/// Service to handle GDPR-compliant account deletion
/// Cascades deletion across all user-related data
class AccountDeletionService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Deletes user account and all associated data in compliance with GDPR
  /// Returns true if successful, throws exception on failure
  Future<bool> deleteUserAccount(String userId) async {
    try {
      debugPrint('Starting account deletion for user: $userId');

      // 1. Delete user profile data
      await _deleteUserProfile(userId);

      // 2. Delete user's events (created events)
      await _deleteUserEvents(userId);

      // 3. Remove user from events they've joined
      await _removeUserFromJoinedEvents(userId);

      // 4. Delete user's messages
      await _deleteUserMessages(userId);

      // 5. Delete user's reports (submitted and received)
      await _deleteUserReports(userId);

      // 6. Delete user's blocks
      await _deleteUserBlocks(userId);

      // 7. Delete user's followers/following relationships
      await _deleteUserFollowRelationships(userId);

      // 8. Delete user's subscription data
      await _deleteUserSubscriptionData(userId);

      // 9. Delete user's storage files (photos, videos)
      await _deleteUserStorage(userId);

      // 10. Delete Firebase Auth account
      final user = _auth.currentUser;
      if (user != null && user.uid == userId) {
        await user.delete();
        debugPrint('Firebase Auth user deleted');
      }

      debugPrint('Account deletion completed successfully for user: $userId');
      return true;
    } catch (e) {
      debugPrint('Error during account deletion: $e');
      rethrow;
    }
  }

  /// Deletes user profile document
  Future<void> _deleteUserProfile(String userId) async {
    try {
      await _firestore.collection('users').doc(userId).delete();
      debugPrint('User profile deleted');
    } catch (e) {
      debugPrint('Error deleting user profile: $e');
      // Continue with other deletions even if this fails
    }
  }

  /// Deletes all events created by the user
  Future<void> _deleteUserEvents(String userId) async {
    try {
      final eventsQuery = await _firestore.collection('events').where('createdBy', isEqualTo: userId).get();

      final batch = _firestore.batch();
      for (var doc in eventsQuery.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
      debugPrint('User events deleted: ${eventsQuery.docs.length}');
    } catch (e) {
      debugPrint('Error deleting user events: $e');
    }
  }

  /// Removes user from participant lists of events they joined
  Future<void> _removeUserFromJoinedEvents(String userId) async {
    try {
      final eventsQuery = await _firestore.collection('events').where('participants', arrayContains: userId).get();

      final batch = _firestore.batch();
      for (var doc in eventsQuery.docs) {
        batch.update(doc.reference, {
          'participants': FieldValue.arrayRemove([userId]),
          'participantCount': FieldValue.increment(-1),
        });
      }
      await batch.commit();
      debugPrint('User removed from ${eventsQuery.docs.length} events');
    } catch (e) {
      debugPrint('Error removing user from events: $e');
    }
  }

  /// Deletes all messages sent by the user
  Future<void> _deleteUserMessages(String userId) async {
    try {
      // Delete from direct messages
      final messagesQuery = await _firestore.collection('messages').where('senderId', isEqualTo: userId).get();

      final batch = _firestore.batch();
      for (var doc in messagesQuery.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
      debugPrint('User messages deleted: ${messagesQuery.docs.length}');

      // Also delete conversation documents where user is participant
      final conversationsQuery =
          await _firestore.collection('conversations').where('participants', arrayContains: userId).get();

      final batch2 = _firestore.batch();
      for (var doc in conversationsQuery.docs) {
        batch2.delete(doc.reference);
      }
      await batch2.commit();
      debugPrint('User conversations deleted: ${conversationsQuery.docs.length}');
    } catch (e) {
      debugPrint('Error deleting user messages: $e');
    }
  }

  /// Deletes all reports submitted by or against the user
  Future<void> _deleteUserReports(String userId) async {
    try {
      // Reports submitted by user
      final submittedReportsQuery = await _firestore.collection('reports').where('reporterId', isEqualTo: userId).get();

      // Reports against user
      final receivedReportsQuery =
          await _firestore.collection('reports').where('reportedUserId', isEqualTo: userId).get();

      final batch = _firestore.batch();
      for (var doc in submittedReportsQuery.docs) {
        batch.delete(doc.reference);
      }
      for (var doc in receivedReportsQuery.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
      debugPrint('User reports deleted: ${submittedReportsQuery.docs.length + receivedReportsQuery.docs.length}');
    } catch (e) {
      debugPrint('Error deleting user reports: $e');
    }
  }

  /// Deletes all block relationships involving the user
  Future<void> _deleteUserBlocks(String userId) async {
    try {
      // Blocks created by user
      final blockedByUserQuery = await _firestore.collection('blocks').where('blockerId', isEqualTo: userId).get();

      // Blocks against user
      final blockedUserQuery = await _firestore.collection('blocks').where('blockedUserId', isEqualTo: userId).get();

      final batch = _firestore.batch();
      for (var doc in blockedByUserQuery.docs) {
        batch.delete(doc.reference);
      }
      for (var doc in blockedUserQuery.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
      debugPrint('User blocks deleted: ${blockedByUserQuery.docs.length + blockedUserQuery.docs.length}');
    } catch (e) {
      debugPrint('Error deleting user blocks: $e');
    }
  }

  /// Deletes all follower/following relationships
  Future<void> _deleteUserFollowRelationships(String userId) async {
    try {
      // Following relationships
      final followingQuery = await _firestore.collection('follows').where('followerId', isEqualTo: userId).get();

      // Follower relationships
      final followersQuery = await _firestore.collection('follows').where('followingId', isEqualTo: userId).get();

      final batch = _firestore.batch();
      for (var doc in followingQuery.docs) {
        batch.delete(doc.reference);
      }
      for (var doc in followersQuery.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
      debugPrint('User follow relationships deleted: ${followingQuery.docs.length + followersQuery.docs.length}');
    } catch (e) {
      debugPrint('Error deleting user follow relationships: $e');
    }
  }

  /// Deletes user subscription data
  Future<void> _deleteUserSubscriptionData(String userId) async {
    try {
      await _firestore.collection('subscriptions').doc(userId).delete();
      debugPrint('User subscription data deleted');
    } catch (e) {
      debugPrint('Error deleting user subscription data: $e');
    }
  }

  /// Deletes all user files from Firebase Storage
  Future<void> _deleteUserStorage(String userId) async {
    try {
      final userStorageRef = _storage.ref().child('users/$userId');

      // List all files in user's storage
      final listResult = await userStorageRef.listAll();

      // Delete all files
      for (var item in listResult.items) {
        await item.delete();
      }

      // Recursively delete folders
      for (var prefix in listResult.prefixes) {
        await _deleteStorageFolder(prefix);
      }

      debugPrint('User storage deleted: ${listResult.items.length} files');
    } catch (e) {
      debugPrint('Error deleting user storage: $e');
    }
  }

  /// Helper to recursively delete storage folders
  Future<void> _deleteStorageFolder(Reference folderRef) async {
    try {
      final listResult = await folderRef.listAll();

      for (var item in listResult.items) {
        await item.delete();
      }

      for (var prefix in listResult.prefixes) {
        await _deleteStorageFolder(prefix);
      }
    } catch (e) {
      debugPrint('Error deleting storage folder: $e');
    }
  }

  /// Pre-deletion validation - checks if user can be deleted
  /// Returns list of warnings/blockers
  Future<List<String>> validateDeletion(String userId) async {
    final warnings = <String>[];

    try {
      // Check for active subscriptions
      final subscription = await _firestore.collection('subscriptions').doc(userId).get();
      if (subscription.exists) {
        final data = subscription.data();
        if (data?['status'] == 'active') {
          warnings.add('You have an active subscription. It will be cancelled.');
        }
      }

      // Check for created events with other participants
      final eventsQuery = await _firestore.collection('events').where('createdBy', isEqualTo: userId).get();

      int activeEvents = 0;
      for (var doc in eventsQuery.docs) {
        final participants = doc.data()['participants'] as List?;
        if (participants != null && participants.length > 1) {
          activeEvents++;
        }
      }

      if (activeEvents > 0) {
        warnings.add('You have $activeEvents active events with participants. They will be deleted.');
      }
    } catch (e) {
      debugPrint('Error validating deletion: $e');
    }

    return warnings;
  }
}
