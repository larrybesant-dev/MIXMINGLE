# PR: chore(lint): Stage 1 lint re-enable — style rules + dart fix

> **Branch:** `lint-stage-1` → `develop`  
> **Commit:** `6cb3a2f`

---

## Summary

Re-enables the first group of style lint rules in `analysis_options.yaml` and applies
all automated fixes via `dart fix --apply`.

| Rule | Before | After |
|------|--------|-------|
| `prefer_const_constructors` | `false` | `true` |
| `prefer_const_declarations` | `false` | `true` |
| `prefer_final_fields` | `false` | `true` |
| `prefer_final_locals` | `false` | `true` |
| `prefer_const_literals_to_create_immutables` | _(not set)_ | `true` |

`dart fix --apply` resolved the majority of violations mechanically. **873 info-level
issues remain** (0 errors, 0 warnings). They do not block CI (`--no-fatal-infos`).

---

## dart fix summary

`dart fix --apply` touched **725 files** across `lib/`, `test/`, and `integration_test/`.
Changes were all mechanical `const` / `final` additions — no logic changed.

---

## Remaining issues by rule (873 total, all `info`)

| Rule | Count |
|------|-------|
| `prefer_const_constructors` | 747 |
| `prefer_const_literals_to_create_immutables` | 71 |
| `prefer_const_declarations` | 30 |
| `prefer_final_locals` | 21 |
| `prefer_final_fields` | 4 |

---

## Top 20 files by remaining issue count

| Issues | File |
|--------|------|
| 37 | `lib/shared/widgets/skeleton_loaders.dart` |
| 29 | `lib/shared/widgets/top_bar_widget.dart` |
| 29 | `lib/features/auth/terms_acceptance_dialog.dart` |
| 26 | `lib/features/video_room/widgets/chat_overlay_widget.dart` |
| 24 | `lib/features/profile/profile_page.dart` |
| 23 | `lib/features/video_room/widgets/participant_list_widget.dart` |
| 21 | `lib/core/retention/retention_service.dart` |
| 20 | `lib/features/video_room/screens/leave_room_screen.dart` |
| 19 | `lib/features/video_room/screens/room_screen.dart` |
| 18 | `lib/features/room/screens/room_discovery_screen.dart` |
| 18 | `lib/features/video_room/widgets/presence_card.dart` |
| 17 | `lib/features/video_room/widgets/room_header_widget.dart` |
| 17 | `lib/shared/widgets/chat_box_widget.dart` |
| 17 | `lib/features/auth/screens/neon_signup_page.dart` |
| 16 | `lib/features/notifications/screens/notifications_page.dart` |
| 15 | `lib/shared/widgets/badge_widgets.dart` |
| 15 | `lib/features/auth/screens/neon_login_page.dart` |
| 15 | `lib/features/payments/screens/coin_store_screen.dart` |
| 15 | `lib/features/auth/screens/neon_splash_page.dart` |
| 14 | `lib/features/video_room/screens/polished_room_screen.dart` |

Full list: run `flutter analyze --no-fatal-infos 2>&1 | Out-File analyze_stage1.txt`
then triage with the PowerShell snippet in `CONTRIBUTING.md`.

---

## Plan for remaining 873 infos

Remaining issues will be fixed in small follow-up commits on this branch, one
logical area at a time, and squashed before merge. Suggested order:

1. `lib/shared/widgets/` — 3 files, ~81 issues
2. `lib/features/auth/` — 4 files, ~76 issues
3. `lib/features/video_room/` — 6 files, ~94 issues
4. `lib/features/profile/` — 1 file, ~24 issues
5. Remaining `lib/` files in descending order

Each batch: open file, add missing `const` keywords, run `flutter analyze` to confirm
reduction, commit with `fix(lint): add const/final in <area>`.

---

## Staged lint plan status

| Stage | Branch | Rules | Status |
|-------|--------|-------|--------|
| **Stage 1** | `lint-stage-1` | `prefer_const_*`, `prefer_final_*` | **In progress — 873 infos remain** |
| Stage 2 | `lint-stage-2` | `unused_local_variable`, `unused_element`, `unused_field` | Not started |
| Stage 3 | `lint-stage-3` | Remove `lib/**_web.dart` from `exclude`; platform analysis | Not started |

---

## Testing

- [x] `flutter analyze --no-fatal-infos` exits 0 (0 errors, 0 warnings)
- [x] `dart fix --apply` completed successfully
- [ ] `flutter test test/unit/` — run before merge
- [ ] Manual smoke test (`flutter run -d chrome`) — run before merge

---

## Checklist

### Author
- [x] Branch based on `develop` (`940b2a4`)
- [x] `flutter analyze` exits 0
- [x] Only mechanical `const`/`final` changes — no logic altered
- [x] No new `dart:html` / non-shim web imports introduced
- [ ] Unit tests passing locally
- [ ] Follow-up commits to fix remaining 873 infos (can be done post-review)

### Reviewer
- [ ] Spot-check 2–3 changed files: confirm only `const`/`final` additions
- [ ] Confirm `analysis_options.yaml` diff shows exactly the 5 rules re-enabled
- [ ] CI analyzer step green
- [ ] No unintended changes to logic, state, or widget trees

### Post-merge
- [ ] Open `lint-stage-2` branch within 72 hours
- [ ] Update staged lint table in `CONTRIBUTING.md`
