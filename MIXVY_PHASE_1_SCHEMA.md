# MixVy Phase 1 Schema Foundation

This document defines additive schema groundwork only. Nothing here is intended to replace the current auth, profile, room, or payment flows yet.

## Central Config

- `lib/config/mixvy_economy_config.dart`
- Holds referral percentages, payout windows, wallet fees, and default currency in one place.

## New Typed Models

- `lib/models/adult_profile_model.dart`
- `lib/models/wallet_model.dart`
- `lib/models/referral_model.dart`
- `lib/models/room_policy_model.dart`
- `lib/models/moderation_model.dart`

## Firestore Collections Added For Future Phases

- `users/{userId}/adult_profile/{documentId}`
  - Holds adult-only answers and visibility settings.
  - Intended to remain isolated from public profile data.

- `wallets/{userId}`
  - Read model for wallet totals.
  - Server-owned updates only.

- `wallet_ledger/{entryId}`
  - Immutable financial ledger entries.
  - One row per economic event.

- `referral_codes/{code}`
  - Maps a unique referral code to its owner.

- `referrals/{referralId}`
  - Tracks attribution between referrer and referred user.

- `referral_earnings/{earningId}`
  - Tracks earned referral payouts separately from wallet summary docs.

- `blocks/{blockId}`
  - Block graph for messaging, room, and cam enforcement.

- `reports/{reportId}`
  - Trust and safety intake queue.

- `rooms/{roomId}/cam_access_requests/{requestId}`
  - Permission-based cam viewing requests and decisions.

- `rooms/{roomId}/policies/{documentId}`
  - Explicit room policy and permission data beyond the current room document.

## Safety Decisions In This Phase

- Existing collections and flows remain untouched.
- New wallet documents are client-readable by owner only and not client-writable.
- Referral earnings and moderation docs are groundwork only; admin mutation paths are intentionally not opened here.
- Adult-profile reads are restricted to the owner or other opted-in users who also accepted adult-mode consent.