import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

const int kProfileBoostCoinCost = 100;
const int kRoomBoostCoinCost = 200;
const int kProfileBoostHours = 24;
const int kRoomBoostHours = 12;

class BoostService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ---------------------------------------------------------------------------
  // Profile boost
  // ---------------------------------------------------------------------------

  /// Spend [kProfileBoostCoinCost] coins to boost the current user's profile
  /// discovery ranking for [kProfileBoostHours] hours.
  Future<void> boostProfile(String userId) async {
    final snap = await _firestore.collection('users').doc(userId).get();
    final balance = (snap.data()?['coinBalance'] as num?)?.toInt() ?? 0;
    if (balance < kProfileBoostCoinCost) {
      throw Exception(
          'Need $kProfileBoostCoinCost coins to boost your profile. You have $balance.');
    }
    final expiry =
        DateTime.now().add(const Duration(hours: kProfileBoostHours));
    await _firestore.collection('users').doc(userId).update({
      'coinBalance': FieldValue.increment(-kProfileBoostCoinCost),
      'profileBoostExpiry': Timestamp.fromDate(expiry),
      'boostScore': FieldValue.increment(100),
    });
    debugPrint('BoostService: profile boosted until $expiry');
  }

  /// Whether [userId]'s profile boost is currently active.
  Future<bool> isProfileBoosted(String userId) async {
    try {
      final snap = await _firestore.collection('users').doc(userId).get();
      final expiry =
          (snap.data()?['profileBoostExpiry'] as Timestamp?)?.toDate();
      return expiry != null && expiry.isAfter(DateTime.now());
    } catch (_) {
      return false;
    }
  }

  /// Streams whether [userId]'s profile boost is active.
  Stream<bool> profileBoostStream(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .snapshots()
        .map((snap) {
      final expiry =
          (snap.data()?['profileBoostExpiry'] as Timestamp?)?.toDate();
      return expiry != null && expiry.isAfter(DateTime.now());
    });
  }

  // ---------------------------------------------------------------------------
  // Room boost
  // ---------------------------------------------------------------------------

  /// Spend [kRoomBoostCoinCost] coins (from [userId]) to push [roomId] to
  /// the top of the trending feed for [kRoomBoostHours] hours.
  Future<void> boostRoom(String userId, String roomId) async {
    final snap = await _firestore.collection('users').doc(userId).get();
    final balance = (snap.data()?['coinBalance'] as num?)?.toInt() ?? 0;
    if (balance < kRoomBoostCoinCost) {
      throw Exception(
          'Need $kRoomBoostCoinCost coins to boost your room. You have $balance.');
    }
    final expiry =
        DateTime.now().add(const Duration(hours: kRoomBoostHours));
    final batch = _firestore.batch();
    batch.update(_firestore.collection('users').doc(userId), {
      'coinBalance': FieldValue.increment(-kRoomBoostCoinCost),
    });
    batch.update(_firestore.collection('rooms').doc(roomId), {
      'isBoosted': true,
      'boostExpiry': Timestamp.fromDate(expiry),
      'boostScore': FieldValue.increment(500),
    });
    await batch.commit();
  }

  /// Streams whether [roomId]'s boost is currently active.
  Stream<bool> roomBoostStream(String roomId) {
    return _firestore
        .collection('rooms')
        .doc(roomId)
        .snapshots()
        .map((snap) {
      final isBoosted = snap.data()?['isBoosted'] as bool? ?? false;
      if (!isBoosted) return false;
      final expiry =
          (snap.data()?['boostExpiry'] as Timestamp?)?.toDate();
      return expiry != null && expiry.isAfter(DateTime.now());
    });
  }

  // ---------------------------------------------------------------------------
  // Premium flag
  // ---------------------------------------------------------------------------

  /// Check whether [userId] has an active premium subscription stored on the
  /// user document (set by the backend / admin).
  Stream<bool> isPremiumStream(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .snapshots()
        .map((snap) {
      final isPremium = snap.data()?['isPremium'] as bool? ?? false;
      if (!isPremium) return false;
      final expiry =
          (snap.data()?['premiumExpiry'] as Timestamp?)?.toDate();
      // No expiry → lifetime grant; otherwise check date.
      return expiry == null || expiry.isAfter(DateTime.now());
    });
  }
}
