# MixVy Release Validation Protocol

## Release Rule
Release state is binary.

- PASS: all required tests pass
- FAIL: any Tier 0 or Tier 1 test fails
- Non-blocking: Tier 2 issues, unless runtime-critical

Ship is allowed only when all required gate conditions below are met.

## Tier Model

### Tier 0: Hard Blockers (Core Correctness)

- Messaging Core
- Presence and Sync

If any Tier 0 test fails, ship is blocked.

### Tier 1: Product Usability Blockers

- Notifications and Routing

If any Tier 1 test fails, ship is blocked.

### Tier 2: Confidence Gates

- Analyzer and test health
- CI stability

Tier 2 is non-blocking unless there is a critical runtime failure.

## Executable Test Cases

### Tier 0: Messaging Core

#### MC-1 Ordering Determinism
- Setup: dual client, force one client offline, reconnect.
- Pass condition: final message ordering is identical across clients.

#### MC-2 Duplicate Suppression
- Setup: retry same message under network flaps.
- Pass condition: exactly one persisted message per `messageId`.

#### MC-3 Offline Queue Integrity
- Setup: queue 20 messages offline, reconnect.
- Pass condition: all 20 delivered once, in correct order.

#### MC-4 Crash Recovery Consistency
- Setup: kill app immediately after send.
- Pass condition: no ghost/pending mismatch after restart.

### Tier 0: Presence and Sync

#### PS-1 Lifecycle Correctness
- Setup: foreground, background, and kill cycles.
- Pass condition: presence is correct within defined latency window.

#### PS-2 Multi-Device Truth Convergence
- Setup: same user on two devices.
- Pass condition: one correct presence state, no ghost online.

#### PS-3 Partition Recovery
- Setup: network partition then restore.
- Pass condition: presence converges to source of truth.

#### PS-4 Room Dominance Rule
- Setup: user joins room during active presence updates.
- Pass condition: no dual classification state.

### Tier 1: Notifications and Routing

#### NR-1 Push to Correct Route
- Setup: app in background, tap push notification.
- Pass condition: correct conversation opens.

#### NR-2 Deep Link Correctness
- Setup: deep link on cold start and active session.
- Pass condition: correct route every time.

#### NR-3 No Double Navigation
- Setup: collide boot, deep link, and auth refresh.
- Pass condition: exactly one navigation event.

#### NR-4 Auth-Aware Routing
- Setup: push tap while unauthenticated.
- Pass condition: auth flow completes, then correct post-auth route opens.

### Tier 2: Confidence Gates

#### CG-1 Analyzer
- Pass condition: no runtime-blocking analyzer errors.

#### CG-2 Test Suite
- Pass condition: all Tier 0 and Tier 1 tests are green.

#### CG-3 CI Stability
- Pass condition: no flaky failures across two consecutive CI runs.

## Final Ship Gate
Ship equals TRUE only if:

- All Tier 0 tests PASS.
- All Tier 1 tests PASS.
- Tier 2 has no critical runtime failures.

Otherwise, ship equals FALSE.

## CI Mapping Layer

### Tier 0 stage (blocking)
- CI job: `flutter-tier0`
- Runner command: `bash tools/run_release_gate.sh tier0`
- Cases: `MC-1..MC-4`, `PS-1..PS-4`

### Tier 1 stage (blocking)
- CI job: `flutter-tier1`
- Runner command: `bash tools/run_release_gate.sh tier1`
- Cases: `NR-1..NR-4`

### Tier 2 stage (soft gate)
- CI job: `flutter-tier2`
- Runner command: `bash tools/run_release_gate.sh tier2`
- Cases: `CG-1..CG-3`
- Policy: job is `continue-on-error: true`; warnings must still be reviewed before release.

## Case-to-Command Mapping

### MC (Messaging Core)
- `MC-1` -> `flutter test --no-pub test/messages_screen_test.dart`
- `MC-2` -> `flutter test --no-pub test/chat_pane_view_test.dart`
- `MC-3` -> `flutter test --no-pub test/messaging_retention_test.dart`
- `MC-4` -> `flutter test --no-pub test/app_integration_test.dart`

### PS (Presence + Sync)
- `PS-1` -> `flutter test --no-pub test/presence_service_test.dart`
- `PS-2` -> `flutter test --no-pub test/presence_guardrail_test.dart`
- `PS-3` -> `flutter test --no-pub test/room_session_stress_test.dart`
- `PS-4` -> `flutter test --no-pub test/live_room_screen_test.dart`

### NR (Notifications + Routing)
- `NR-1` -> `flutter test --no-pub test/notification_service_test.dart`
- `NR-2` -> `flutter test --no-pub test/app_router_redirect_test.dart`
- `NR-3` -> `flutter test --no-pub test/messages_screen_test.dart`
- `NR-4` -> `flutter test --no-pub test/login_signup_navigation_test.dart`

### CG (Confidence)
- `CG-1` -> `flutter analyze --no-pub`
- `CG-2` -> `flutter test --no-pub test/features/schema_messenger/consistency`
- `CG-2` -> `flutter test --no-pub test/friend_list_screen_test.dart test/friend_provider_test.dart test/presence_guardrail_test.dart`
- `CG-3` -> `bash tools/enforce_governance_boundaries.sh`

## Usage Notes

- This protocol supersedes narrative readiness estimates.
- Interpret all results as binary PASS/FAIL for release decisions.
- Keep test evidence attached to each case ID (`MC-*`, `PS-*`, `NR-*`, `CG-*`).
