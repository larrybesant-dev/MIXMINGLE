// lib/services/monetization_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../shared/models/subscription_plan_model.dart';
import '../shared/models/entitlement_model.dart';

class MonetizationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  final List<SubscriptionPlanModel> plans = [
    SubscriptionPlanModel(id: 'free', name: 'Free', price: 0.0, features: ['Basic Rooms']),
    SubscriptionPlanModel(id: 'premium', name: 'Premium', price: 9.99, features: ['Screen Share', 'Reactions', 'Breakout Rooms']),
  ];

  EntitlementModel getUserEntitlement(String userId) {
    // Placeholder: everyone is free by default
    return EntitlementModel(userId: userId, entitlements: ['Basic Rooms']);
  }

  /// Submit a withdrawal request for the currently authenticated user.
  /// Validates identity server-side via Firestore rules (userId must match auth.uid).
  Future<void> submitWithdrawal({required int amount, required String email}) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Not authenticated');
    if (amount <= 0) throw Exception('Amount must be greater than zero');

    await _firestore.collection('withdrawals').add({
      'userId': user.uid,
      'amount': amount,
      'email': email,
      'status': 'pending',
      'createdAt': FieldValue.serverTimestamp(),
    });
  }
}
