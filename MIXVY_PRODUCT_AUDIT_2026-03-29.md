# MixVy Product Audit (2026-03-29)

This audit compares MixVy against a universal social app baseline (auth, profile, settings, social, content, payments, safety, reliability).

## Scoring Legend
- Implemented: Feature exists and appears wired in user flow.
- Partial: Feature exists but appears incomplete, duplicated, or not fully hardened.
- Missing: No strong evidence in app or backend.

## 1) Authentication & Account Control

### Implemented
- Email/password sign in and sign up.
- Google sign in (web + mobile helper paths).
- Sign out.
- Forgot password / password reset email.
- Session persistence and guarded routing.

### Partial
- Email verification support exists in repository API but no clear end-user verification flow gate.
- Account management is split across multiple auth paths/controllers.

### Missing
- Apple Sign In.
- In-app change password flow.
- Delete account flow (self-serve, authenticated, secure reauth path).

## 2) User Profile Tools

### Implemented
- Profile photo, cover photo, gallery photo, intro video uploads.
- Display name, bio, interests/tags, advanced profile fields.
- View other profiles.
- Block user.
- Report user.

### Partial
- Profile model/service surface is broad; some profile-related responsibilities are spread across feature and presentation layers.

### Missing
- None critical in baseline identity expression.

## 3) Settings & Preferences

### Implemented
- Theme mode (system/light/dark).
- Notification toggle.
- Analytics toggle.
- Basic privacy summary.

### Partial
- Privacy controls are split between settings and profile subflows.

### Missing
- Language/locale selection.
- Connected account management UI.
- In-app app-version/build info panel.

## 4) Core Social Tools

### Implemented
- Friends system (requests, accept/decline, remove).
- Follow system.
- Chat in room contexts.
- Typing/presence repositories.
- Live rooms and host controls.
- Reactions in room/feed modules.
- Discovery feed with recommendation ranking, reasons, and tiers.

### Partial
- Activity feed quality and breadth appear limited compared with major social apps.
- Some repository/service overlap remains across room/chat/presence abstractions.

### Missing
- Robust comments system at broad app content level (outside room messaging).

## 5) Content Tools

### Implemented
- Photo/video upload flows.
- Image resizing and size guardrails.
- Media link viewing/opening.

### Partial
- No strong centralized media processing pipeline evidence (transcode/thumbnail jobs at backend level).

### Missing
- Automated NSFW moderation pipeline.
- Anti-spam content moderation classifier.

## 6) Payments & Monetization

### Implemented
- Stripe payment intent and checkout session flows.
- Coin transfer/request flows.
- Stripe Connect onboarding and dashboard link.
- Transactions stream/history support.

### Partial
- Refund and dispute lifecycle handling appears limited.
- Some payment operations still rely on trust in callable sequencing; additional server-side policy hardening is advisable.

### Missing
- Explicit refund request and status UX.
- Subscription lifecycle management UX (if subscription is a product requirement).

## 7) Trust, Safety, Reliability, and Ops

### Implemented
- Blocking and report submission models/services.
- Crash capture integration in app startup flow.
- Firebase emulator bootstrap support.

### Partial
- Safety controls exist but no explicit moderation dashboard for operational triage.
- Reliability telemetry exists in parts; not yet complete funnel-level observability.

### Missing
- Rate limiting/throttling strategy clearly enforced in Cloud Functions.
- Dedicated anti-spam guardrails for critical write paths.
- Terms of Service and Privacy Policy surfaced in-app.
- Backup/restore and disaster recovery runbook documentation.

---

## Highest-Priority Gaps (P0)
1. Account deletion flow (UI + backend callable + reauth checks + data retention policy).
2. Apple Sign In (parity with user expectations).
3. Rate limiting and anti-spam hardening on write-heavy endpoints.
4. Terms/Privacy legal surfaces and settings links.
5. Refund handling path and user-visible payment support states.

## Next Priority (P1)
1. Connected account management center.
2. Language/localization controls.
3. Version/build info and diagnostics panel.
4. Moderation dashboard for reports and abuse triage.
5. Content moderation pipeline (image/video/text scanning and queue).

## Architectural Risks to Track
1. Duplicate/overlapping repository/service layers (room/chat/presence + older data/domain paths).
2. Feature duplication in auth/profile pathways can create regression risk.
3. Growing social graph and feed ranking need stronger analytics feedback loops for tuning.

---

## 4-Phase Build Plan

### Phase 1 (Security/Trust Foundation)
- Ship account deletion.
- Add Apple Sign In.
- Enforce function-level throttling and abuse limits.
- Add legal links/screens and acceptance tracking.

### Phase 2 (Monetization Reliability)
- Add refund request workflow and payment support states.
- Harden transaction auditing and admin review tools.

### Phase 3 (User Control & Product Polish)
- Add language support.
- Add linked-account management and session device controls.
- Add version/about/diagnostics in settings.

### Phase 4 (Safety + Scale)
- Build moderation dashboard and triage workflow.
- Add content moderation jobs and human-review queues.
- Expand ranking telemetry and conversion analytics.

---

## Suggested Tracking Checklist
- [x] P0-01 Account delete (client flow + backend cleanup trigger + tests)
- [ ] P0-02 Apple Sign In (iOS/web + fallback UX + tests)
- [x] P0-03 Rate limits and anti-spam middleware in functions
- [x] P0-04 Terms/Privacy in app settings and onboarding/legal acceptance
- [x] P0-05 Refund path and support states
- [x] P1-01 Connected account center
- [ ] P1-02 Language selector and localization baseline
- [x] P1-03 App version/build diagnostics panel
- [ ] P1-04 Moderation dashboard
- [ ] P1-05 Automated content moderation pipeline

