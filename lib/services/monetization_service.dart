// lib/services/monetization_service.dart

import '../models/subscription_plan_model.dart';
import '../models/entitlement_model.dart';

class MonetizationService {
  final List<SubscriptionPlanModel> plans = [
    SubscriptionPlanModel(id: 'free', name: 'Free', price: 0.0, features: ['Basic Rooms']),
    SubscriptionPlanModel(id: 'premium', name: 'Premium', price: 9.99, features: ['Screen Share', 'Reactions', 'Breakout Rooms']),
  ];

  EntitlementModel getUserEntitlement(String userId) {
    // Placeholder: everyone is free by default
    return EntitlementModel(userId: userId, entitlements: ['Basic Rooms']);
  }
}
