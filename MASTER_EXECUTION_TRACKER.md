# 🚀 MIX & MINGLE: MASTER EXECUTION TRACKER

**Current Phase:** 1 (Speed Dating Hardening)
**Status:** ✅ Implementation Complete → ⏳ Awaiting Deployment & Testing
**Last Updated:** February 10, 2026

---

## 📊 EXECUTION ROADMAP

```
PHASE 1: Harden Speed Dating ──────────────────► ✅ COMPLETE (Deploy Next)
PHASE 2: Define Launch MVP ────────────────────► 🔜 NEXT (After Phase 1 Tests)
PHASE 3: Adult Matching System ────────────────► 📋 PLANNED
PHASE 4: Real Launch Checklist ────────────────► 📋 PLANNED
```

---

## PHASE 1: SPEED DATING (Server-Authoritative)

### Status: ✅ IMPLEMENTATION COMPLETE

**What Was Built:**
- [x] Cloud Functions: Session expiry timer (5 minutes)
- [x] Cloud Functions: Server-side decision validation
- [x] Cloud Functions: Forced disconnect enforcement
- [x] Firestore Rules: Locked decisions after expiry
- [x] Firestore Rules: Server-only session creation
- [x] Client: Real-time status listener
- [x] Client: Auto-disconnect on server expiry
- [x] Documentation: Deployment guide + abuse tests

**Critical Files:**
- `functions/src/speedDating.ts` - Server logic
- `firestore.rules` - Security rules (lines 495-590)
- `lib/services/speed_dating_service.dart` - Client integration
- `lib/features/speed_dating/screens/speed_dating_call_page.dart` - UI handler

**Next Actions:**
1. ⏳ **Deploy Cloud Functions** (run: `firebase deploy --only functions`)
2. ⏳ **Deploy Firestore Rules** (run: `firebase deploy --only firestore:rules`)
3. ⏳ **Run Abuse Tests** (see PHASE_1_SPEED_DATING_HARDENED.md)
4. ⏳ **Verify Forced Disconnect** (2 test users, 5-minute session)

**Success Criteria:**
- [ ] All 5 abuse tests pass
- [ ] Zero sessions extend beyond 6 minutes
- [ ] Decisions rejected after expiry
- [ ] Client auto-disconnects on server signal

**Risk Level:** 🔴 HIGH (Legal liability if sessions don't expire)

---

## PHASE 2: DEFINE LAUNCH MVP

### Status: 📋 PLANNED (Pending Phase 1 Completion)

**Objective:** Lock down what launches vs what waits

### 2A: Core Identity ✅ (Existing - Verify Only)
- [ ] Audit: Profile pages (Facebook-like layout)
- [ ] Audit: Avatar, bio, interests
- [ ] Audit: Age verified (18+) enforcement
- [ ] Audit: Username/displayName requirements

**Files to Check:**
- `lib/features/onboarding/screens/profile_setup_screen.dart`
- `lib/features/onboarding/screens/onboarding_page.dart`
- `lib/core/safety/safety_ai_service.dart` (age checks)

**Action Items:**
- [ ] Run `grep -r "age >= 18" lib/` to verify gate exists
- [ ] Test: Try to create profile with age=17 (must fail)
- [ ] Test: Try to skip age field (must fail)

---

### 2B: Social Features ⚠️ (Verify Safety)
- [ ] Audit: Public rooms (who can join? NSFW separation?)
- [ ] Audit: Private rooms (invite-only enforcement?)
- [ ] Audit: Video + audio chat (Agora working?)
- [ ] Audit: Text chat (profanity filter?)
- [ ] Audit: Presence indicators (online/offline)

**Files to Check:**
- `lib/services/room_service.dart`
- `lib/services/room_firestore_service.dart`
- `firestore.rules` (rooms collection, lines 175-250)
- `lib/services/auto_moderation_service.dart`

**Action Items:**
- [ ] Test: Create public room with NSFW=true
- [ ] Verify: Only 18+ users can join NSFW rooms
- [ ] Test: Block user → verify they can't join your rooms
- [ ] Check: Profanity filter active in chat

---

### 2C: Dating Features ✅ (Speed Dating Hardened)
- [x] Speed dating (3-5 min) - **HARDENED**
- [ ] Like / pass / match UI
- [ ] Daily match limits (prevent spam)
- [ ] Match discovery (how do users find potential matches?)

**Files to Check:**
- `lib/features/speed_dating/` (already hardened)
- `lib/services/matching_service.dart` (if exists)
- `functions/src/matches.ts` (server-side matching)

**Action Items:**
- [ ] Find daily match limit logic (client? server?)
- [ ] Test: Like 50+ users in 1 hour (should be rate limited)
- [ ] Verify: Match algorithm uses consent preferences

---

### 2D: Safety Features 🔴 (HIGH PRIORITY)
- [ ] Block / report (verify enforcement)
- [ ] NSFW room separation (verify gate)
- [ ] Consent enforcement (what does this mean exactly?)

**Files to Check:**
- `lib/services/user_safety_service.dart` (block/report)
- `lib/services/moderation_service.dart`
- `firestore.rules` (reports collection)

**Action Items:**
- [ ] Test: Block user A as user B
- [ ] Verify: User A cannot join user B's rooms
- [ ] Verify: User A cannot send DMs to user B
- [ ] Test: Report user → verify admin can see report
- [ ] Check: NSFW rooms hidden from users <18

---

### 2E: Monetization (Soft) 💰 (Test, Don't Push Hard)
- [ ] Coins (virtual currency)
- [ ] Tips / gifts
- [ ] No aggressive paywalls yet

**Files to Check:**
- `functions/src/coins.ts` (coin transactions)
- `functions/src/payments.ts` (Stripe integration?)
- `lib/services/coin_service.dart`

**Action Items:**
- [ ] Test: Send tip to another user
- [ ] Verify: Coins deducted correctly
- [ ] Verify: Negative balance not possible
- [ ] Check: No forced purchase prompts (soft only)

---

### 2F: What WAITS (Do NOT Build Yet)
❌ MySpace-style profile theming
❌ CSS-like customization
❌ Advanced fetish graph matching
❌ Creator storefronts
❌ Paid boosts & visibility

**Why?** Real user behavior decides how these should work.

---

## PHASE 3: ADULT MATCHING & FETISH SYSTEM

### Status: 📋 PLANNED (After Phase 2 Audit Complete)

**Critical Design Principle:** Consent-first, no public sexual data

### 3A: Preference Storage Model
```json
user_preferences {
  categories: ["poly", "bdsm", "swingers", "vanilla"],
  hardLimits: ["..."],
  softLimits: ["..."],
  visibility: "opt-in" | "private",
  consentToMatch: true/false
}
```

**Rules:**
- ❌ Never show sexual preference unless BOTH users opted in
- ❌ Never make sexual data searchable publicly
- ✅ Only used server-side for matching algorithm

---

### 3B: Question Engine (Already Exists - Verify)
- [ ] Locate question storage in Firestore
- [ ] Verify questions are server-side only
- [ ] Check: Questions used ONLY for matching (not public)

**Matching Weight Example:**
```
30% shared interests
30% sexual compatibility (if both opted in)
20% location proximity
20% activity/engagement history
```

---

### 3C: Legal Shield (Already Done - Maintain)
- [x] Age enforcement (18+)
- [x] Terms acceptance required
- [x] NSFW labeling on rooms

**DO NOT WEAKEN LATER**

---

## PHASE 4: REAL LAUNCH CHECKLIST

### Status: 📋 PLANNED (Final Gate Before Public Users)

### 4A: Technical Lock
- [ ] `flutter build web --release` runs clean
- [ ] `firebase deploy` succeeds (exit code 0)
- [ ] Cloud Functions logs clean (no errors)
- [ ] No console errors on join/leave room

### 4B: Abuse Testing (CRITICAL)
Run with 2 fake users, try to:
- [ ] Spam messages (rate limit should block)
- [ ] Extend speed dates (server should expire)
- [ ] Change age after signup (should be locked)
- [ ] Bypass block (blocked user cannot access)
- [ ] Enter NSFW room as underage (should be denied)

**If ANY succeed → FIX before launch**

### 4C: Store & Legal Positioning
- [ ] App labeled **18+** in stores
- [ ] Clear content disclaimer on landing page
- [ ] Dating + social category (NOT porn)
- [ ] Terms of Service reviewed by lawyer (recommended)

---

## 🎯 CURRENT PRIORITY: PHASE 1 DEPLOYMENT

**You are HERE:**
```
[✅ Code Complete] → [⏳ Deploy] → [⏳ Test] → [✅ Phase 1 Done]
```

**Next 3 Actions:**
1. Run: `firebase deploy --only functions`
2. Run: `firebase deploy --only firestore:rules`
3. Execute abuse tests from PHASE_1_SPEED_DATING_HARDENED.md

**Estimated Time:** 30 minutes deployment + 1 hour testing

---

## 📈 SUCCESS METRICS BY PHASE

### Phase 1 (Speed Dating)
- **Must Have:** 0 sessions beyond 6 minutes
- **Must Have:** <1% abandonment rate
- **Goal:** 100+ completed sessions before Phase 2

### Phase 2 (Launch MVP)
- **Must Have:** All safety tests passed
- **Must Have:** Block/report working
- **Goal:** 500+ registered users, 50+ DAU

### Phase 3 (Adult Matching)
- **Must Have:** Zero public sexual data leaks
- **Must Have:** Opt-in consent enforced
- **Goal:** 80%+ match satisfaction rate

### Phase 4 (Real Launch)
- **Must Have:** App store approval
- **Must Have:** Zero critical bugs in production
- **Goal:** 1,000+ users in first week

---

## 🚨 RISK REGISTER

| Risk | Phase | Severity | Mitigation |
|------|-------|----------|------------|
| Sessions don't expire | 1 | 🔴 CRITICAL | Abuse testing before launch |
| Users bypass age gate | 2 | 🔴 CRITICAL | Server-side age validation |
| Sexual data leaks publicly | 3 | 🔴 CRITICAL | Firestore rules + visibility opt-in |
| Platform ban (ToS violation) | 4 | 🔴 CRITICAL | Legal review, 18+ labeling |
| Harassment reports spike | 2-4 | 🟡 HIGH | Block/report working + fast response |
| Server costs exceed budget | 4 | 🟡 HIGH | Monitor Cloud Function usage |

---

## 💬 DECISION LOG

| Date | Decision | Rationale |
|------|----------|-----------|
| Feb 10, 2026 | 5-minute sessions (not 3) | User feedback: 3 min too rushed |
| Feb 10, 2026 | setTimeout (not Cloud Tasks) | Simpler for MVP, migrate at scale |
| Feb 10, 2026 | Server-only session creation | Prevent client-side gaming |
| Feb 10, 2026 | Phase 2 before Phase 3 | Safety audit before adult features |

---

## 📞 ESCALATION PATHS

**If speeds dating tests fail:**
- Do NOT launch
- Debug with Firebase emulator
- Review Cloud Function logs
- Escalate to senior engineer

**If Firestore rules broken:**
- Rollback immediately
- Audit rule changes
- Re-test all abuse scenarios

**If users report harassment:**
- Block reported user immediately
- Investigate session logs
- Verify forced disconnect worked

---

**Next Update:** After Phase 1 deployment completes

**Owner:** Engineering team
**Stakeholders:** Product, Legal, Safety teams
