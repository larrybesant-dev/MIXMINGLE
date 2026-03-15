# Payments Feature - Integration Guide

## Overview

The payments feature provides:

- **Membership Tiers**: Free, VIP ($9.99/mo), VIP+ ($19.99/mo)
- **Coin Economy**: 4 packages (100, 500, 1000, 5000 coins)
- **RevenueCat Integration**: Subscriptions and consumables
- **Firestore Sync**: Membership and coin balance persistence
- **Neon VIP Lounge Aesthetic**: Animated cards, gold trim, spotlight effects

## File Structure

```
lib/features/payments/
├── payments.dart              # Barrel exports
├── models/
│   ├── membership_tier.dart   # MembershipTier enum, TierBenefit, TierPricing
│   └── coin_package.dart      # CoinPackage, CoinBalance, CoinTransaction
├── services/
│   ├── revenuecat_service.dart  # RevenueCat SDK wrapper
│   └── membership_service.dart  # Firestore sync service
├── controllers/
│   └── coin_controller.dart   # Riverpod state management
├── widgets/
│   ├── membership_badge.dart  # Badge widgets for profile/chat
│   ├── neon_tier_card.dart    # Animated tier selection cards
│   └── neon_coin_package_card.dart # Coin package selection cards
└── screens/
    ├── paywall_screen.dart    # Membership upgrade paywall
    └── coin_store_screen.dart # Coin purchase store
```

## Integration Steps

### 1. Initialize Services (main.dart or app startup)

```dart
import 'package:mix_and_mingle/features/payments/payments.dart';

// In your app initialization:
Future<void> initializePayments(String userId) async {
  // Initialize membership service (also initializes RevenueCat)
  await MembershipService.instance.initialize(userId);
}
```

### 2. Add RevenueCat API Keys (revenuecat_service.dart)

Update the `RevenueCatConfig` class with your actual API keys:

```dart
class RevenueCatConfig {
  static const String googleApiKey = 'YOUR_GOOGLE_API_KEY';
  static const String appleApiKey = 'YOUR_APPLE_API_KEY';
  // ...
}
```

### 3. Show Paywall

```dart
import 'package:mix_and_mingle/features/payments/payments.dart';

// In any widget:
ElevatedButton(
  onPressed: () => showPaywall(context, source: 'profile'),
  child: Text('Upgrade to VIP'),
);
```

### 4. Show Coin Store

```dart
import 'package:mix_and_mingle/features/payments/payments.dart';

// In any widget:
ElevatedButton(
  onPressed: () => showCoinStore(context),
  child: Text('Get Coins'),
);
```

### 5. Display Membership Badge

```dart
import 'package:mix_and_mingle/features/payments/payments.dart';

// In profile or chat:
MembershipBadge(
  tier: MembershipTier.vip,
  size: MembershipBadgeSize.medium,
  showLabel: true,
  animated: true,
);

// Compact version for chat:
CompactMembershipBadge(tier: user.membershipTier);

// Upgrade button:
UpgradeBadge(onTap: () => showPaywall(context));
```

### 6. Display Coin Balance

```dart
import 'package:mix_and_mingle/features/payments/payments.dart';

// In app header:
Consumer(
  builder: (context, ref, _) {
    final balance = ref.watch(currentCoinBalanceProvider);
    return CoinBalanceDisplay(
      balance: balance,
      compact: true,
      onTap: () => showCoinStore(context),
    );
  },
);
```

### 7. Check Access in Rooms

```dart
import 'package:mix_and_mingle/features/payments/payments.dart';

// Before joining VIP room:
if (!MembershipService.instance.canJoinVipRooms) {
  await MembershipService.instance.logVipRoomBlocked();
  showPaywall(context, source: 'vip_room');
  return;
}
```

### 8. Use Coins (Gifts, Spotlight)

```dart
import 'package:mix_and_mingle/features/payments/payments.dart';

// Check affordability:
if (!ref.canAfford(50)) {
  showCoinStore(context);
  return;
}

// Send gift:
final success = await ref.sendGift(50, recipientUserId);

// Activate spotlight:
final success = await ref.activateSpotlight(100);
```

## Firestore Schema

### User Document Fields

```json
{
  "membershipTier": "free" | "vip" | "vip_plus",
  "coinBalance": 0,
  "lastMembershipUpdate": Timestamp
}
```

### Coin Transactions Subcollection

```
users/{userId}/coinTransactions/{transactionId}
```

```json
{
  "type": "purchase" | "bonus" | "gift_sent" | "gift_received" | "spotlight" | "refund" | "other",
  "amount": 100,
  "description": "Purchased Popular Pack",
  "balanceAfter": 650,
  "timestamp": Timestamp
}
```

## RevenueCat Product IDs

### Subscriptions

- `vip_monthly` - VIP Monthly ($9.99)
- `vip_yearly` - VIP Yearly ($79.99)
- `vip_plus_monthly` - VIP+ Monthly ($19.99)
- `vip_plus_yearly` - VIP+ Yearly ($149.99)

### Consumables (Coins)

- `coins_100` - 100 coins ($0.99)
- `coins_500` - 500 coins + 50 bonus ($4.99)
- `coins_1000` - 1000 coins + 150 bonus ($9.99)
- `coins_5000` - 5000 coins + 1000 bonus ($39.99)

### Entitlements

- `vip` - VIP tier access
- `vip_plus` - VIP+ tier access

## Analytics Events

| Event                       | Parameters                     |
| --------------------------- | ------------------------------ |
| `paywall_viewed`            | `current_tier`                 |
| `membership_upgraded`       | `previous_tier`, `new_tier`    |
| `membership_downgraded`     | `previous_tier`, `new_tier`    |
| `coin_purchase_started`     | `package_id`, `coins`, `price` |
| `coin_purchase_completed`   | `package_id`, `coins`, `price` |
| `coin_purchase_failed`      | `package_id`, `error`          |
| `vip_room_attempt_blocked`  | `current_tier`                 |
| `spotlight_attempt_blocked` | `current_tier`                 |

## Design Tokens

The feature uses the existing design system from `lib/core/design_system/design_constants.dart`:

- **Background**: `DesignColors.background` (#080C14)
- **Gold**: `DesignColors.gold` (#FFD700)
- **Accent Blue**: `DesignColors.accent` (#4A90FF)
- **Secondary Orange**: `DesignColors.secondary` (#FF6B35)

And neon colors from `lib/core/theme/neon_colors.dart`:

- **Neon Orange**: `NeonColors.neonOrange` (#FF7A3C)
- **Neon Blue**: `NeonColors.neonBlue` (#00D9FF)
- **Success Green**: `NeonColors.successGreen` (#00FF88)
- **Error Red**: `NeonColors.errorRed` (#FF1744)

## Development Mode

The `RevenueCatService` includes simulated data for development. Set `_useSimulatedData` to `false` and enable the production code blocks when ready to test with actual RevenueCat.

## Next Steps

1. Create RevenueCat project at https://www.revenuecat.com
2. Add products in App Store Connect / Google Play Console
3. Configure products in RevenueCat dashboard
4. Update API keys in `revenuecat_service.dart`
5. Test purchase flows on physical devices
