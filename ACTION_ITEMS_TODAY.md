# ⚡ ACTION ITEMS FOR TODAY - MIX & MINGLE LAUNCH SPRINT

**Date:** January 28, 2026
**Goal:** Complete test cleanup + validation on Web
**Time Required:** 2–3 hours

---

## 🎯 IMMEDIATE ACTIONS (Next 2 Hours)

### 1. DELETE BROKEN TEST FILES (5 minutes)

```bash
# Remove files that import deleted login_page.dart
rm test/login_flow_test.dart
rm test/widgets/login_page_test.dart
```

**Why:** These files reference a deleted file and break the test suite.

---

### 2. REGENERATE TEST MOCKS (10 minutes)

```bash
# Rebuild mocks after file cleanup
flutter pub run build_runner build --delete-conflicting-outputs
```

**Expected output:**

- Regenerates `test/helpers/mock_firebase.mocks.dart`
- Fixes import errors

**What to check:**

```
✅ "Build complete" message
✅ No "unresolved symbol" errors
```

---

### 3. RUN FULL TEST SUITE (15 minutes)

```bash
# Run all tests
flutter test

# Or run specific tests if there are failures
flutter test test/models/
flutter test test/services/auth_service_test.dart
```

**Expected:**

- Most tests pass (some auth mock assertions may fail — that's OK for MVP)
- No compilation errors
- No missing imports

**What to check:**

```
✅ No "undefined class" errors
✅ No "missing import" errors
✅ Tests run without crashing
```

---

### 4. TEST ON WEB PLATFORM (45 minutes)

```bash
# Launch app on Chrome
flutter run -d chrome --no-hot
```

**Test checklist:**

- [ ] Splash screen loads (3 seconds)
- [ ] Login page appears
- [ ] Google sign-in works (or test account login)
- [ ] Dashboard/home page loads
- [ ] Room list loads and displays
- [ ] Can tap a room without crashing
- [ ] Settings page accessible
- [ ] Profile page accessible
- [ ] No error messages in browser console
- [ ] No crashes in Crashlytics (check Firebase Console)

**If something fails:**

```
Take note of error message
Check Crashlytics for stack trace
Create a new GitHub issue with the error
```

---

## ✅ VALIDATION CHECKLIST

After completing all 4 items above, verify:

- [ ] No test files broken (file cleanup successful)
- [ ] Mocks regenerated without errors
- [ ] Test suite runs (at least compiles)
- [ ] Web app launches without crashes
- [ ] All user flows work (login → room → settings)
- [ ] No errors in browser console (F12 → Console tab)
- [ ] Crashlytics shows no critical errors

---

## 🚀 IF EVERYTHING PASSES

**Congratulations!** You're ready for next phase:

1. Tomorrow: Build for iOS (`flutter build ipa --release`)
2. Tomorrow: Build for Android (`flutter build appbundle --release`)
3. This week: Deploy to Firebase Hosting
4. Next week: Submit to App Store + Play Store

---

## 🔴 IF SOMETHING BREAKS

**Troubleshooting guide:**

### Test file deletion fails

```bash
# Check if files exist
ls test/login_flow_test.dart
ls test/widgets/login_page_test.dart

# If they don't exist, they're already gone. Continue to step 2.
```

### Mock regeneration fails

```bash
# Clean build_runner cache
flutter clean
flutter pub get

# Try again
flutter pub run build_runner build --delete-conflicting-outputs
```

### Tests won't compile

```bash
# Check for import errors
flutter analyze

# Fix the first error
# Try again
flutter test
```

### Web app crashes

```bash
# Check browser console (F12 → Console)
# Check Crashlytics in Firebase Console
# Note the error message and share it

# Try rebuilding
flutter clean
flutter pub get
flutter run -d chrome --no-hot
```

---

## 📞 WHEN TO REACH OUT

If any of these happen:

- ❌ Multiple test failures (more than 3–4)
- ❌ Web app crashes on every flow
- ❌ "undefined symbol" or "missing import" errors
- ❌ Crashlytics shows critical errors

**Then:** Check error logs, note the exact error message, and request help.

---

## ⏰ TIME ESTIMATE

| Task              | Time       | Notes                    |
| ----------------- | ---------- | ------------------------ |
| Delete test files | 5 min      | Quick                    |
| Regenerate mocks  | 10 min     | Automated                |
| Run test suite    | 15 min     | Compile + run            |
| Test on Web       | 45 min     | Manual testing all flows |
| **TOTAL**         | **75 min** | ~1.5 hours               |

**Add 30 min buffer for troubleshooting if needed.**

---

## 📋 SUCCESS CRITERIA

You're READY FOR NEXT PHASE when:

```
✅ All test files deleted or fixed
✅ Mocks regenerated without errors
✅ flutter test runs successfully
✅ App launches on Web without crashing
✅ Can log in, access room, view settings
✅ No errors in Crashlytics
```

---

## 🎯 NEXT PHASE (TOMORROW)

Once today's actions complete:

### iOS Build (45 min)

```bash
flutter build ipa --release --obfuscate --split-debug-info
```

### Android Build (30 min)

```bash
flutter build appbundle --release --obfuscate --split-debug-info
```

### Firebase Hosting Deploy (1 hour)

```bash
flutter build web --release
firebase deploy --only hosting
```

---

**Good luck! You're on the final stretch to public release.** 🚀

---

**Questions?** Refer to:

- `MVP_LAUNCH_ROADMAP.md` — Full launch plan
- `MASTER_EXECUTION_PLAN.md` — Phase breakdown
- `LAUNCH_STATUS_TODAY.md` — Current progress
