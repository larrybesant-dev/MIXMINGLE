# Enterprise Architecture Audit — MixMingle
**Date:** 2026-02-23  
**Grade Target:** Enterprise-grade  
**Auditor:** GitHub Copilot Engineering Review

---

## Executive Summary

The project is active and functional but carries structural debt that will block scaling.  
The core problems are **layer bleeding**, **duplicate feature folders**, **missing repository abstraction**, and **service-layer sprawl**.  
This document maps every problem to a specific fix and provides the complete target layout.

---

## 1. Current State — Problem Inventory

### 1.1 Root-Level `lib/` Pollution

Files sitting loose at `lib/` root that belong inside structured folders:

| File | Problem | Target Location |
|---|---|---|
| `app.dart` | App shell should not be at root | `lib/app/app.dart` |
| `app_routes.dart` | Routing is a core concern | `lib/core/routing/app_routes.dart` |
| `auth_gate.dart` | Auth guard is a core concern | `lib/core/guards/auth_gate.dart` |
| `auth_gate_root.dart` | Duplicate guard | `lib/core/guards/auth_gate_root.dart` |
| `firebase_options.dart` | Config file | `lib/core/config/firebase_options.dart` |

---

### 1.2 Parallel Competing Directories (Critical)

The following top-level folders duplicate responsibilities that `core/` and `features/` already own.  
Every one of these is a structural split that must be resolved.

| Directory | Files | Problem | Resolution |
|---|---|---|---|
| `lib/services/` | 80+ files | Competes with `lib/core/services/` | Merge into `lib/services/` (cross-feature only) + move feature-specific to their feature |
| `lib/screens/` | 4 files | Competes with `features/*/screens/` | Move each to its owning feature |
| `lib/widgets/` | 4 files | Competes with `features/*/widgets/` | Move each to its owning feature |
| `lib/controllers/` | 9 files | Competes with `features/*/controllers/` | Move each to its owning feature |
| `lib/helpers/` | 3 files | Platform helpers scattered | Move to `lib/core/platform/` |
| `lib/utils/` | 10 files | Web/platform utils scattered | Move to `lib/core/platform/` |
| `lib/design/` | 1 file | Should not be separate from `core/design_system/` | Merge into `lib/core/design_system/` |
| `lib/platform/` | 2 files | Should not be top-level | Move to `lib/core/platform/` |
| `lib/config/` | 2 files | Should not be top-level | Move to `lib/core/config/` |

---

### 1.3 Duplicate Feature Folders (Critical)

These are the same domain concern split across multiple folders — a maintenance and import nightmare:

| Duplicate Group | Folders | Action |
|---|---|---|
| Room/Live | `features/room/` + `features/rooms/` + `features/video_room/` + `features/voice_room/` + `features/go_live/` | **Merge → `features/room/`** with `live/`, `video/`, `voice/` sub-dirs |
| Payments | `features/payment/` + `features/payments/` | **Merge → `features/payments/`** |
| Discovery | `features/discover/` + `features/discover_users/` + `features/browse/` + `features/browse_rooms/` | **Merge → `features/discover/`** |

---

### 1.4 Non-Feature Folders Leaking into `features/` (High Priority)

These are **roadmap/planning categories masquerading as feature folders**. They should not exist in `features/`.  
They contain dev notes, prototypes, or empty shells — not production feature code.

```
features/automation/      ← roadmap concept, not a user-facing feature
features/autonomy/        ← same
features/beta/            ← dev category, not a feature
features/ecosystem/       ← same
features/empire/          ← same
features/enterprise/      ← same
features/experiments/     ← should be feature_flags, not a folder
features/future/          ← dev notes, not a feature
features/growth/          ← analytics/marketing concern, not a screen feature
features/insights/        ← belongs in admin or analytics
features/launch/          ← dev category
features/liveops/         ← ops concern
features/multiplatform/   ← platform concern
features/qa/              ← belongs in test/
features/quality/         ← same
features/release/         ← belongs in CI/CD docs
features/retention/       ← analytics/marketing concern
features/scale/           ← ops/infra concern
```

**Rule:** `features/` contains only user-facing, screen-based feature modules.  
Everything else goes to `core/`, `lib/services/`, docs, or `test/`.

---

### 1.5 Missing Repository Layer (Blocker for Enterprise Standard)

Current write path:  
```
UI Widget → Service → Firestore  ❌
```

Enterprise required path:  
```
UI Widget → Controller/Provider → Service → Repository → Firestore  ✅
```

No feature currently has a `repositories/` folder. This means:
- Firestore coupling cannot be swapped or mocked
- Unit testing services requires live Firestore
- There is no single enforced write contract per collection

**Required:** Every feature that writes to Firestore must have a `repositories/` layer.

---

### 1.6 Shared Layer Confusion

`lib/shared/` and `lib/core/` overlap significantly:

| Concern | Locations Found | Should Be |
|---|---|---|
| Models | `lib/shared/models/` + `lib/core/models/` | `lib/core/models/` (cross-feature only) |
| Providers | `lib/shared/providers/` + `lib/core/providers/` | `lib/core/providers/` |
| Widgets | `lib/shared/widgets/` + `lib/core/design_system/components/` | `lib/core/design_system/components/` |
| Constants | `lib/shared/constants/` + `lib/core/constants/` | `lib/core/constants/` |
| Stubs | `lib/shared/stubs/` + `lib/core/stubs/` | `lib/core/stubs/` |

`lib/shared/` should either be fully absorbed into `lib/core/` or kept strictly for **UI components only**.

---

### 1.7 Service Layer Sprawl

`lib/services/` contains **80+ service files** with no sub-grouping.  
For enterprise scale, services must be grouped by domain:

```
lib/services/
  agora/       ← 9 agora-related files currently loose
  video/
  auth/
  storage/
  analytics/
  notifications/
  moderation/
  payments/
```

---

### 1.8 CI/CD Status

5 GitHub Actions workflows exist. Assessment:

| Workflow | File | Status |
|---|---|---|
| General CI | `.github/workflows/ci.yml` | Exists |
| Build + Deploy | `.github/workflows/build-deploy.yml` | Exists |
| Android build | `.github/workflows/build-android.yml` | Exists |
| Flutter CI | `.github/workflows/flutter-ci.yml` | Exists |
| Web deploy | `.github/workflows/deploy-web.yml` | Exists |

**Gaps (enterprise standard):**
- No staging vs. production environment separation in workflows
- No security rule deployment step
- No test coverage threshold enforcement
- No `flutter analyze --fatal-infos` failure gate

---

## 2. Target Enterprise Layout

```
lib/
├── main.dart                          ← entry only: runApp + bootstrap
├── bootstrap.dart                     ← DI, Firebase init, env setup
│
├── app/
│   ├── app.dart                       ← MaterialApp root
│   └── auth_gate.dart                 ← top-level auth state router
│
├── core/
│   ├── config/
│   │   ├── environment_config.dart
│   │   ├── firebase_options.dart
│   │   └── production_initializer.dart
│   ├── constants/
│   │   └── app_constants.dart
│   ├── design_system/
│   │   ├── colors.dart
│   │   ├── typography.dart
│   │   ├── spacing.dart
│   │   └── components/               ← shared atoms (buttons, cards, inputs)
│   ├── error/
│   │   ├── app_error.dart
│   │   └── error_handler.dart
│   ├── extensions/
│   ├── feature_flags/
│   │   └── feature_flags.dart
│   ├── guards/
│   │   └── auth_guard.dart
│   ├── i18n/
│   ├── logging/
│   ├── models/                        ← ONLY truly cross-feature models
│   ├── pagination/
│   ├── performance/
│   ├── platform/                      ← js_bridge, media helpers, stubs
│   ├── providers/                     ← root-level Riverpod/Provider setup
│   ├── routing/
│   │   └── app_routes.dart
│   ├── safety/
│   └── theme/
│
├── features/
│   ├── auth/
│   │   ├── models/
│   │   ├── repositories/              ← auth_repository.dart
│   │   ├── services/
│   │   ├── controllers/
│   │   ├── screens/
│   │   └── widgets/
│   │
│   ├── profile/
│   │   ├── models/
│   │   ├── repositories/
│   │   ├── services/
│   │   ├── controllers/
│   │   ├── screens/
│   │   └── widgets/
│   │
│   ├── room/                          ← MERGED: room + rooms + video_room + voice_room + go_live
│   │   ├── models/
│   │   ├── repositories/
│   │   ├── services/
│   │   ├── controllers/
│   │   ├── screens/
│   │   ├── widgets/
│   │   └── live/                     ← live-specific sub-concerns
│   │
│   ├── chat/
│   │   ├── models/
│   │   ├── repositories/
│   │   ├── services/
│   │   ├── controllers/
│   │   ├── screens/
│   │   └── widgets/
│   │
│   ├── discover/                      ← MERGED: discover + discover_users + browse + browse_rooms
│   │   ├── models/
│   │   ├── repositories/
│   │   ├── services/
│   │   ├── controllers/
│   │   ├── screens/
│   │   └── widgets/
│   │
│   ├── payments/                      ← MERGED: payment + payments
│   │   ├── models/
│   │   ├── repositories/
│   │   ├── services/
│   │   ├── controllers/
│   │   ├── screens/
│   │   └── widgets/
│   │
│   ├── notifications/
│   ├── moderation/
│   ├── settings/
│   ├── onboarding/
│   ├── leaderboards/
│   ├── events/
│   ├── matching/
│   ├── messages/
│   ├── achievements/
│   ├── withdrawal/
│   ├── admin/
│   ├── group_chat/
│   ├── reporting/
│   └── home/
│
├── services/                          ← ONLY cross-feature infrastructure services
│   ├── agora/
│   │   ├── agora_service.dart
│   │   ├── agora_platform_service.dart
│   │   └── agora_web_bridge.dart
│   ├── analytics/
│   │   └── analytics_service.dart
│   ├── auth/
│   │   └── auth_service.dart
│   ├── storage/
│   │   └── storage_service.dart
│   ├── notifications/
│   │   └── push_notification_service.dart
│   ├── moderation/
│   │   └── ai_moderation_service.dart
│   └── video/
│       └── video_engine_service.dart
│
└── shared/
    ├── constants/                     ← shared string/numeric constants
    ├── models/                        ← shared data models (if any remain after feature migration)
    ├── validation/
    └── widgets/                       ← shared UI: loading, error boundary, etc.
```

---

## 3. Repository Layer Standard

Every feature that writes to Firestore must implement this pattern:

```dart
// features/profile/repositories/profile_repository.dart
abstract class IProfileRepository {
  Future<UserProfile?> getProfile(String uid);
  Future<void> updateProfile(String uid, Map<String, dynamic> data);
  Future<void> deleteProfile(String uid);
}

class ProfileRepository implements IProfileRepository {
  final FirebaseFirestore _db;
  ProfileRepository(this._db);

  @override
  Future<void> updateProfile(String uid, Map<String, dynamic> data) async {
    // UID validation must happen HERE, not in the UI
    if (uid.isEmpty) throw ArgumentError('UID cannot be empty');
    await _db.collection('users').doc(uid).update(data);
  }
}
```

**Write contract:**
```
UI → Controller → Service (validates intent) → Repository (validates UID/data) → Firestore
```

---

## 4. Migration Execution Order

Execute in this order to avoid breaking imports:

### Phase 1 — Non-breaking structural (1–2 days)
1. Move `lib/design/design_colors.dart` → `lib/core/design_system/colors.dart`
2. Move `lib/config/` → `lib/core/config/`
3. Move `lib/platform/` → `lib/core/platform/`
4. Move `lib/helpers/` → `lib/core/platform/`
5. Move `lib/utils/` → `lib/core/platform/`
6. Move `app.dart`, `app_routes.dart`, `auth_gate*` → `lib/app/` and `lib/core/routing/`

### Phase 2 — Consolidate lib-level duplicates (2–3 days)
7. Move `lib/screens/*.dart` → owning feature `/screens/`
8. Move `lib/widgets/*.dart` → owning feature `/widgets/`
9. Move `lib/controllers/*.dart` → owning feature `/controllers/`

### Phase 3 — Merge duplicate features (3–5 days)
10. Merge `payment/` into `payments/`
11. Merge `discover/` + `discover_users/` + `browse/` + `browse_rooms/` → `discover/`
12. Merge `room/` + `rooms/` + `video_room/` + `voice_room/` + `go_live/` → `room/`

### Phase 4 — Consolidate shared/core overlap (2 days)
13. Merge `lib/shared/models/` into `lib/core/models/`
14. Merge `lib/shared/providers/` into `lib/core/providers/`
15. Merge `lib/shared/constants/` into `lib/core/constants/`
16. Reduce `lib/shared/` to widgets only

### Phase 5 — Add repository layer (3–5 days)
17. Create `repositories/` in every feature that writes to Firestore
18. Refactor services to delegate Firestore writes to repositories
19. Update service unit tests to use mocked repositories

### Phase 6 — Consolidate services (2 days)
20. Group `lib/services/` files into sub-folders by domain
21. Remove feature-specific services from top-level `lib/services/` (move to feature)

### Phase 7 — Delete non-feature folders from `features/` (1 day)
22. Archive or delete: `automation/`, `autonomy/`, `beta/`, `ecosystem/`, `empire/`, `enterprise/`, `experiments/`, `future/`, `growth/`, `insights/`, `launch/`, `liveops/`, `multiplatform/`, `qa/`, `quality/`, `release/`, `retention/`, `scale/`

### Phase 8 — CI/CD hardening (1 day)
23. Add `flutter analyze --fatal-infos` to CI
24. Add test coverage threshold (minimum 60% for enterprise)
25. Add separate staging deploy workflow
26. Add Firestore rules deployment to CI

---

## 5. Enterprise Standards Checklist

### Architecture
- [ ] Root lib/ has no loose feature files
- [ ] Every feature has: `models/`, `repositories/`, `services/`, `controllers/`, `screens/`, `widgets/`
- [ ] No duplicate feature folders
- [ ] No roadmap folders inside `features/`
- [ ] Services grouped by domain in `lib/services/`
- [ ] `lib/shared/` contains UI components only

### Data Layer
- [ ] Every Firestore write goes through a Repository
- [ ] All repositories implement an abstract interface
- [ ] UID validation happens in the repository, not the UI
- [ ] No direct `FirebaseFirestore.instance` calls in widgets

### Security
- [ ] Firestore rules: default deny on all collections
- [ ] UID validated server-side in security rules
- [ ] Custom claims used for admin role
- [ ] Rate-sensitive actions gated by Cloud Functions
- [ ] Storage rules: folder-based access control

### Testing
- [ ] Unit tests for all repositories
- [ ] Unit tests for all services
- [ ] Widget tests for all screens
- [ ] Firestore rules tested via emulator
- [ ] CI enforces test pass before merge

### CI/CD
- [ ] `flutter analyze --fatal-infos` blocks merge
- [ ] Tests run on every PR
- [ ] Staging environment separate from production
- [ ] Rules deployed via CI, not manually
- [ ] Build artifacts versioned

### Monitoring
- [ ] Crashlytics enabled
- [ ] Firebase Analytics integrated
- [ ] Performance monitoring enabled
- [ ] Error tracking service wired to logging

---

## 6. Severity Index

| Issue | Severity | Effort | Impact |
|---|---|---|---|
| Missing repository layer | 🔴 Critical | High | Testability, security |
| Duplicate feature folders | 🔴 Critical | Medium | Maintainability |
| 80+ flat service files | 🟠 High | Medium | Discoverability, ownership |
| Root lib/ pollution | 🟠 High | Low | Import clarity |
| Non-feature dirs in features/ | 🟠 High | Low | Cognitive load |
| Shared/core overlap | 🟡 Medium | Medium | Duplication |
| Parallel lib/ directories | 🟡 Medium | Medium | Confusion |
| CI coverage threshold missing | 🟡 Medium | Low | Regression risk |

---

*Start with Phase 1. It is non-breaking, can be done in a day, and immediately clarifies the mental model for every other phase.*
