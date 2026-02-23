/// RevenueCat Service - Stub for compilation
/// TODO: Implement full RevenueCat integration
library;

import '../features/payments/models/membership_tier.dart';

class RevenueCatService {
  static final RevenueCatService _instance = RevenueCatService._internal();
  factory RevenueCatService() => _instance;
  RevenueCatService._internal();

  /// Initialize RevenueCat SDK
  Future<void> init() async {
    // TODO: Initialize RevenueCat with API key
  }

  /// Purchase a membership tier
  Future<void> purchaseMembership(MembershipTier tier) async {
    // DEV STUB â€” monetization disabled
    // TODO: Implement RevenueCat purchase flow when ready
    return;
  }

  /// Restore purchases
  Future<void> restorePurchases() async {
    // TODO: Implement restore purchases
  }

  /// Get current entitlements
  Future<List<String>> getEntitlements() async {
    // TODO: Fetch active entitlements from RevenueCat
    return [];
  }
}


