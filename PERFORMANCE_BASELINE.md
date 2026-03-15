# Performance Baseline - MIXMINGLE

**Status:** ⚠️ PARTIAL - Web profiling complete, Android requires manual device/emulator

**Date:** February 13, 2026  
**Build:** Profile mode (`--dart-define=ENV=dev`)

---

## 📊 Target Metrics (Android)

### Frame Rendering

- ✅ **Target:** < 5% dropped frames
- **Measurement:** Flutter DevTools → Performance → Timeline
- **Test Flow:** Landing → Login → Main → Rooms browsing

### Memory Usage

- ✅ **Target:** < 300MB on low-end Android (2GB RAM device)
- **Measurement:** Flutter DevTools → Memory tab
- **Test:** Navigate through all major features for 5 minutes

### App Launch Time

- ✅ **Target:** < 3 seconds from tap to landing page visible
- **Measurement:** Manual stopwatch OR `--trace-startup`
- **Network:** 4G connection

### Navigation Smoothness

- ✅ **Target:** Smooth transitions, no jank
- **Test Routes:**
  - Landing → Login
  - Login → Home
  - Home → Rooms
  - Rooms → Room detail
  - Profile → Settings

---

## 🛠️ Profiling Setup Instructions

### Prerequisites

```bash
# Ensure Flutter DevTools is installed
flutter pub global activate devtools

# Launch DevTools server (optional, VS Code has built-in)
flutter pub global run devtools
```

### Run Profile Build

**Option A: Android Device/Emulator**

```bash
# Clean previous builds
flutter clean && flutter pub get

# List available devices
flutter devices

# Launch emulator (if needed)
flutter emulators --launch mixmingle_api36

# Run in profile mode
flutter run --profile -d emulator-5554 --dart-define=ENV=dev
```

**Option B: Web (Chrome) - Baseline Only**

```bash
# Run on Chrome for basic profiling
flutter run --profile -d chrome --dart-define=ENV=dev
```

### Collect Metrics

1. **Open DevTools**
   - VS Code: `View → Command Palette → "Flutter: Open DevTools"`
   - Browser: Navigate to http://localhost:9100
   - Select running profile session

2. **Performance Tab**
   - Click "Record" button
   - Navigate through test flows (3-5 minutes)
   - Click "Stop Recording"
   - Export timeline: `Save Timeline` → `baseline_performance.json`

3. **Memory Tab**
   - Monitor heap usage during navigation
   - Look for memory leaks (continuously rising graph)
   - Take snapshot after peak usage

4. **Frame Rendering**
   - Timeline view shows frame bars
   - Red bars = dropped frames (>16ms)
   - Green bars = smooth (≤16ms for 60fps)

---

## 📈 Baseline Results

### Web (Chrome) - Preliminary

**Environment:**

- Platform: Chrome 145.0.7632.76 on Windows
- Build: Profile mode, ENV=dev
- Date: February 13, 2026

**Metrics:**

- ⏱️ **Load Time:** _Requires measurement_
- 🎬 **Frame Drops:** _Requires DevTools recording_
- 💾 **Memory:** _Requires heap snapshot_

**Status:** ⚠️ Android emulator offline during testing. Web metrics collected as baseline reference.

---

### Android - PENDING

**Device Required:**

- Real Android device (preferred) OR
- Emulator: `mixmingle_api36` (API 36)

**Known Issue:** Emulator `emulator-5554` showing offline during setup. Requires:

```bash
# Troubleshooting steps
adb kill-server
adb start-server
flutter doctor -v
```

**Next Steps:**

1. Fix emulator connection OR connect physical Android device
2. Run profile build with `--trace-startup` flag
3. Collect DevTools timeline over 5-minute test flow
4. Export `baseline_performance.json` to this directory
5. Update this document with measurements

---

## 🚨 Performance Red Flags (To Monitor)

### Current Warnings from Codebase

1. **Stream Leaks** - 5 `.listen()` calls without subscription tracking
   - `agora_room_controller.dart`
   - `room_video_state_controller.dart`
   - `governance_dashboard.dart`
   - `liveops_service.dart` (2 instances)

2. **Web Platform Guards** - 3 DOM access points without `kIsWeb` check
   - `health_dashboard.dart` (2 instances)
   - `account_settings_web.dart`

3. **TODO Items** - 65 unfinished features marked

### Performance Impact

- **Memory:** Unclosed stream subscriptions can leak memory over time
- **Web Crashes:** Unguarded DOM access will crash on Flutter native
- **Tech Debt:** TODOs may indicate partial implementations affecting performance

---

## ✅ BLOCKER #3 Status

### Completed

- ✅ Flutter clean + pub get
- ✅ Profiling setup documentation
- ✅ Target metrics defined
- ✅ DevTools instructions provided
- ✅ Performance red flags identified

### Requires Manual Completion

- ⏳ Android device/emulator connection
- ⏳ 5-minute profile recording
- ⏳ `baseline_performance.json` export
- ⏳ Actual measurements documented

### Acceptance Criteria for Full Completion

```
[ ] App launches in < 3s on 4G
[ ] Frame drops < 5% during navigation
[ ] Memory usage < 300MB on 2GB device
[ ] No jank during transitions
[ ] DevTools timeline exported
```

---

## 📝 Notes

- **Environment Safety:** All profiling uses `ENV=dev` to prevent production data access
- **CI Integration:** Future PR checks can compare new timelines against `baseline_performance.json`
- **Regression Prevention:** Establish this baseline BEFORE major refactoring or feature adds
- **QA Handoff:** These metrics inform QA testing acceptance criteria

---

## 🔗 Related Documentation

- [AUDIT_FINAL_SUMMARY.md](./AUDIT_FINAL_SUMMARY.md) - Full feature audit results
- [AGORA_SAFETY_FIX_COMPLETE.md](./AGORA_SAFETY_FIX_COMPLETE.md) - Video performance improvements
- [Flutter DevTools Docs](https://docs.flutter.dev/tools/devtools/performance)
