# Contributing to MIXMINGLE

Thank you for contributing! Please read this guide before opening a PR.

---

## Table of Contents
1. [Development setup](#development-setup)
2. [Branch and commit conventions](#branch-and-commit-conventions)
3. [Pre-commit checks](#pre-commit-checks)
4. [Platform-specific code pattern](#platform-specific-code-pattern)
5. [Staged lint re-enable plan](#staged-lint-re-enable-plan)
6. [CI requirements](#ci-requirements)
7. [Pull request checklist](#pull-request-checklist)

---

## Development setup

```powershell
# 1. Clone and enter the repo
git clone <repo-url>
cd MIXMINGLE

# 2. Install Flutter dependencies
flutter pub get

# 3. Install the pre-commit hook (one-time per checkout)
.\scripts\install_hooks.ps1

# 4. Verify setup
flutter analyze --no-fatal-infos
flutter test test/unit/
```

Requirements: Flutter 3.24.3 (stable), Java 17, Dart 3.x

---

## Branch and commit conventions

| Branch | Purpose |
|--------|---------|
| `main` | Production; protected; requires PR + passing CI |
| `develop` | Integration branch; protected; requires PR + passing CI |
| `feat/<name>` | New features |
| `fix/<name>` | Bug fixes |
| `chore/<name>` | Maintenance, deps, lint |
| `lint-stage-<n>` | Staged lint re-enable (see below) |

Commit messages follow [Conventional Commits](https://www.conventionalcommits.org/):

```
feat(scope): short description
fix(scope): short description
chore(lint): staged lint re-enable stage N
```

---

## Pre-commit checks

The pre-commit hook at `.git/hooks/pre-commit` runs automatically on every `git commit`.  
It executes `scripts/pre_commit_check.ps1`, which:

1. Runs `flutter pub get --offline`
2. Runs `flutter analyze --no-fatal-infos` — **blocks commit on any error**
3. Runs `flutter test test/unit/` — **blocks commit on test failure**

To install it on a fresh checkout:

```powershell
.\scripts\install_hooks.ps1
```

To run it manually before committing:

```powershell
.\scripts\pre_commit_check.ps1
```

---

## Platform-specific code pattern

MIXMINGLE targets both web and non-web (Android/iOS) platforms. Some APIs (Agora
web SDK, `dart:html`, `package:web`) are only available in the browser.

**Always use the shim / stub / `_web` triplet** for any web-only module:

```
lib/
  foo.dart          ← shim (entry point, all platforms)
  foo_stub.dart     ← non-web implementation (no-op or UnsupportedError)
  foo_web.dart      ← web-only implementation
```

### `foo.dart` — shim entry point

```dart
// foo.dart
// Conditional import: load the web version on web, stub on all other platforms.
export 'foo_stub.dart'
    if (dart.library.html) 'foo_web.dart';
```

### `foo_stub.dart` — non-web stub

```dart
// foo_stub.dart
// Stub for non-web platforms. Throws UnsupportedError for methods that must
// never be called outside a browser.

class Foo {
  void initialize() {
    throw UnsupportedError('Foo is only supported on web.');
  }

  // No-op fields are acceptable when the caller guards with kIsWeb.
  String get channelName => '';
}
```

### `foo_web.dart` — web implementation

```dart
// foo_web.dart
// Web-only implementation. Do NOT import this file directly; use foo.dart.
// ignore_for_file: avoid_web_libraries_in_flutter

import 'package:web/web.dart';
import 'dart:js_interop';

class Foo {
  void initialize() {
    // ... real web implementation
  }

  String get channelName => 'web-channel';
}
```

### Rules

- **Never** import `foo_web.dart` directly. Always import `foo.dart`.
- **Never** import `dart:html` or `package:js` outside a `_web.dart` file.
- Add `// ignore_for_file: avoid_web_libraries_in_flutter` only to `_web.dart` files.
- Use `package:web` + `dart:js_interop` instead of the deprecated `dart:html` + `package:js`.

### Quick verification

After adding a new shim triplet, verify it compiles on both targets:

```bash
# Non-web (Android)
flutter build apk --debug

# Web
flutter build web
```

---

## Staged lint re-enable plan

Lint rules are being re-enabled incrementally to avoid a large disruptive
change. Do not re-enable rules outside the designated stage PR.

| Stage | Branch | Rules |
|-------|--------|-------|
| Stage 1 | `lint-stage-1` | `prefer_const_constructors`, `prefer_final_fields` |
| Stage 2 | `lint-stage-2` | `unused_local_variable`, `unused_element`, `unused_field` |
| Stage 3 | `lint-stage-3` | Remove `lib/**_web.dart` from `analyzer.exclude`; full platform analysis |

Workflow per stage:

```bash
git checkout -b lint-stage-N develop
# Re-enable the target rules in analysis_options.yaml
flutter pub get
dart fix --apply
flutter analyze --no-fatal-infos
# Fix remaining issues manually, then commit
git commit -m "chore(lint): re-enable stage N rules"
# Open a PR targeting develop
```

---

## CI requirements

Every PR targeting `main` or `develop` must pass:

| Check | Workflow | Failure mode |
|-------|----------|-------------|
| `flutter analyze --no-fatal-infos` | `ci.yml` | Blocks merge |
| `flutter test test/unit/` | `ci.yml` | Blocks merge |
| No build artifacts in repo | `ci.yml` | Blocks merge |

The `build-android-apk` job runs on PRs only and uploads the APK as a build
artifact. It uses a dual-path copy step to handle the AGP 8.x output-directory
change:

```yaml
- name: 📋 Copy APK to expected artifact path
  run: |
    mkdir -p build/app/outputs/flutter-apk
    find android/app/build/outputs -name 'app-debug.apk' \
      -exec cp {} build/app/outputs/flutter-apk/ \; 2>/dev/null || true
```

---

## Pull request checklist

```
- [ ] Branch is up-to-date with target (develop or main)
- [ ] flutter analyze exits 0
- [ ] flutter test test/unit/ passes
- [ ] No build artifacts committed
- [ ] Commit messages follow feat|fix|chore(scope): description
- [ ] New web-only code uses the shim/stub/_web triplet
- [ ] No dart:html or package:js imports outside _web.dart files
- [ ] Docs / comments updated where relevant
```
