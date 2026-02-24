/// RevenueCat Service
///
/// Handles all RevenueCat integration for subscriptions and consumables.
/// Manages offerings, purchases, entitlements, and restore flow.
library;

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../models/membership_tier.dart';
import '../models/coin_package.dart';

/// RevenueCat configuration
class RevenueCatConfig {
  /// API keys for RevenueCat
  static const String androidApiKey = 'YOUR_ANDROID_API_KEY';
  static const String iosApiKey = 'YOUR_IOS_API_KEY';

  /// Entitlement identifiers
  static const String vipEntitlement = 'vip';
  static const String vipPlusEntitlement = 'vip_plus';

  /// Product identifiers
  static const String vipMonthly = 'vip_monthly';
  static const String vipYearly = 'vip_yearly';
  static const String vipPlusMonthly = 'vip_plus_monthly';
  static const String vipPlusYearly = 'vip_plus_yearly';

  /// Coin product identifiers
  static const String coins100 = 'coins_100';
  static const String coins500 = 'coins_500';
  static const String coins1000 = 'coins_1000';
  static const String coins5000 = 'coins_5000';
}

/// Result of a purchase operation
class PurchaseResult {
  final bool success;
  final String? errorMessage;
  final MembershipTier? newTier;
  final int? coinsAdded;
  final String? productId;

  const PurchaseResult({
    required this.success,
    this.errorMessage,
    this.newTier,
    this.coinsAdded,
    this.productId,
  });

  factory PurchaseResult.success({
    MembershipTier? tier,
    int? coins,
    String? productId,
  }) =>
      PurchaseResult(
        success: true,
        newTier: tier,
        coinsAdded: coins,
        productId: productId,
      );

  factory PurchaseResult.failure(String message) => PurchaseResult(
        success: false,
        errorMessage: message,
      );

  factory PurchaseResult.cancelled() => const PurchaseResult(
        success: false,
        errorMessage: 'Purchase cancelled',
      );
}

/// Offering data from RevenueCat
class StoreOffering {
  final String identifier;
  final List<StoreProduct> products;
  final StoreProduct? monthlyProduct;
  final StoreProduct? annualProduct;

  const StoreOffering({
    required this.identifier,
    required this.products,
    this.monthlyProduct,
    this.annualProduct,
  });
}

/// Product data from RevenueCat
class StoreProduct {
  final String identifier;
  final String title;
  final String description;
  final String priceString;
  final double price;
  final String currencyCode;
  final ProductType type;

  const StoreProduct({
    required this.identifier,
    required this.title,
    required this.description,
    required this.priceString,
    required this.price,
    required this.currencyCode,
    required this.type,
  });
}

/// Product type
enum ProductType {
  subscription,
  consumable,
}

/// RevenueCat service for handling all purchases
class RevenueCatService extends ChangeNotifier {
  static RevenueCatService? _instance;
  static RevenueCatService get instance => _instance ??= RevenueCatService._();

  RevenueCatService._();

  bool _isInitialized = false;
  bool _isLoading = false;
  MembershipTier _currentTier = MembershipTier.free;
  List<StoreOffering> _offerings = [];
  String? _errorMessage;
  StreamController<MembershipTier>? _tierStreamController;

  // Getters
  bool get isInitialized => _isInitialized;
  bool get isLoading => _isLoading;
  MembershipTier get currentTier => _currentTier;
  List<StoreOffering> get offerings => _offerings;
  String? get errorMessage => _errorMessage;

  /// Stream of membership tier changes
  Stream<MembershipTier> get tierStream {
    _tierStreamController ??= StreamController<MembershipTier>.broadcast();
    return _tierStreamController!.stream;
  }

  /// Initialize RevenueCat
  Future<void> initialize(String userId) async {
    if (_isInitialized) return;

    try {
      _isLoading = true;
      notifyListeners();

      debugPrint('ðŸ›’ [RevenueCat] Initializing...');

      // In production, you would initialize RevenueCat here:
      // await Purchases.setDebugLogsEnabled(kDebugMode);
      // PurchasesConfiguration configuration;
      // if (Platform.isAndroid) {
      //   configuration = PurchasesConfiguration(RevenueCatConfig.androidApiKey);
      // } else if (Platform.isIOS) {
      //   configuration = PurchasesConfiguration(RevenueCatConfig.iosApiKey);
      // }
      // await Purchases.configure(configuration);
      // await Purchases.logIn(userId);

      // Simulated initialization for development
      await Future.delayed(const Duration(milliseconds: 500));

      await _fetchOfferings();
      await _checkEntitlements();

      _isInitialized = true;
      debugPrint('âœ… [RevenueCat] Initialized successfully');
    } catch (e) {
      _errorMessage = 'Failed to initialize purchases: $e';
      debugPrint('âŒ [RevenueCat] Init error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Fetch available offerings
  Future<void> _fetchOfferings() async {
    try {
      debugPrint('ðŸ“¦ [RevenueCat] Fetching offerings...');

      // In production:
      // final offerings = await Purchases.getOfferings();
      // _offerings = offerings.all.values.map((o) => StoreOffering(...)).toList();

      // Simulated offerings for development
      _offerings = [
        const StoreOffering(
          identifier: 'vip',
          products: [
            StoreProduct(
              identifier: RevenueCatConfig.vipMonthly,
              title: 'VIP Monthly',
              description: 'VIP membership billed monthly',
              priceString: '\$9.99',
              price: 9.99,
              currencyCode: 'USD',
              type: ProductType.subscription,
            ),
            StoreProduct(
              identifier: RevenueCatConfig.vipYearly,
              title: 'VIP Yearly',
              description: 'VIP membership billed yearly',
              priceString: '\$79.99',
              price: 79.99,
              currencyCode: 'USD',
              type: ProductType.subscription,
            ),
          ],
          monthlyProduct: StoreProduct(
            identifier: RevenueCatConfig.vipMonthly,
            title: 'VIP Monthly',
            description: 'VIP membership billed monthly',
            priceString: '\$9.99',
            price: 9.99,
            currencyCode: 'USD',
            type: ProductType.subscription,
          ),
          annualProduct: StoreProduct(
            identifier: RevenueCatConfig.vipYearly,
            title: 'VIP Yearly',
            description: 'VIP membership billed yearly',
            priceString: '\$79.99',
            price: 79.99,
            currencyCode: 'USD',
            type: ProductType.subscription,
          ),
        ),
        const StoreOffering(
          identifier: 'vip_plus',
          products: [
            StoreProduct(
              identifier: RevenueCatConfig.vipPlusMonthly,
              title: 'VIP+ Monthly',
              description: 'VIP+ membership billed monthly',
              priceString: '\$19.99',
              price: 19.99,
              currencyCode: 'USD',
              type: ProductType.subscription,
            ),
            StoreProduct(
              identifier: RevenueCatConfig.vipPlusYearly,
              title: 'VIP+ Yearly',
              description: 'VIP+ membership billed yearly',
              priceString: '\$149.99',
              price: 149.99,
              currencyCode: 'USD',
              type: ProductType.subscription,
            ),
          ],
          monthlyProduct: StoreProduct(
            identifier: RevenueCatConfig.vipPlusMonthly,
            title: 'VIP+ Monthly',
            description: 'VIP+ membership billed monthly',
            priceString: '\$19.99',
            price: 19.99,
            currencyCode: 'USD',
            type: ProductType.subscription,
          ),
          annualProduct: StoreProduct(
            identifier: RevenueCatConfig.vipPlusYearly,
            title: 'VIP+ Yearly',
            description: 'VIP+ membership billed yearly',
            priceString: '\$149.99',
            price: 149.99,
            currencyCode: 'USD',
            type: ProductType.subscription,
          ),
        ),
        const StoreOffering(
          identifier: 'coins',
          products: [
            StoreProduct(
              identifier: RevenueCatConfig.coins100,
              title: '100 Coins',
              description: '100 coins for gifts',
              priceString: '\$0.99',
              price: 0.99,
              currencyCode: 'USD',
              type: ProductType.consumable,
            ),
            StoreProduct(
              identifier: RevenueCatConfig.coins500,
              title: '550 Coins',
              description: '500 coins + 50 bonus',
              priceString: '\$4.99',
              price: 4.99,
              currencyCode: 'USD',
              type: ProductType.consumable,
            ),
            StoreProduct(
              identifier: RevenueCatConfig.coins1000,
              title: '1150 Coins',
              description: '1000 coins + 150 bonus',
              priceString: '\$9.99',
              price: 9.99,
              currencyCode: 'USD',
              type: ProductType.consumable,
            ),
            StoreProduct(
              identifier: RevenueCatConfig.coins5000,
              title: '6000 Coins',
              description: '5000 coins + 1000 bonus',
              priceString: '\$39.99',
              price: 39.99,
              currencyCode: 'USD',
              type: ProductType.consumable,
            ),
          ],
        ),
      ];

      debugPrint('âœ… [RevenueCat] Fetched ${_offerings.length} offerings');
    } catch (e) {
      debugPrint('âŒ [RevenueCat] Failed to fetch offerings: $e');
      _errorMessage = 'Failed to load store products';
    }
  }

  /// Check current entitlements
  Future<void> _checkEntitlements() async {
    try {
      debugPrint('ðŸ” [RevenueCat] Checking entitlements...');

      // In production:
      // final customerInfo = await Purchases.getCustomerInfo();
      // if (customerInfo.entitlements.active.containsKey(RevenueCatConfig.vipPlusEntitlement)) {
      //   _currentTier = MembershipTier.vipPlus;
      // } else if (customerInfo.entitlements.active.containsKey(RevenueCatConfig.vipEntitlement)) {
      //   _currentTier = MembershipTier.vip;
      // } else {
      //   _currentTier = MembershipTier.free;
      // }

      // Simulated entitlement check for development
      _currentTier = MembershipTier.free;

      _tierStreamController?.add(_currentTier);
      debugPrint('âœ… [RevenueCat] Current tier: ${_currentTier.displayName}');
    } catch (e) {
      debugPrint('âŒ [RevenueCat] Failed to check entitlements: $e');
    }
  }

  /// Purchase membership by tier (stub wrapper for purchaseSubscription)
  Future<PurchaseResult> purchaseMembership(MembershipTier tier) async {
    // DEV STUB - Map tier to product ID
    final productId = tier == MembershipTier.vipPlus
        ? RevenueCatConfig.vipPlusMonthly
        : RevenueCatConfig.vipMonthly;
    return purchaseSubscription(productId);
  }

  /// Purchase a subscription
  Future<PurchaseResult> purchaseSubscription(String productId) async {
    try {
      _isLoading = true;
      notifyListeners();

      debugPrint('ðŸ’³ [RevenueCat] Purchasing subscription: $productId');

      // In production:
      // final customerInfo = await Purchases.purchaseProduct(productId);
      // Check entitlements and return result

      // Simulated purchase for development
      await Future.delayed(const Duration(seconds: 2));

      MembershipTier newTier = MembershipTier.free;
      if (productId.contains('vip_plus')) {
        newTier = MembershipTier.vipPlus;
      } else if (productId.contains('vip')) {
        newTier = MembershipTier.vip;
      }

      _currentTier = newTier;
      _tierStreamController?.add(_currentTier);
      notifyListeners();

      debugPrint('âœ… [RevenueCat] Purchase successful: ${newTier.displayName}');
      return PurchaseResult.success(tier: newTier, productId: productId);
    } catch (e) {
      debugPrint('âŒ [RevenueCat] Purchase failed: $e');
      return PurchaseResult.failure('Purchase failed: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Purchase coins (consumable)
  Future<PurchaseResult> purchaseCoins(CoinPackage package) async {
    try {
      _isLoading = true;
      notifyListeners();

      debugPrint('ðŸ’³ [RevenueCat] Purchasing coins: ${package.productId}');

      // In production:
      // await Purchases.purchaseProduct(package.productId);

      // Simulated purchase for development
      await Future.delayed(const Duration(seconds: 2));

      final totalCoins = package.getTotalCoinsForTier(_currentTier);

      debugPrint('âœ… [RevenueCat] Coins purchased: $totalCoins');
      return PurchaseResult.success(
        coins: totalCoins,
        productId: package.productId,
      );
    } catch (e) {
      debugPrint('âŒ [RevenueCat] Coin purchase failed: $e');
      return PurchaseResult.failure('Purchase failed: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Restore purchases
  Future<PurchaseResult> restorePurchases() async {
    try {
      _isLoading = true;
      notifyListeners();

      debugPrint('â™»ï¸ [RevenueCat] Restoring purchases...');

      // In production:
      // final customerInfo = await Purchases.restorePurchases();
      // Check entitlements and update tier

      // Simulated restore for development
      await Future.delayed(const Duration(seconds: 2));
      await _checkEntitlements();

      debugPrint('âœ… [RevenueCat] Purchases restored');
      return PurchaseResult.success(tier: _currentTier);
    } catch (e) {
      debugPrint('âŒ [RevenueCat] Restore failed: $e');
      return PurchaseResult.failure('Restore failed: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Get offerings for a specific tier
  StoreOffering? getOfferingForTier(MembershipTier tier) {
    final identifier = tier == MembershipTier.vipPlus ? 'vip_plus' : 'vip';
    return _offerings.where((o) => o.identifier == identifier).firstOrNull;
  }

  /// Get coin offerings
  StoreOffering? getCoinOffering() {
    return _offerings.where((o) => o.identifier == 'coins').firstOrNull;
  }

  /// Log out (call when user logs out)
  Future<void> logOut() async {
    try {
      debugPrint('ðŸ‘‹ [RevenueCat] Logging out...');
      // In production: await Purchases.logOut();
      _currentTier = MembershipTier.free;
      _tierStreamController?.add(_currentTier);
      notifyListeners();
    } catch (e) {
      debugPrint('âŒ [RevenueCat] Logout error: $e');
    }
  }

  @override
  void dispose() {
    _tierStreamController?.close();
    super.dispose();
  }
}
