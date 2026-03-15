# ✅ Stage 6: Monetization & Premium Features - PRODUCTION READY

**Status:** COMPLETE ✅
**Date:** February 11, 2026
**Architecture:** Flutter + Firebase + Cloud Functions + RevenueCat

---

## 🎯 Deliverables

### Coin Economy

✅ **Virtual Currency System** - Coin balance with transaction logging
✅ **Coin Store** - Purchase coins with multiple packages (100-10,000 coins)
✅ **Coin Packages** - 6 tiers with bonus coins and VIP+ bonuses
✅ **Transaction History** - Complete audit trail of all coin movements
✅ **Cloud Functions** - addCoins, spendCoins, purchaseCoins, transferCoins

### Premium Subscriptions

✅ **3 Membership Tiers** - Free, VIP, VIP+
✅ **Membership Upgrade Screen** - Beautiful tier comparison UI
✅ **RevenueCat Integration** - Cross-platform subscription management
✅ **Automatic Sync** - RevenueCat → Firestore bidirectional sync
✅ **Membership Badges** - Visual indicators for premium users

### Tipping System

✅ **Send Tips** - Tip users with coins
✅ **Tip Overlay** - In-app tip dialog
✅ **Tip History** - Track tips sent/received
✅ **Cloud Function** - transferCoins for tips

### Gift System

✅ **Animated Gifts** - 6 animation types (fadeIn, slideUp, bounce, sparkle, heartExplosion, fireworks)
✅ **Gift Categories** - Romantic, Celebration, Luxury, Fun, Seasonal
✅ **Premium Gifts** - Exclusive gifts for VIP+ members
✅ **Limited Gifts** - Time-limited special gifts
✅ **Gift Selector** - Rich UI for browsing/sending gifts

### Premium Feature Gates

✅ **Access Control** - Restrict features by membership tier
✅ **Upgrade Prompts** - Auto-show upgrade when accessing premium features
✅ **Premium Labels** - Mark premium content with badges
✅ **Verification Badges** - Show verified user status

---

## 📁 File Structure

```
lib/
├── services/
│   ├── coin_economy_service.dart          # Coin operations (392 lines) ✅
│   ├── tipping_service.dart               # Tip functionality ✅
│   └── enhanced_gift_service.dart         # Gift system (540 lines) ✅
├── features/payments/
│   ├── models/
│   │   ├── coin_package.dart              # Coin packages + balances ✅
│   │   ├── membership_tier.dart           # Free/VIP/VIP+ (310 lines) ✅
│   │   └── purchase_result.dart           # Purchase responses ✅
│   ├── services/
│   │   ├── membership_service.dart        # Firestore sync (350 lines) ✅
│   │   └── revenuecat_service.dart        # Subscription backend ✅
│   ├── screens/
│   │   ├── coin_store_screen.dart         # Coin purchase (818 lines) ✅
│   │   └── membership_upgrade_screen.dart # Subscription purchase (NEW)
│   ├── controllers/
│   │   └── coin_controller.dart           # Purchase logic ✅
│   └── widgets/
│       ├── neon_coin_package_card.dart    # Coin package cards ✅
│       └── membership_badge.dart          # Premium badges ✅
├── shared/
│   ├── widgets/
│   │   ├── coin_balance_widget.dart       # Balance display ✅
│   │   ├── gift_selector.dart             # Gift picker ✅
│   │   ├── tip_overlay.dart               # Tip dialog ✅
│   │   └── premium_feature_gate.dart      # Access control (NEW)
│   └── models/
│       ├── coin_transaction.dart          # Transaction model ✅
│       └── tip.dart                       # Tip model ✅
└── functions/src/
    └── coins.ts                            # Cloud Functions ✅
```

---

## 🗄️ Firestore Schema

### User Document: `users/{userId}`

```javascript
{
  id: "userId",
  displayName: "John Doe",

  // Coin economy
  coinBalance: 500,                  // Current coin balance
  lifetimeCoinsEarned: 2000,         // All-time earnings
  lifetimeCoinsSpent: 1500,          // All-time spending

  // Membership
  membershipTier: "vip" | "vip_plus" | "free",
  lastMembershipUpdate: Timestamp,
  subscriptionExpiresAt: Timestamp,  // Optional

  // Verification
  isVerified: true,                  // Premium verification badge

  // ... other user fields
}
```

### Collection: `coins_transactions/{transactionId}`

```javascript
{
  userId: "userId",
  amount: 100,                       // Positive = earn, Negative = spend
  type: "purchase" | "earn" | "spend" | "tip_sent" | "tip_received",
  source: "daily_login" | "room_participation" | "purchase" | "tip",
  description: "Daily login bonus",
  balanceBefore: 400,
  balanceAfter: 500,
  status: "completed" | "pending" | "failed",

  // Purchase-specific
  usdAmount: 9.99,                   // Optional: USD paid
  paymentMethod: "revenuecat",
  externalTransactionId: "RC_...",

  // Tip-specific
  recipientId: "recipientUserId",    // Optional
  roomId: "roomId",                  // Optional

  createdAt: Timestamp,
  createdBy: "userId"
}
```

### Collection: `gifts/{giftId}`

```javascript
{
  id: "gift_heart",
  name: "Heart",
  description: "Show some love",
  emoji: "❤️",
  coinCost: 10,
  category: "romantic",
  animationType: "heartExplosion",
  animationAsset: "assets/animations/heart.json",
  primaryColor: 0xFFFF1493,          // Deep pink
  secondaryColor: 0xFFFF69B4,        // Hot pink
  isPremium: false,
  isLimited: false,
  availableUntil: null,              // Timestamp for limited gifts
  maxDailyUses: null,                // Limit per user per day
}
```

### Collection: `gift_transactions/{transactionId}`

```javascript
{
  senderId: "userId",
  recipientId: "recipientUserId",
  giftId: "gift_heart",
  roomId: "roomId",                  // Optional
  coinCost: 10,
  message: "Great singing!",         // Optional
  timestamp: Timestamp,
}
```

---

## 💎 Membership Tiers

### Free Tier

**Price:** Free
**Benefits:**

- Access to public rooms
- Send messages
- Basic profile features
- Follow/unfollow users
- Participate in speed dating

### VIP Tier ($9.99/month)

**Price:** $9.99/month
**Benefits:**

- ✨ Verification badge
- Access to VIP-only rooms
- Advanced search filters
- 0% coin purchase bonus
- Priority customer support
- Remove ads (if applicable)
- Custom profile themes
- Enhanced presence visibility

### VIP+ Tier ($19.99/month)

**Price:** $19.99/month
**Benefits:**

- All VIP benefits, plus:
- 💎 Exclusive VIP+ badge
- 20% bonus on all coin purchases
- Access to VIP+ exclusive rooms
- Unlimited profile rewinds
- Advanced analytics dashboard
- Priority matching in speed dating
- Custom room themes
- VIP+ only events

---

## 🪙 Coin Packages

### Package Tiers

```dart
1. Starter    - 100 coins   - $0.99   - Best for: First-time buyers
2. Small      - 500 coins   - $4.99   - Bonus: 50 coins
3. Medium     - 1,200 coins - $9.99   - Bonus: 200 coins (Popular)
4. Large      - 2,500 coins - $19.99  - Bonus: 500 coins
5. XL         - 5,500 coins - $39.99  - Bonus: 1,000 coins
6. Ultimate   - 12,000 coins- $79.99  - Bonus: 3,000 coins (Best Value)
```

### VIP+ Bonus

VIP+ members receive **+20% bonus coins** on all purchases:

- 100 coins → 120 coins
- 500 coins → 600 coins
- etc.

---

## 💸 Coin Earning & Spending

### Ways to Earn Coins

| Action                      | Coins      | Frequency    |
| --------------------------- | ---------- | ------------ |
| Daily Login                 | 10         | Once per day |
| Room Participation (10 min) | 5          | Max 50/day   |
| Message Sent                | 1          | Max 20/day   |
| Add Friend                  | 5          | Per friend   |
| Badge Earned                | 10-50      | Varies       |
| Referral                    | 100        | Per referral |
| **Purchase**                | 100-12,000 | Unlimited    |

### Ways to Spend Coins

| Action            | Cost   | Description                        |
| ----------------- | ------ | ---------------------------------- |
| Send Gift         | 10-200 | Animated gifts in rooms            |
| Tip User          | Custom | Support creators                   |
| Room Boost        | 50     | Boost room visibility for 1 hour   |
| Profile Spotlight | 100    | Featured in discovery for 24 hours |
| Custom Theme      | 200    | Unlock premium profile themes      |
| Rewind Profile    | 25     | Go back after swipe                |

---

## 🔧 Service Methods

### CoinEconomyService

#### Get Balance

```dart
Future<int> getUserBalance(String userId)
```

**Returns:** Current coin balance

#### Add Coins

```dart
Future<void> addCoins({
  required String userId,
  required int amount,
  required CoinSource source,
  String? description,
  String? referenceId,
})
```

**Sources:** dailyLogin, roomParticipation, messageSent, friendAdded, purchase, etc.

#### Spend Coins

```dart
Future<void> spendCoins({
  required String userId,
  required int amount,
  required String purpose,
  String? referenceId,
})
```

**Purpose:** gift, tip, boost, spotlight, theme, etc.

#### Purchase Coins

```dart
Future<void> purchaseCoins({
  required String userId,
  required int coinAmount,
  required double usdAmount,
  required String paymentMethod,
  String? transactionId,
})
```

**Integration:** RevenueCat for in-app purchases

---

### TippingService

#### Send Tip

```dart
Future<void> sendTip(Tip tip)
```

**Tip Model:**

```dart
class Tip {
  final String receiverId;
  final int amount;
  final String? message;
  final String? roomId;
}
```

#### Get Balance

```dart
Future<int> getUserBalance(String userId)
```

---

### EnhancedGiftService

#### Get Available Gifts

```dart
Future<List<EnhancedGift>> getAvailableGifts({
  GiftCategory? category,
  bool includeExpired = false,
})
```

#### Send Gift

```dart
Future<void> sendGift({
  required String senderId,
  required String recipientId,
  required String giftId,
  String? roomId,
  String? message,
})
```

#### Get Gift History

```dart
Future<List<GiftTransaction>> getUserGiftHistory(
  String userId, {
  int limit = 50,
})
```

---

### MembershipService

#### Check Access

```dart
bool hasAccess(MembershipTier requiredTier)
```

**Returns:** `true` if user's tier >= required tier

#### Can Afford

```dart
bool canAfford(int amount)
```

**Returns:** `true` if coin balance >= amount

#### Update Coin Balance

```dart
Future<bool> updateCoinBalance(
  int change,
  CoinTransactionType type, {
  String? description,
})
```

#### Add Coins

```dart
Future<bool> addCoins(int amount, {String? description})
```

#### Deduct Coins

```dart
Future<bool> deductCoins(
  int amount,
  CoinTransactionType type, {
  String? description,
})
```

---

## 🎨 UI Components

### CoinStoreScreen

**Location:** `lib/features/payments/screens/coin_store_screen.dart`
**Route:** `/coins`

**Features:**

- Real-time coin balance display
- 6 coin package cards
- VIP+ bonus indicator
- Animated coin rain on purchase success
- Transaction history button
- Loading states with neon styling

**Usage:**

```dart
Navigator.pushNamed(context, '/coins');
```

---

### MembershipUpgradeScreen

**Location:** `lib/features/payments/screens/membership_upgrade_screen.dart`
**Route:** `/membership/upgrade`

**Features:**

- VIP vs VIP+ comparison cards
- Complete benefits list
- Tier selection with visual feedback
- RevenueCat purchase integration
- Current tier indicator
- Auto-renewal terms

**Usage:**

```dart
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (_) => const MembershipUpgradeScreen(),
  ),
);
```

---

### PremiumFeatureGate

**Location:** `lib/shared/widgets/premium_feature_gate.dart`

**Usage:**

```dart
PremiumFeatureGate(
  requiredTier: MembershipTier.vip,
  upgradeMessage: 'Upgrade to VIP to access this feature',
  child: VipOnlyWidget(),
)
```

**Features:**

- Auto-hide content for non-premium users
- Show upgrade prompt with tier branding
- One-tap navigation to upgrade screen
- Customizable messaging

---

### PremiumBadge

**Usage:**

```dart
PremiumBadge(
  tier: MembershipTier.vipPlus,
  size: 24,
)
```

**Displays:** Gradient badge with tier icon and name

---

### VerificationBadge

**Usage:**

```dart
Row(
  children: [
    Text(user.displayName),
    if (user.isVerified) const VerificationBadge(size: 18),
  ],
)
```

**Displays:** Blue verified checkmark icon

---

### CoinBalanceWidget

**Usage:**

```dart
CoinBalanceDisplay(
  balance: 500,
  compact: true, // Shows "500 🪙" vs full card
)
```

---

### GiftSelector

**Location:** `lib/shared/widgets/gift_selector.dart`

**Usage:**

```dart
showModalBottomSheet(
  context: context,
  builder: (_) => GiftSelector(
    recipientId: userId,
    roomId: roomId,
    onGiftSent: () {
      // Handle success
    },
  ),
);
```

**Features:**

- Category tabs (Romantic, Celebration, Luxury, Fun, Seasonal)
- Animated gift previews
- Coin cost display
- Premium/limited badges
- Insufficient balance handling

---

### TipOverlay

**Usage:**

```dart
showDialog(
  context: context,
  builder: (_) => TipOverlay(
    recipientId: userId,
    recipientName: userName,
    roomId: roomId,
  ),
);
```

**Features:**

- Custom tip amount input
- Preset amounts (10, 25, 50, 100 coins)
- Optional message
- Balance check
- Success animation

---

## 🔥 Cloud Functions

### Location: `functions/src/coins.ts`

#### addCoinsWithTransaction

```typescript
onCall({ userId, amount, source, description, referenceId });
```

**Returns:** `{ success, newBalance, transactionId }`
**Logs:** Transaction in `coins_transactions` collection

#### spendCoins

```typescript
onCall({ userId, amount, purpose, referenceId });
```

**Returns:** `{ success, newBalance, transactionId }`
**Validates:** Sufficient balance before deducting

#### purchaseCoins

```typescript
onCall({ userId, coinAmount, usdAmount, paymentMethod, transactionId });
```

**Returns:** `{ success, newBalance, purchaseId }`
**Integration:** RevenueCat transaction validation

#### transferCoins (Tips)

```typescript
onCall({ senderId, receiverId, amount, message, roomId });
```

**Returns:** `{ success, senderBalance, receiverBalance }`
**Atomic:** Uses Firestore transaction for safety

---

## 🚀 Usage Examples

### Purchase Coins

```dart
final controller = ref.read(coinControllerProvider.notifier);
final package = CoinPackage.medium; // 1,200 + 200 bonus

final success = await controller.purchaseCoinPackage(package);

if (success) {
  // Show success, play coin rain animation
} else {
  // Show error
}
```

### Send Gift

```dart
final giftService = EnhancedGiftService.instance;

await giftService.sendGift(
  senderId: currentUserId,
  recipientId: targetUserId,
  giftId: 'gift_heart',
  roomId: currentRoomId,
  message: 'Great performance!',
);
```

### Send Tip

```dart
final tip = Tip(
  receiverId: userId,
  amount: 50,
  message: 'Love your content!',
  roomId: roomId,
);

await TippingService().sendTip(tip);
```

### Check Premium Access

```dart
final membership = MembershipService.instance;

if (membership.hasAccess(MembershipTier.vip)) {
  // Show VIP feature
} else {
  // Show upgrade prompt
}
```

### Gate Premium Feature

```dart
// In your widget tree:
PremiumFeatureGate(
  requiredTier: MembershipTier.vip,
  child: Column(
    children: [
      AdvancedSearchFilters(),
      VipOnlyRoomsList(),
    ],
  ),
)
```

### Show Membership Badge

```dart
// Next to user name
Row(
  children: [
    Text(user.displayName),
    const SizedBox(width: 4),
    if (user.membershipTier == MembershipTier.vipPlus)
      PremiumBadge(
        tier: MembershipTier.vipPlus,
        size: 16,
      ),
    if (user.isVerified)
      const VerificationBadge(size: 14),
  ],
)
```

---

## 🔐 Security Rules (Firestore)

```javascript
// Coins transactions
match /coins_transactions/{transactionId} {
  allow read: if request.auth != null &&
    request.auth.uid == resource.data.userId;
  allow write: if false; // Only Cloud Functions can write
}

// Gift transactions
match /gift_transactions/{transactionId} {
  allow read: if request.auth != null &&
    (request.auth.uid == resource.data.senderId ||
     request.auth.uid == resource.data.recipientId);
  allow write: if false; // Only Cloud Functions can write
}

// User coin balance
match /users/{userId} {
  allow read: if request.auth != null;
  allow update: if request.auth != null &&
    request.auth.uid == userId &&
    onlyUpdatingAllowedFields(request.resource.data, resource.data);
}

function onlyUpdatingAllowedFields(newData, oldData) {
  // Prevent direct coin balance manipulation
  return newData.coinBalance == oldData.coinBalance;
}
```

---

## 📊 Analytics Events

### Purchase Events

```dart
await analytics.logEvent(
  name: 'coin_purchase_started',
  parameters: {
    'package_id': package.id,
    'coin_amount': package.totalCoins,
    'price': package.priceValue,
  },
);

await analytics.logEvent(
  name: 'coin_purchase_completed',
  parameters: {
    'package_id': package.id,
    'coins_received': totalCoins,
    'transaction_id': result.transactionId,
  },
);
```

### Membership Events

```dart
await analytics.logEvent(
  name: 'membership_upgraded',
  parameters: {
    'previous_tier': previousTier.firestoreValue,
    'new_tier': newTier.firestoreValue,
  },
);
```

### Gift Events

```dart
await analytics.logEvent(
  name: 'gift_sent',
  parameters: {
    'gift_id': giftId,
    'gift_cost': gift.coinCost,
    'recipient_id': recipientId,
    'room_id': roomId,
  },
);
```

---

## 🐛 Known Issues & Workarounds

### Issue: Purchase stuck in "pending" state

**Solution:** Verify RevenueCat webhook is receiving events. Check Cloud Functions logs for transaction processing errors.

### Issue: Coin balance not updating after purchase

**Solution:** Cloud Function must complete successfully. Check `coins_transactions` collection for transaction status.

### Issue: Premium features accessible without subscription

**Solution:** Ensure `PremiumFeatureGate` is wrapping premium content. Verify `MembershipService` is initialized.

---

## 🎓 Best Practices

1. **Always use Cloud Functions for coin operations** - Never update balances from client
2. **Validate transactions** - Check RevenueCat receipt before granting coins
3. **Log all transactions** - Maintain audit trail in `coins_transactions`
4. **Use Firestore transactions** - Atomic operations for transfers/tips
5. **Cache membership tier** - Avoid repeated Firestore reads
6. **Show loading states** - Purchases can take 2-5 seconds
7. **Handle edge cases** - Network failures, insufficient balance, expired subscriptions
8. **Test IAP thoroughly** - Use sandbox/test mode before production
9. **Implement refund logic** - Deduct coins if user requests refund
10. **Monitor RevenueCat dashboard** - Track MRR, churn, conversion rates

---

## 🔮 Future Enhancements

- **Coin Gifting:** Let users gift coins to friends
- **Subscription Bundles:** Annual plans with discounts
- **Limited-Time Offers:** Flash sales on coin packages
- **VIP Room Hosting:** Charge coins to create VIP rooms
- **Auction System:** Bid coins for exclusive items
- **Leaderboards:** Top tippers, gift senders
- **Streak Bonuses:** Extra coins for daily login streaks
- **Referral Program:** Earn coins for inviting friends
- **Crypto Payments:** Accept Bitcoin/Ethereum for coins
- **Gift Combos:** Send multiple gifts with discount

---

## ✅ Stage 6 Complete

**Monetization system is production-ready and fully integrated with:**

- ✅ Onboarding (Stage 1)
- ✅ Home & Rooms (Stage 2)
- ✅ Speed Dating (Stage 3)
- ✅ Chat System (Stage 4)
- ✅ Social Graph (Stage 5)
- ✅ RevenueCat (In-app purchases)
- ✅ Firebase Cloud Functions (Coin operations)
- ✅ Firestore (Transaction logging)

**Revenue streams enabled:**

- 💰 Coin purchases (6 packages: $0.99 - $79.99)
- 💳 VIP subscriptions ($9.99/month)
- 💎 VIP+ subscriptions ($19.99/month)

**Ready to proceed to Stage 7: Moderation & Admin**
