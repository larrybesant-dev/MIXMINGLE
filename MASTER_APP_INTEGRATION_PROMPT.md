# MASTER APP INTEGRATION & PRODUCTION PROMPT — MIX & MINGLE

## Context

I have a **Flutter 3.38.7** app called **Mix & Mingle** (Web/iOS/Android) with Firebase backend, Agora video, Stripe payments, and multi-feature social platform functionality including:

- **Multi-user video chat rooms** (Web & Mobile)
- **Speed-dating rounds** (5-minute rounds, questionnaire, Keep/Pass, mutual matching)
- **Host/moderator controls** (mute, remove, lock room, end room, co-hosts)
- **Stripe tipping and coin purchase system**
- **Neon club branding and theme**
- **Multi-window web rooms** (like Paltalk)
- Existing stub/deprecated files and multiple duplicate video engine implementations

## Goals

1. Scan and inventory the entire project (`lib/`, `services/`, `models/`, `screens/`, `web/`)
2. Identify critical compilation issues, stub/duplicate files, and overlapping services
3. Consolidate video engine architecture (Web ↔ Mobile) via unified `VideoEngineService`
4. Ensure multi-window Web rooms are fully functional
5. Fully implement speed dating features:
   - Questionnaire storage & retrieval (10-12 questions)
   - Keep/Pass decision tracking
   - Smart pairing logic
   - Round timers (5 min) with real-time countdown
   - Multi-window management
6. Implement and verify host/moderator controls
7. Implement and verify Stripe payment system (tips, coin purchases, refunds)
8. Clean up stub, old, deprecated files
9. Ensure Firestore schema is consistent, secure rules applied, and permissions follow least privilege
10. Test Web, iOS, Android builds
11. Generate comprehensive production report with build, test logs, and audit summary
12. Prepare app for deployment (Firebase Hosting for Web, APK/AAB for Android, IPA for iOS)

---

## Tasks (10 Phases)

### PHASE 1 — SCAN & AUDIT

- [ ] Scan all `lib/`, `services/`, `models/`, `screens/` folders
- [ ] List all stub, old, deprecated, and duplicate files
- [ ] Catalog all services, models, features, and Firestore collections
- [ ] Generate a detailed report of code structure and feature completeness

**Output:** `PROJECT_STRUCTURE_AUDIT.md`

---

### PHASE 2 — FIX CRITICAL ISSUES

- [ ] Fix Agora mobile engine compilation errors
- [ ] Verify `ChannelMediaOptions`, `RemoteAudioState`, `RemoteVideoState` enums
- [ ] Ensure `VideoEngineService` interface matches Web & Mobile implementations
- [ ] Run `flutter analyze` and fix critical errors

**Output:** `CRITICAL_FIXES_LOG.md`

---

### PHASE 3 — CONSOLIDATE VIDEO ENGINE

- [ ] Create `IVideoEngine` interface
- [ ] Ensure `AgoraWebEngine` and `AgoraMobileEngine` implement interface
- [ ] Remove redundant/stub bridge files
- [ ] Test multi-user join/leave, mute/unmute, toggle video

**Output:** `VIDEO_ENGINE_CONSOLIDATION_REPORT.md`

---

### PHASE 4 — SPEED DATING SYSTEM

- [ ] Implement full questionnaire model & storage
- [ ] Implement pairing logic and room assignment
- [ ] Implement 5-minute timer with countdown
- [ ] Implement Keep/Pass logic with mutual matching
- [ ] Enable multi-window Web room support
- [ ] Ensure host can end/lock rooms

**Output:** `SPEED_DATING_IMPLEMENTATION_REPORT.md`, `speed_dating_flow_test.dart`

---

### PHASE 5 — HOST & MODERATOR CONTROLS

- [ ] mute/unmute individual users
- [ ] remove/kick users from rooms
- [ ] ban/unban users with audit log
- [ ] promote/demote co-hosts
- [ ] lock/unlock/end rooms
- [ ] comprehensive moderation history

**Output:** `MODERATOR_CONTROLS_IMPLEMENTATION_REPORT.md`

---

### PHASE 6 — STRIPE PAYMENTS

- [ ] Implement tip functionality via Cloud Function
- [ ] Implement coin purchases via Stripe checkout
- [ ] Track tip history and leaderboards
- [ ] Enable refunds and secure logging

**Output:** `STRIPE_PAYMENTS_IMPLEMENTATION_REPORT.md`, `stripe_checkout_test.dart`

---

### PHASE 7 — CLEANUP

- [ ] Remove all stub, old, deprecated files
- [ ] Consolidate overlapping services
- [ ] Verify proper dependency injection
- [ ] Ensure Neon theme is consistent

**Output:** `CLEANUP_COMPLETION_LOG.md`

---

### PHASE 8 — TESTING

- [ ] Run `flutter analyze`, fix info-level warnings where possible
- [ ] Test multi-window Web rooms
- [ ] Test speed dating flow (questionnaire, rounds, Keep/Pass)
- [ ] Test Stripe payments & coin purchases
- [ ] Build Web, Android, iOS (if macOS available)
- [ ] Generate automated logs for all tests

**Output:**
- `analyze_report.txt`
- `web_room_test_log.txt`
- `speed_dating_test_log.txt`
- `stripe_test_log.txt`
- `build_log.txt`

---

### PHASE 9 — BUILD & DEPLOY

- [ ] Clean build directories
- [ ] Build Flutter Web release
- [ ] Build Flutter Android APK & AAB release
- [ ] Build iOS release (if macOS)
- [ ] Deploy Web to Firebase Hosting
- [ ] Generate production-ready report with:
  - Build artifacts
  - Test logs
  - Firestore schema
  - Host/moderator controls verification
  - Stripe payments verification

**Output:** `PRODUCTION_READY_REPORT.md`

---

### PHASE 10 — FINAL VERIFICATION

- [ ] Ensure auth flows (signup/login/logout/session restore) work
- [ ] Ensure video rooms work cross-platform
- [ ] Ensure speed dating works as designed
- [ ] Ensure payments work
- [ ] Ensure Neon theme is applied consistently
- [ ] Confirm all logs and reports generated
- [ ] App is production-ready

**Output:** `FINAL_VERIFICATION_CHECKLIST.md`

---

## Deliverables

- ✅ Cleaned & consolidated project files
- ✅ Unified video engine service
- ✅ Fully functional speed dating system
- ✅ Full host/moderator controls
- ✅ Stripe payment integration
- ✅ Production-ready builds (Web, Android, iOS)
- ✅ Automated test scripts
- ✅ Comprehensive audit report

---

## Instructions

1. **Scan project** - Inventory all files, services, and features
2. **Implement fixes and missing features** - Follow each phase systematically
3. **Run automated tests** - Execute test scripts to verify functionality
4. **Generate logs & final report** - Collect all output files
5. **Prepare builds for deployment** - Create production-ready artifacts
6. **Confirm all features work as intended** - Manual QA checklist
7. **Provide a checklist of remaining minor tasks** (if any)

---

## Important Notes

- ⚠️ **All operations should preserve Firestore security rules**
- ⚠️ **Use proper async handling for multi-user video**
- ⚠️ **Multi-window Web rooms must behave like Paltalk**
- ⚠️ **Speed dating rounds must be 5 minutes with countdown timers**
- ⚠️ **Questionnaire must store answers and feed pairing logic**
- ⚠️ **Stripe integration must be fully PCI compliant**

---

## Progress Tracking

| Phase | Task | Status | Completion Date |
|-------|------|--------|-----------------|
| 1 | Scan & Audit | Not Started | - |
| 2 | Fix Critical Issues | Not Started | - |
| 3 | Consolidate Video Engine | Not Started | - |
| 4 | Speed Dating System | Not Started | - |
| 5 | Host & Moderator Controls | Not Started | - |
| 6 | Stripe Payments | Not Started | - |
| 7 | Cleanup | Not Started | - |
| 8 | Testing | Not Started | - |
| 9 | Build & Deploy | Not Started | - |
| 10 | Final Verification | Not Started | - |

---

**Date Created:** February 6, 2026
**Project:** Mix & Mingle Flutter App
**Target:** Production Ready
