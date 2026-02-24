import 'package:cloud_firestore/cloud_firestore.dart';
import '../../shared/models/subscription.dart';

/// Service for managing user subscriptions and premium features
class SubscriptionService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Subscribe a user to a subscription package
  Future<void> subscribe({
    required String userId,
    required SubscriptionPackage package,
  }) async {
    try {
      await _firestore.runTransaction((transaction) async {
        // Check for existing active subscription
        final existingQuery = await _firestore
            .collection('subscriptions')
            .where('userId', isEqualTo: userId)
            .where('status',
                isEqualTo: SubscriptionStatus.active.toString().split('.').last)
            .limit(1)
            .get();

        if (existingQuery.docs.isNotEmpty) {
          throw Exception('User already has an active subscription');
        }

        final subscription = UserSubscription(
          id: '', // Will be set by Firestore
          userId: userId,
          tier: package.tier,
          startDate: DateTime.now(),
          endDate: _calculateEndDate(package.duration),
          status: SubscriptionStatus.active,
          autoRenew: true,
          price: package.price,
          paymentMethod: 'stripe', // Default payment method
        );

        final docRef = _firestore.collection('subscriptions').doc();
        transaction.set(docRef, subscription.toMap());
      });
    } catch (e) {
      throw Exception('Failed to subscribe: $e');
    }
  }

  /// Cancel a user's subscription
  Future<void> cancelSubscription(String subscriptionId) async {
    try {
      await _firestore.collection('subscriptions').doc(subscriptionId).update({
        'status': SubscriptionStatus.cancelled.toString().split('.').last,
        'autoRenew': false,
        'cancelledAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to cancel subscription: $e');
    }
  }

  /// Get a user's active subscription
  Future<UserSubscription?> getUserSubscription(String userId) async {
    final snapshot = await _firestore
        .collection('subscriptions')
        .where('userId', isEqualTo: userId)
        .where('status',
            isEqualTo: SubscriptionStatus.active.toString().split('.').last)
        .orderBy('startDate', descending: true)
        .limit(1)
        .get();

    if (snapshot.docs.isEmpty) return null;

    final doc = snapshot.docs.first;
    final data = doc.data();
    data['id'] = doc.id;
    return UserSubscription.fromMap(data);
  }

  /// Stream of user's subscription status
  Stream<UserSubscription?> getUserSubscriptionStream(String userId) {
    return _firestore
        .collection('subscriptions')
        .where('userId', isEqualTo: userId)
        .where('status',
            isEqualTo: SubscriptionStatus.active.toString().split('.').last)
        .orderBy('startDate', descending: true)
        .limit(1)
        .snapshots()
        .map((snapshot) {
      if (snapshot.docs.isEmpty) return null;

      final doc = snapshot.docs.first;
      final data = doc.data();
      data['id'] = doc.id;
      return UserSubscription.fromMap(data);
    });
  }

  /// Check if a user has an active subscription
  Future<bool> hasActiveSubscription(String userId) async {
    final subscription = await getUserSubscription(userId);
    return subscription != null &&
        subscription.status == SubscriptionStatus.active &&
        subscription.endDate.isAfter(DateTime.now());
  }

  /// Renew a subscription
  Future<void> renewSubscription(
      String subscriptionId, Duration duration) async {
    try {
      await _firestore.runTransaction((transaction) async {
        final docRef =
            _firestore.collection('subscriptions').doc(subscriptionId);
        final doc = await transaction.get(docRef);

        if (!doc.exists) {
          throw Exception('Subscription not found');
        }

        final subscription =
            UserSubscription.fromMap({...doc.data()!, 'id': doc.id});
        final newEndDate = subscription.endDate.add(duration);

        transaction.update(docRef, {
          'endDate': Timestamp.fromDate(newEndDate),
          'status': SubscriptionStatus.active.toString().split('.').last,
          'renewedAt': FieldValue.serverTimestamp(),
        });
      });
    } catch (e) {
      throw Exception('Failed to renew subscription: $e');
    }
  }

  /// Calculate end date based on subscription duration
  DateTime _calculateEndDate(SubscriptionDuration duration) {
    final now = DateTime.now();
    switch (duration) {
      case SubscriptionDuration.monthly:
        return DateTime(now.year, now.month + 1, now.day);
      case SubscriptionDuration.quarterly:
        return DateTime(now.year, now.month + 3, now.day);
      case SubscriptionDuration.yearly:
        return DateTime(now.year + 1, now.month, now.day);
    }
  }

  /// Get all available subscription packages
  Future<List<SubscriptionPackage>> getAvailablePackages() async {
    // In a real app, this would come from Firestore or a backend
    return [
      SubscriptionPackage(
        id: 'basic_monthly',
        tier: SubscriptionTier.basic,
        duration: SubscriptionDuration.monthly,
        price: 9.99,
        features: [
          'Ad-free experience',
          'Priority support',
          '10 free coins monthly',
        ],
      ),
      SubscriptionPackage(
        id: 'premium_monthly',
        tier: SubscriptionTier.premium,
        duration: SubscriptionDuration.monthly,
        price: 19.99,
        features: [
          'All Basic features',
          'Unlimited video calls',
          'Custom profile themes',
          '25 free coins monthly',
          'Exclusive badges',
        ],
      ),
      SubscriptionPackage(
        id: 'vip_monthly',
        tier: SubscriptionTier.vip,
        duration: SubscriptionDuration.monthly,
        price: 49.99,
        features: [
          'All Premium features',
          'VIP badge',
          'Priority room creation',
          'Custom emojis',
          '100 free coins monthly',
          'Early access to features',
        ],
      ),
    ];
  }
}
